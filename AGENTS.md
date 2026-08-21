# Agent Rules

## Every repository mutation must use `$human-review`.

- Read `.agents/skills/human-review/SKILL.md` and its required reference before
  changing repository files.
- Record material requests, corrections, decisions, actions, failures, and
  validation results in `.ai/transcript.md`.
- Maintain `.ai/checklist.md` with stable review IDs for every changed
  structure, function, contract, route, API, interface, UI behavior, test,
  document, and delivery artifact.
- Present related checks in module-sized batches of 10–50 items and never mark
  a check approved on an agent's authority.
- Stop for human review before staging agent-authored changes, committing,
  pushing, merging, or rewriting history.

## Parallel Work and Git Worktrees

- Windi explicitly permits the lead agent to run multiple sub-agents
  concurrently for independent, bounded jobs when parallel execution materially
  helps the task.
- Give every sub-agent a concrete scope and exclusive file ownership. Keep
  dependent work sequential and never let multiple writers edit the same path.
- Use a dedicated `codex/<task>` branch and Git worktree for each parallel writer
  once the shared baseline is committed and clean.
- Before that baseline exists, parallelize read-only analysis or assign writers
  disjoint paths in the primary worktree; never let two agents edit one file.
- The lead agent is the sole writer for `.ai/transcript.md` and
  `.ai/checklist.md`. Workers read the ledgers and report requests, actions,
  failures, paths, and validation results to the lead for recording.
- Workers do not stage, commit, merge, cherry-pick, or open human-review rounds.
- The lead reconciles every worktree, the canonical ledgers, and the final diff
  before asking for review.
- Preserve unrelated user changes and identify the branch, worktree, files, and
  checks in every handoff.

## Human Review and Git Authorization

All changes must be reviewed by a human before delivery.

- Never run `git add`, `git commit`, `git push`, `git merge`, `git cherry-pick`,
  or a history-rewriting command on your own initiative. Preserve files the user
  already staged, but do not stage new agent-authored changes without approval.
- After editing, present the changed behavior, validation, risks, and unresolved
  checklist items. A completed implementation is not permission to commit.
- Never perform irreversible or destructive operations outside the requested
  scope without explicit human confirmation.

After explicit approval, commits must be signed off and follow:
`type(scope): subject`.

- Use `git commit -s` so the `Signed-off-by:` trailer is present.
- Use a lowercase imperative subject with no trailing period and a meaningful
  scope such as `app`, `ui`, `tracking`, `carrier`, `auth`, `db`, `agents`, or
  `tooling`.
- Never add a `Co-authored-by:` trailer.
