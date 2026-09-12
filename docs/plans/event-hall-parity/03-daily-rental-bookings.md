# Phase 3: Daily-Rental Availability and Booking

## Outcome

Replace mock rental details/calendar behavior with live daily-rental availability, date-range selection, booking requests, and typed booking state.

## Prerequisites

- Phase 1 property helpers and live listing models are complete.
- Phase 2 filtering guarantees Event Halls cannot enter this flow.
- The backend daily-rental endpoints are available in the target environment.

## Models and repository

Add typed models for:

- Booking with IDs, listing relation, guest/owner IDs, check-in/out dates, nights, guest count, total price, notes, status, and timestamps.
- Calendar block with date and optional time slot. Daily rental logic treats any returned block for that date as unavailable.
- Availability result with `isAvailable` and optional `blockedDates`.
- Paginated booking response with data, total, and page count.

Keep status parsing forward-compatible. Render known statuses `pending`, `confirmed`, `cancelled`, and `completed`; preserve unknown statuses as a neutral badge rather than throwing.

Create a booking repository around the exact backend routes:

- `POST /bookings/check-availability/:listingId`
- `GET /listings/:id/calendar?year=&month=`
- `POST /bookings`
- `GET /bookings/my/guest`
- `GET /bookings/my/owner`
- `PATCH /bookings/:id/confirm`
- `PATCH /bookings/:id/decline`
- `PATCH /bookings/:id/cancel`

All repository methods must propagate the typed API failure from Phase 1. Do not swallow network errors into empty collections.

## Live daily-rental details

Load daily-rental details from `/listings/:id`; remove `mockRentals` and mock extras from the production path.

Show:

- Nightly price from `totalPrice`.
- Optional check-in/check-out times.
- Minimum nights when greater than 1.
- Optional maximum guests.
- Existing live media, description, amenities/features, location, and owner data.

The booking section appears only when `isDailyRental(propertyType, listingType)` is true. Regular sale/long-rent listings and Event Halls must not instantiate it.

## Availability calendar

Build a reusable RTL month-grid range selector without requiring a third-party calendar package unless one is already adopted elsewhere.

Rules:

- Start on the current local month; allow navigation through twelve months ahead.
- Disable dates before today.
- Load blocked dates for every displayed month and cache by `year-month` for the widget lifetime.
- A first tap selects check-in.
- A later tap on or before check-in restarts selection at that date.
- A later valid tap selects checkout.
- Checkout is not a booked night; calculate nights as the date difference.
- Reject a range containing any blocked night.
- Reject a range shorter than `minNights` and leave the new tap as the next check-in.
- Clear the summary callback whenever selection becomes incomplete.
- Render loading and retry inside the calendar without discarding a valid selection from another loaded month.
- Use date-only comparisons and ISO `YYYY-MM-DD`; do not let timezone conversion shift selected dates.

Before enabling final request submission, call the availability endpoint with the selected check-in/out dates. If unavailable, display the blocked-date message, invalidate the selection, and refresh affected calendar months.

## Booking request sheet

Show the selected dates, night count, preview total, and these optional inputs:

- Guest count, integer >= 1 and <= `listing.maxGuests` when capacity exists.
- Notes, maximum 500 characters.

The backend total is authoritative; the local total is only a preview.

Truthful payment copy:

- Submitting a request does not debit the wallet.
- If the owner confirms, the full booking amount is debited from the guest wallet and held until backend release.
- Encourage the guest to maintain sufficient balance.

If unauthenticated, preserve the full rental route and selected dates in the local booking provider, navigate through login with `returnTo`, restore the pending selection after authentication, and require the user to tap final confirmation again. Never auto-submit after login.

On success:

- Add the returned pending booking to guest state.
- Close the sheet.
- Show an Arabic success dialog with actions for My Bookings and host chat.
- Do not claim payment occurred.

On failure, retain all input, re-enable submission, and display the backend message.

## Tests

Unit tests:

- Date-only parsing across timezone boundaries.
- Night counting and checkout exclusion.
- Minimum-night validation.
- Blocked date inside ranges and at boundaries.
- Guest-count bounds and total preview.
- Repository request and response parsing.

Widget/provider tests:

- Month navigation, loading, retry, and cached blocked dates.
- Range selection/reset and blocked/minimum-night messages.
- Booking widget visibility for daily rental only.
- Unauthenticated return/restore without auto-submit.
- Availability recheck and request success/error states.
- Payment copy correctly distinguishes request from confirmation.

## Acceptance gate

- Daily-rental details and calendars use live API data.
- Blocked dates and minimum nights behave correctly.
- The server is rechecked before request submission.
- A successful request creates a visible pending booking without changing wallet UI locally.
- No Event Hall can enter this flow.

