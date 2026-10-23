#!/bin/sh
# Install the AFK agents into an opencode agents directory.
#
# Each agents/<name>.md is rendered by replacing its {{MODEL_*}} placeholder
# with the model chosen for that agent. The default comes from the models file
# (models.env). Interactively, you pick a model per agent (Enter keeps the
# default). Files whose rendered content already matches the installed copy are
# left alone. Files that differ prompt before they are replaced.
set -eu

script_dir=$(CDPATH= cd "$(dirname "$0")" && pwd)
source_dir="$script_dir/agents"
models_file="$script_dir/models.env"
destination="${HOME}/.opencode/agents"
assume_yes=false

usage() {
  printf 'Usage: %s [--models FILE] [--yes] [destination]\n' "$0"
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --models)
      if [ "$#" -lt 2 ]; then usage >&2; exit 2; fi
      models_file=$2
      shift 2
      ;;
    --yes) assume_yes=true; shift ;;
    -h|--help) usage; exit 0 ;;
    -*) usage >&2; exit 2 ;;
    *) break ;;
  esac
done

if [ "$#" -gt 1 ]; then
  usage >&2
  exit 2
fi

if [ "$#" -eq 1 ]; then
  destination=$1
fi

if [ ! -f "$models_file" ]; then
  printf 'Models file not found: %s\n' "$models_file" >&2
  exit 1
fi

case "$models_file" in
  /*) ;;
  *) models_file="./$models_file" ;;
esac

# shellcheck source=/dev/null
. "$models_file"

# Agent name -> variable name: afk-orchestrator -> MODEL_AFK_ORCHESTRATOR.
var_for() {
  printf 'MODEL_%s' "$1" | tr 'a-z-' 'A-Z_'
}

valid_model() {
  printf '%s' "$1" | grep -Eq '^[A-Za-z0-9._/:-]+$'
}

# Preflight: every agent needs a valid default before anything is written.
for source in "$source_dir"/*.md; do
  name=$(basename "$source" .md)
  var=$(var_for "$name")
  eval "default=\${$var:-}"
  if [ -z "$default" ]; then
    printf '%s is not set in %s\n' "$var" "$models_file" >&2
    exit 1
  fi
  if ! valid_model "$default"; then
    printf 'Invalid model id for %s: %s\n' "$var" "$default" >&2
    exit 1
  fi
done

interactive=false
if [ "$assume_yes" = false ] && [ -t 0 ]; then
  interactive=true
fi

prompt_model() { # name default -> prints chosen model
  while :; do
    printf '%s model [%s]: ' "$1" "$2" >&2
    answer=""
    read -r answer || true
    if [ -z "$answer" ]; then
      answer=$2
    fi
    if valid_model "$answer"; then
      printf '%s\n' "$answer"
      return 0
    fi
    printf 'Invalid model id: %s\n' "$answer" >&2
  done
}

confirm() { # prompt -> exit 0 on yes
  printf '%s [y/N]: ' "$1" >&2
  answer=""
  read -r answer || true
  case "$answer" in
    y|Y|yes|YES) return 0 ;;
    *) return 1 ;;
  esac
}

# render source var model out: fill the placeholder, fail on anything left over.
render() {
  sed "s|{{$2}}|$3|" "$1" > "$4"
  if grep -q '{{' "$4"; then
    printf 'Unresolved placeholder in %s\n' "$1" >&2
    exit 1
  fi
}

mkdir -p "$destination"
tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT
skipped=false

for source in "$source_dir"/*.md; do
  name=$(basename "$source" .md)
  var=$(var_for "$name")
  eval "model=\${$var}"

  if [ "$interactive" = true ]; then
    model=$(prompt_model "$name" "$model")
  fi

  rendered="$tmp_dir/$name.md"
  render "$source" "$var" "$model" "$rendered"
  target="$destination/$name.md"

  if [ ! -e "$target" ]; then
    cp "$rendered" "$target"
    printf 'Installed %s (model: %s)\n' "$target" "$model"
  elif cmp -s "$rendered" "$target"; then
    printf 'Unchanged %s (model: %s)\n' "$target" "$model"
  elif [ "$interactive" = true ]; then
    if confirm "Replace $target?"; then
      cp "$rendered" "$target"
      printf 'Updated %s (model: %s)\n' "$target" "$model"
    else
      printf 'Kept %s\n' "$target"
    fi
  else
    printf 'Skipped %s: differs from the repo version (run interactively to replace it)\n' "$target" >&2
    skipped=true
  fi
done

if [ "$skipped" = true ]; then
  exit 1
fi
