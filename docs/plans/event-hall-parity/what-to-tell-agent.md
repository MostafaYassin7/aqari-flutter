
  Implement Phase 1 of the Flutter parity work.

  Repository:
   /Users/mostafayassin/Projects/aQora/aqari-flutter

  First read completely:
  - remaining-event-hall-prompt.md
  - docs/plans/event-hall-parity/01-add-listing.md
  - all applicable AGENTS.md files

  Treat those documents as the source of intent, but inspect the current Flutter, web, and
  backend code before editing so implementation follows the real APIs and repository
  conventions.

  Requirements:
  - Implement the phase fully; do not merely produce another plan.
  - Preserve unrelated worktree changes.
  - Use the web app at ../aqari-web8 as the functional reference.
  - Use ../aqari-backend as the API-contract source.
  - Do not modify the web or backend repositories unless I explicitly authorize it.
  - Do not expose production Event Hall creation if the backend readiness gate has not passed.
  - Add the specified unit and widget tests.
  - Run Dart formatting checks, flutter analyze, and relevant tests.
  - Fix failures caused by this work.
  - Report changed files, verification results, remaining blockers, and whether the phase
  acceptance gate passed.
  - Do not proceed to Phase 2 until Phase 1 is complete and verified.

  For later phases, use:

  Continue the Flutter parity implementation with Phase N.

  Repository:
   /Users/mostafayassin/Projects/aQora/aqari-flutter

  Read completely:
  - remaining-event-hall-prompt.md
  - docs/plans/event-hall-parity/0N-<phase-name>.md
  - all applicable AGENTS.md files

  Confirm the preceding phase’s acceptance gate still passes, then implement this phase fully.
  Inspect the current code and backend contracts before editing, preserve unrelated changes, add
  the required tests, run formatting/analyze/tests, fix relevant failures, and report whether
  this phase’s acceptance gate passed. Do not begin the next phase.

  Recommended sequence:

  1. 01-add-listing.md
  2. 02-event-halls.md
  3. 03-daily-rental-bookings.md
  4. 04-wallet-and-booking-management.md
  5. 05-end-to-end-rollout.md