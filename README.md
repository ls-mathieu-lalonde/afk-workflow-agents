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

The included installer copies these agents into the global opencode agent
directory (`~/.config/opencode/agents`) and refuses to overwrite existing
files:

```sh
./install.sh
```

To install into another directory, pass its path:

```sh
./install.sh /path/to/opencode/agents
```

To replace an existing installation deliberately:

```sh
./install.sh --force
```

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
**deep review** when the stronger, read-only `deep-reviewer` should run. The
orchestrator selects one specialist per request and returns that specialist's
result.

## Repository layout

```text
afk-workflow-agents/
├── agents/
│   ├── afk-orchestrator.md
│   ├── coder.md
│   ├── reviewer.md
│   └── deep-reviewer.md
├── install.sh
└── README.md
```
