# Expected routing

- No plan file: a single request with the exact phrase **deep review**.
- `deep-reviewer` runs first and is read-only.
- If it returns findings, they go to `coder` in one fix pass, unless the request says not to fix them.
- If it returns no findings, no `coder` delegation happens and the work copy stays unchanged.
- No second review cycle. Any findings still open are reported.
