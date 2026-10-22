# Orchestrator routing tests

Local harness for checking how `afk-orchestrator` routes a request. Each run
works on a disposable copy of a scenario project, so the fixture stays clean
and the run can be inspected afterwards.

## Layout

```text
tests/
├── run-scenario.sh              # runner
├── scenarios/
│   ├── trivial-plan/
│   │   ├── project/             # fixture project, deep-copied per run
│   │   ├── prompt.md            # request sent to afk-orchestrator
│   │   └── expect.md            # expected routing and end state
│   └── trivial-deep-review/
│       ├── project/
│       ├── prompt.md
│       └── expect.md
└── work/                        # disposable run copies (git-ignored)
```

## Run

```sh
tests/run-scenario.sh --list                 # list scenarios
tests/run-scenario.sh --dry-run trivial-plan # build the copy, do not call opencode
tests/run-scenario.sh trivial-plan           # full run
```

Each run:

1. Deep-copies `scenarios/<name>/project/` into
   `tests/work/<name>-<timestamp>/`.
2. Initializes a git repo there and commits the baseline, so the final diff
   shows only what the agents changed.
3. Renders the agents from this working tree into the copy's
   `.opencode/agents/` with `install.sh --yes --models tests/models.cheap.env`.
   The test runs the code under review, not the globally installed agents, and
   exercises the same substitution path users run. Every agent uses the cheap
   test model.
4. Runs `opencode run --standalone --agent afk-orchestrator --auto` with
   `prompt.md` from inside the copy. `--auto` approves permission prompts so the
   run does not block.
5. Prints `git status` and the diff stat for the copy, plus the log path.

Compare the run against `expect.md` by hand. Work copies are kept in
`tests/work/` for inspection. Delete that directory to clean up.

## Adding a scenario

1. Create `tests/scenarios/<name>/project/` with the smallest fixture that
   exercises the routing you want. Keep it trivial.
2. Add `prompt.md` with the request, and `expect.md` with the expected routing
   and end state.
3. Run `tests/run-scenario.sh --dry-run <name>` to check the setup.
