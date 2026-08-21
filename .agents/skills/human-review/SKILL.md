---
name: human-review
description: Build, track, resume, and close transcript-led, module-batched human reviews for Windi repository changes. Use for every repository mutation and whenever a user requests a checklist, implementation review, design walkthrough, question-answer-action flow, approval tracking, 10–50-check module conversation, or durable record in .ai/transcript.md and .ai/checklist.md.
---

# Windi Human Review

Create a durable audit trail and let the human approve or revise one coherent
module batch at a time. Treat the transcript as chronological history and the
checklist as current review state.

## Required files

Use:

- `.ai/transcript.md` for prompts, decisions, actions, failures, corrections,
  validations, and review checkpoints in chronological order.
- `.ai/checklist.md` for the complete review inventory, stable IDs, current
  question, answers, actions, verification, and approval state.

Read [references/ledger-format.md](references/ledger-format.md) completely before
creating or restructuring either file. Never store secrets, credentials, private
keys, raw tokens, or generated dependency contents in a ledger.

During parallel work, the lead agent is the sole ledger writer. Workers read the
ledgers and report material events and evidence to the lead.

## Workflow

### 1. Reconstruct context

Before opening or resuming a review:

1. Read the repository instructions and required skills for changed paths.
2. Read `.ai/transcript.md` and `.ai/checklist.md` completely.
3. Inspect the working tree and changed/untracked files without changing them.
4. Reconcile the request, transcript, checklist, implementation, and parallel
   worker reports.

Do not ask the first review question until this preflight is complete.

### 2. Record messages before acting

Append every material user request, correction, approval, rejection, deferral,
scope change, implementation request, Git request, or stop request before acting.
Preserve prompts and answers verbatim when practical; redact secrets.

After acting, append material changes, failures, corrective reruns, and validation
evidence. Do not rewrite history to make it look cleaner.

### 3. Build the exhaustive checklist

Derive the checklist from source evidence. Inventory:

- repository ownership, dependency direction, package/configuration, and vendor
  assets;
- changed production types, interfaces, functions, and exported behavior;
- SvelteKit routes, loads, actions, endpoints, hooks, APIs, webhooks, and
  serializable contracts;
- tracking models, carrier-neutral ports, provider adapters, persistence schemas,
  migrations, repositories, caches, or queues when present;
- components, layouts, interaction states, validation, accessibility, responsive
  behavior, and Bootstrap markup;
- security and browser/server trust boundaries;
- tests, fixtures, docs, scripts, deployment artifacts, intentional removals,
  unsupported behavior, and deferrals.

Give every independently reviewable item a stable ID. Never renumber an existing
ID; append one when scope grows. Store the triggering prompt verbatim and state
the inventory basis and coverage limits.

### 4. Run module-batch review rounds

Review one owning module or tightly coupled vertical slice per conversation with
10–50 independently tracked checks. Split larger modules; combine smaller ones
with directly coupled contracts, UI, tests, and documentation.

Prioritize decisions that can invalidate downstream work:

1. application ownership and browser/server trust boundaries;
2. route, form, HTTP, carrier, and webhook contracts;
3. domain and use-case behavior;
4. persistence and external carrier adapters;
5. UI/UX, accessibility, responsive, and Bootstrap behavior;
6. tests, deployment, documentation, and cleanup.

Each round states its module, item count and IDs, a compact findings table,
implemented behavior, why it matters, recommendation, tradeoffs, and one explicit
decision request. A plain batch approval covers only listed checks whose work is
complete; partial answers retain per-check state.

### 5. Persist answer, action, and result

Before acting on an answer, append it to the transcript and active round, then
set the affected state:

- `pending`
- `awaiting-answer`
- `approved`
- `changes-requested`
- `awaiting-re-review`
- `deferred`
- `not-applicable`

For requested changes, preserve approved checks, record the exact agreed action,
implement only that scope, verify it, record evidence, and set affected checks to
`awaiting-re-review`. Never treat implementation as approval.

### 6. Resume and close safely

On continuation, record the message, repeat preflight, find the sole active round,
and continue without replaying approved questions. Keep at most one active
`awaiting-answer`, `changes-requested`, or `awaiting-re-review` round.

Close only when every item is approved, deferred, or not applicable; requested
actions are implemented and re-reviewed; validation passed or its failure was
accepted; and the ledgers agree. A completed checklist never grants permission to
stage, commit, push, merge, or rewrite history.

## Integrity rules

- Prefer source paths, declarations, diffs, and command output over prior claims.
- Preserve stable IDs, historical failures, and previous answers.
- Never approve an item, child, or parent on the assistant's authority.
- Record assistant work as actions, not human decisions.
- Keep the user-facing review self-contained even though ledgers persist state.
