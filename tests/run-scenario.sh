#!/usr/bin/env bash
# Run an orchestrator routing scenario against a disposable copy of its project.
#
# Usage:
#   tests/run-scenario.sh [--dry-run] [--list] <scenario>
#
#   --list      List available scenarios and exit.
#   --dry-run   Build the work copy and install agents, but do not call opencode.
#
# Each run deep-copies tests/scenarios/<scenario>/project into
# tests/work/<scenario>-<timestamp>/, initializes a git baseline there, installs
# the agents from this working tree into the copy's .opencode/agents, and runs
# the orchestrator with the scenario's prompt.md. The original fixture is never
# modified. tests/work/ is git-ignored and kept for inspection.
set -euo pipefail

tests_dir=$(CDPATH= cd "$(dirname "$0")" && pwd)
repo_dir=$(CDPATH= cd "$tests_dir/.." && pwd)
scenarios_dir="$tests_dir/scenarios"
work_root="$tests_dir/work"

dry_run=false

usage() {
  printf 'Usage: %s [--dry-run] [--list] <scenario>\n' "$0" >&2
}

list_scenarios() {
  for dir in "$scenarios_dir"/*/; do
    [ -d "$dir" ] || continue
    basename "$dir"
  done
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --dry-run) dry_run=true; shift ;;
    --list) list_scenarios; exit 0 ;;
    -h|--help) usage; exit 0 ;;
    --) shift; break ;;
    -*) usage; exit 2 ;;
    *) break ;;
  esac
done

if [ "$#" -ne 1 ]; then
  usage
  printf 'Scenarios:\n' >&2
  list_scenarios | sed 's/^/  /' >&2
  exit 2
fi

scenario=$1
scenario_dir="$scenarios_dir/$scenario"

if [ ! -d "$scenario_dir/project" ] || [ ! -f "$scenario_dir/prompt.md" ]; then
  printf 'Unknown scenario %s (need %s/project and prompt.md)\n' "$scenario" "$scenario_dir" >&2
  exit 2
fi

timestamp=$(date +%Y%m%d-%H%M%S)
work_dir="$work_root/$scenario-$timestamp"
mkdir -p "$work_dir"

# Deep copy the fixture project, including dotfiles.
cp -R "$scenario_dir/project/." "$work_dir/"

# The copy needs its own git repo so the coder's git permissions and the
# final diff are meaningful. Commit the baseline with a fixed identity.
cd "$work_dir"
if [ ! -d .git ]; then
  git init -q
fi
git add -A
git -c user.name=afk-test -c user.email=afk-test@localhost \
  commit -q --allow-empty -m "scenario baseline: $scenario"

# Install the agents from this working tree (not the global install) so the
# test exercises the code under review.
mkdir -p .opencode/agents
cp "$repo_dir"/agents/*.md .opencode/agents/

prompt=$(cat "$scenario_dir/prompt.md")
log="$work_dir/run.log"

printf 'Scenario:  %s\n' "$scenario"
printf 'Work copy: %s\n' "$work_dir"

if [ "$dry_run" = true ]; then
  printf 'Dry run: opencode not invoked.\n'
  printf 'Prompt:\n%s\n' "$prompt"
  exit 0
fi

if ! command -v opencode >/dev/null 2>&1; then
  printf 'opencode not found on PATH\n' >&2
  exit 1
fi

# --standalone keeps the run isolated from the background service, and --auto
# approves permission prompts so unattended runs do not block.
set +e
opencode run --standalone --agent afk-orchestrator --auto "$prompt" 2>&1 | tee "$log"
status=${PIPESTATUS[0]}
set -e

printf '\n--- Result in work copy ---\n'
git status --short
git --no-pager diff --stat HEAD || true
printf '\nRun log:   %s\n' "$log"
printf 'Expected:  %s\n' "$scenario_dir/expect.md"
printf 'Opencode exit status: %s\n' "$status"
