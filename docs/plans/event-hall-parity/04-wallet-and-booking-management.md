# Phase 4: Wallet Holds and Booking Management

## Outcome

Give guests and owners accurate booking-management screens and wallet visibility for pending requests, atomic confirmation debits, held funds, pending host earnings, completed payouts, and terminal statuses.

## Prerequisites

- Phase 3 booking repository and typed models are complete.
- Backend confirmation, hold summary, release completion, and transaction `type` filtering changes are implemented in the environment used by contract tests.

## Booking routes and state

Register `AppRoutes.bookings` in `GoRouter` and link it from the account screen and booking success dialog.

Create separate paginated state for:

- Guest bookings from `GET /bookings/my/guest`.
- Owner requests from `GET /bookings/my/owner`.

Both tabs need independent loading, refresh, load-more, error, and retry state. A failure must not be represented as an empty list.

Booking cards show live listing image/title, dates, night count, total, optional guest count/notes, and status:

- `pending`: Arabic waiting badge.
- `confirmed`: Arabic confirmed/held badge.
- `cancelled`: Arabic cancelled/declined badge.
- `completed`: Arabic completed badge.
- Unknown value: neutral raw-status badge.

## Guest behavior

For a pending card:

- Offer cancellation with confirmation.
- Call `PATCH /bookings/:id/cancel`.
- Replace the card from the returned response or set its status to `cancelled` only after success.
- Keep the card in the list and remove the cancel action.

For a confirmed card:

- Explain that funds are held and the booking cannot be cancelled in-app.
- Offer host chat.
- Do not show a refund or cancellation action.

For completed/cancelled cards, provide status/history only plus appropriate contact/detail navigation.

## Owner behavior

For a pending request:

- Confirm action explains that confirmation will attempt to debit the guest, create a hold, and block dates.
- Decline action accepts an optional reason and calls the backend.
- Disable both actions while either mutation is in flight.

On successful confirmation:

- Replace the card with the returned `confirmed` booking.
- Refresh owner bookings, wallet summary, and booking transactions.
- Show success only after the API response.

On insufficient guest balance, date conflict, already-processed request, or another backend error:

- Keep the card pending unless a refresh proves otherwise.
- Display the backend message.
- Refresh the card/list to reconcile possible concurrent state.
- Never show a false success or locally create a transaction/hold.

On decline success, retain the card with the backend-returned terminal status. Current backend behavior maps decline to `cancelled`; the UI must use the returned status rather than invent `declined`.

## Wallet summary

Replace the balance-only state with a model that parses:

- `balance`: currently spendable wallet balance.
- `currency`.
- `heldBalance`: active holds where the user is the guest.
- `pendingEarnings`: active holds where the user is the host.

Display these as separate labeled values. Do not subtract `heldBalance` from `balance` again: confirmation already debits the guest balance. Do not add `pendingEarnings` to spendable balance before release.

Refresh wallet summary:

- On wallet screen entry/resume.
- On pull-to-refresh.
- After a successful owner confirmation.
- After processing a booking/payment notification.
- After a top-up.

## Transaction model and filters

Separate direction and purpose in code:

- Direction is API `type`: `credit` or `debit`.
- Purpose is API `referenceType`: `top_up`, `promotion`, `subscription`, or `booking`.

`WalletTransaction` stores both. Amount remains an absolute API amount; expose a display signed amount derived from direction rather than mutating the parsed amount. Unknown reference types use a neutral description/icon.

Provide filter state with independent optional values:

- Direction: all, credits, debits.
- Purpose: all, top-ups, promotions, subscriptions, bookings.

Send both selected query parameters when set. Changing either filter resets pagination and cancels/ignores stale responses so results from an old filter cannot append to the new list.

Booking transaction rows must show:

- Guest confirmation debit as a debit associated with the booking.
- Host payout after release as a credit associated with the booking.

Do not label all booking transactions as debits.

## Completion and release presentation

The Flutter app does not release holds. The scheduled backend job is authoritative.

When the backend releases a due hold:

- Host spendable balance increases.
- Host pending earnings decrease.
- A booking credit transaction appears.
- The booking becomes `completed`.

Reconcile this through notification-triggered refresh, screen resume, and manual refresh. Notification handling is best-effort; the UI must become correct from API refresh even if a push/socket notification is missed.

## Tests

Unit tests:

- Wallet parsing for decimal strings and absent summary fields.
- Direction/purpose parsing and signed display amounts.
- Query parameter generation for every independent filter combination.
- Booking status parsing and card action eligibility.

Provider tests with fake Dio/repositories:

- Independent guest/owner pagination.
- Cancellation retains and updates the card.
- Decline retains and updates the card.
- Confirmation success refreshes dependent state.
- Insufficient funds/date conflict retains pending and surfaces the error.
- Stale filter responses cannot pollute current transactions.

Widget tests:

- Guest and owner empty/error/loading/populated tabs.
- Wallet balance, held balance, and pending earnings labels.
- Debit/credit and purpose filters.
- Pending, confirmed, cancelled, completed, and unknown status cards.
- Confirmed cards have no cancel/refund action.

Contract scenarios:

- Confirmation produces one guest debit and one active hold.
- Duplicate confirmation does not duplicate money movement.
- Forced-due release produces one host credit, clears pending earnings, and completes the booking.

## Acceptance gate

- Booking cards always reflect server truth and terminal cards remain visible.
- Wallet summary distinguishes spendable, held, and pending amounts.
- Direction and purpose filters use the correct independent API parameters.
- Confirmation/release changes appear after refresh without client-side wallet emulation.

