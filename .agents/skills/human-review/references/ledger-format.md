# Transcript and Checklist Ledger Format

## Contents

1. Transcript entry
2. Checklist header
3. Review item
4. Active module-batch round
5. Review log
6. Coverage audit

## Transcript entry

Append entries chronologically:

```markdown
## YYYY-MM-DD — Short event title

### User message

> Verbatim prompt or answer

### Actions

- Read or changed concrete paths.
- Record material implementation decisions, worker handoffs, and corrections.

### Verification

- `exact command`: passed, failed, or unavailable with a concise reason.
```

Omit an empty verification heading.

## Checklist header

```markdown
# Implementation Human Review Checklist

## Stored requests

> Verbatim triggering prompt

## Protocol

- Owner: human reviewer
- State: active
- Inventory basis: working tree at `<revision>` plus staged and untracked files
- Last reconciled: `YYYY-MM-DD`
- Current round: `R-NNN`

### State legend

- `[ ]` + `pending`
- `[ ]` + `awaiting-answer`
- `[x]` + `approved`
- `[ ]` + `changes-requested`
- `[ ]` + `awaiting-re-review`
- `[ ]` + `deferred`
- `[ ]` + `not-applicable`
```

Use textual state because a checkbox alone cannot distinguish all states.

## Review item

Use stable IDs and concrete evidence:

```markdown
- [ ] `TRACK-SVC-001` — `lookupShipment`
  - State: `pending`
  - Evidence: `src/lib/server/tracking/service.ts`
  - Review: identifier validation, carrier selection, normalized result, errors
  - Decision: —
```

Use one item per independently reviewable function, structure, interface,
contract, or user-visible behavior. Parent items may orient but cannot be
approved until every in-scope child has a terminal state.

## Active module-batch round

Keep exactly one active round:

```markdown
## Active review round

### R-001 — Tracking lookup slice (18 checks)

- State: `awaiting-answer`
- Asked: `YYYY-MM-DD`
- Items: `API-TRACK-001` through `API-TRACK-006`, `TRACK-SVC-001` through
  `TRACK-SVC-012`
- Findings:

  | Check           | State | Finding and evidence               |
  | --------------- | ----- | ---------------------------------- |
  | `API-TRACK-001` | ready | Form action in `src/routes/...`    |
  | `TRACK-SVC-001` | ready | Use case in `$lib/server/tracking` |

- Question: Do you approve this module batch?
- Evidence: `path`, `path`
- Recommendation: ...
- Tradeoffs: ...
- User answer: awaiting
- Agreed action: none
- Action result: none
- Verification: none
```

When resolved, move the data into the review log before opening another round.

## Review log

Keep a compact navigation table, followed by detail when needed:

```markdown
| Round   | Module / Items                | Result   | Date       |
| ------- | ----------------------------- | -------- | ---------- |
| `R-001` | Tracking lookup (`18 checks`) | approved | YYYY-MM-DD |
```

For changes, retain the original answer, agreed action, modified paths, command
evidence, and re-review decision.

## Coverage audit

Before claiming completion, compare the checklist with:

- changed, staged, deleted, and untracked files;
- TypeScript/Svelte production declarations and exported behavior;
- routes, loads, actions, endpoints, hooks, APIs, and webhooks;
- carrier-neutral contracts, provider adapters, persistence schemas/migrations,
  caches, and queues when present;
- components, layouts, interactions, accessibility, and responsive states;
- tests, fixtures, manifests, vendor assets, scripts, deployment, and docs.

Record:

```markdown
## Coverage audit

- Working-tree files represented: `N/N`
- Production declarations represented: `N/N`
- Routes/actions/endpoints represented: `N/N`
- Carrier/persistence contracts represented: `N/N`
- UI behaviors represented: `N/N`
- Tests/fixtures represented: `N/N`
- Known exclusions: ...
- Result: passed | incomplete
```

Counts support evidence; they never replace checking actual mappings.
