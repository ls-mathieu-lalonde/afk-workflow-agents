# AFK Workflow Agents

This is a small, standalone opencode agent set for unattended (AFK) coding
workflows. It contains only four agents:

- `afk-orchestrator` — routes each request to exactly one specialist.
- `coder` — implements the requested change and verifies it.
- `reviewer` — performs the normal review.
- `deep-reviewer` — performs the stronger review when the request explicitly
  says **deep review**.

The orchestrator does not implement, it delegates each piece of work to one of the three
specialists in this repository. This makes the review boundary predictable in
AFK workflows: ordinary work uses `reviewer`; an explicit `deep review` uses
`deep-reviewer` instead.

## Install in the local opencode config

The included installer renders these agents into the global opencode agent
directory (`~/.opencode/agents`):

```sh
./install.sh
```

Each agent's model comes from `models.env` and is shown as the default. Press
Enter to keep it, or type another model ID. Files that already match the chosen
model are left alone. Files that differ ask before replacing them. Every line of
output names the file and the model it was installed with.

To install into another directory, pass its path:

```sh
./install.sh /path/to/opencode/agents
```

For a non-interactive run (or when stdin is not a terminal), the installer uses
the defaults and leaves differing files untouched. It exits non-zero if it
skipped any.

```sh
./install.sh --yes
```

To use a different defaults file, pass `--models FILE`.

### Models

`agents/*.md` contain `{{MODEL_*}}` placeholders instead of fixed model IDs.
`models.env` holds the defaults, one variable per agent:

| Agent               | Variable                    |
| ------------------- | --------------------------- |
| afk-orchestrator    | `MODEL_AFK_ORCHESTRATOR`    |
| coder               | `MODEL_CODER`               |
| reviewer            | `MODEL_REVIEWER`            |
| deep-reviewer       | `MODEL_DEEP_REVIEWER`       |

The installer always renders from these templates, so the repo files are not
valid opencode agents until installed. The routing tests use the same path with
`tests/models.cheap.env`.

The installer does not change `opencode.json`. If you want the orchestrator to
be your default primary agent, set this in your local config:

```json
{
  "default_agent": "afk-orchestrator"
}
```

Restart opencode after installing so it reloads the agent definitions.

## Use

Ask for implementation normally and the orchestrator delegates to `coder`.
Ask for a normal review and it delegates to `reviewer`. Use the exact phrase
**deep review** when the stronger, read-only `deep-reviewer` should run.
For a plan or checklist, the orchestrator breaks it into ordered steps,
delegates each group of steps to the matching specialist in sequence, and
reports any required step that was skipped or failed.

Ideally, build this into your plans or tasks lists.  Example.

[ ] Implement user verification logic
[ ] Review changes and address findings
...
[ ] Implement user verification display
[ ] Perform a `deep review` of the work so far and address findings

### Task groups

Plans often organize steps into named groups with sub-tasks, such as
"1. Verification logic" with 1.1–1.4. The orchestrator treats each group as a
unit:

- **Sizing:** large groups are split into small delegations of a few related
  sub-tasks, run in order, so `coder` gets one focused change at a time.
- **Implicit review:** if a group has no explicit review step after its
  implementation, the orchestrator adds one on the fly. It uses `reviewer`, or
  `deep-reviewer` only when the plan says **deep review**. If the review
  returns actionable findings, the orchestrator sends them to `coder` in one
  fix pass. It does not run a second review cycle unless the plan requires one,
  and it reports any findings still open.
- **Plan file:** the orchestrator never changes the plan file for an implicit
  review. `coder` records only official plan steps, and the added review
  appears only in the report.

Explicit review steps in a plan get the same treatment. If a review returns
actionable findings, the orchestrator sends them to `coder` in one fix pass,
unless the review step, the plan, or the group says not to fix it (for example
"report only" or "do not fix"). Fix passes the orchestrator adds are never
recorded in the plan file; a fix step the plan lists is recorded as usual.

### Skills that follow a plan

Skills such as `openspec-apply-change` read a tasks file and work through it
on their own. When a skill is requested or would read a plan, the orchestrator
takes control of the sequence instead of letting the skill run the whole
workflow inside one agent. It loads the skill, extracts the open steps from the
plan file in order, tags each with its agent, and delegates groups in sequence.
After each group it checks the result, has `coder` record completed official
steps in the plan file, and reports progress per step. A skill's own completion
message does not count as plan completion.

### Ending a session with a deep review

The initial prompt can ask for a final **deep review** to close the session,
for example:

> Implement the tasks in `tasks.md`. When finished, end with a deep review of
> all changes and address the findings.

The orchestrator then runs `deep-reviewer` as the last step, after the
implementation groups, and sends its findings to `coder` in one fix pass.

## Repository layout

```text
afk-workflow-agents/
├── agents/
│   ├── afk-orchestrator.md
│   ├── coder.md
│   ├── reviewer.md
│   └── deep-reviewer.md
├── models.env               # default model per agent
├── tests/                   # routing test harness, see tests/README.md
├── install.sh
└── README.md
```

## Testing routing

`tests/run-scenario.sh` runs the orchestrator against a disposable copy of a
scenario project. See [tests/README.md](tests/README.md).
