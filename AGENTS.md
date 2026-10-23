# AGENTS.md

This repo holds four opencode agents for AFK coding workflows, plus an
installer and a routing test harness. Most changes are edits to the agent
prompts in `agents/*.md`. See `README.md` for usage, the routing rules, and the
repo layout, and `tests/README.md` for the test harness.

## Invariants

- **Templates, not agents.** `agents/*.md` use `{{MODEL_*}}` placeholders that
  `install.sh` fills from `models.env` (see README "Models"). Never hard-code a
  model ID. A new agent needs its variable in both `models.env` and
  `tests/models.cheap.env`.
- **Roles stay separate.** The orchestrator only coordinates, reviewers only
  read and report, and `coder` is the only agent that changes things. Anything
  irreversible needs approval. Permission edits should keep these roles intact.
- **The prompts and the README must agree.** When you change behavior in a
  prompt, such as routing, plan handling, or implicit reviews, update
  `README.md` in the same change, and the other way around.
- `install.sh` is POSIX `sh`, so don't use bashisms there. Keep its install
  behavior as the README describes it.
- `tests/work/` holds disposable run copies. Don't edit them.

## Verifying changes

There is no automated suite. Use the cheapest check that covers the change:

1. Templates or installer: `./install.sh --yes "$(mktemp -d)"`.
2. Harness setup: `tests/run-scenario.sh --dry-run <scenario>`.
3. Prompt behavior: `tests/run-scenario.sh <scenario>`, then compare the run
   against `expect.md`. This calls real models, so run it only when behavior
   changed.

Run `shellcheck` on the scripts when it's available.

## Don'ts

- Do not modify the user's `opencode.json` or installed agents in
  `~/.opencode/agents` unless asked.
