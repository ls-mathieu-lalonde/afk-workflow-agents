# Expected routing

- Groups 1 and 2.1 go to `coder`; group 1 gets an implicit `reviewer` pass after it.
- Step 2.2 contains the exact phrase **deep review**, so it goes to `deep-reviewer` last.
- Plan file is updated only for official steps 1.1, 1.2, 2.1, 2.2 (never for implicit review or orchestrator-added fix passes).
- Actionable findings from the implicit `reviewer` pass go to `coder` in one orchestrator-added fix pass, with no plan-file entry for that fix, unless the plan, group, or review says not to fix.
- Any opt-out ("report only" or "do not fix") in the plan applies to implicit reviews too: findings are reported and no fix is delegated.
- `sh test/test_greet.sh` passes in the work copy at the end.
