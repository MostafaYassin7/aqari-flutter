# Flutter Parity: Event Halls, Add Listing, Daily Rentals, and Wallet Holds

## Purpose

This is the master implementation handoff for bringing the Aqari Flutter app to functional parity with the web app for the following connected flows:

- Category-aware Add Listing
- Event-hall discovery, creation, and contact-only details
- Daily-rental availability and booking
- Guest/owner booking management
- Wallet debits, held funds, pending host earnings, and released payouts

This is functional parity, not pixel-for-pixel visual parity. Use the existing Flutter design system and Arabic UI conventions. English localization and unrelated web features are outside this effort.

## Repositories and source of truth

- Flutter: `/Users/mostafayassin/Projects/aQora/aqari-flutter`
- Web reference: `/Users/mostafayassin/Projects/aQora/aqari-web8`
- Backend/API: `/Users/mostafayassin/Projects/aQora/aqari-backend`
- Cross-repository backend/web plan: `../aqari-web8/EVENT_HALL_DAILY_RENTAL_WALLET_HOLD_PLAN.md`

Always read any `AGENTS.md` files that exist when implementation begins and preserve unrelated worktree changes.

## Non-negotiable product rules

1. Event halls use `propertyType=event_hall` and `listingType=rent_short`, but are contact-only.
2. Event halls never show or call availability, calendar, or booking functionality.
3. Daily rentals are `rent_short` listings whose property type is not `event_hall`.
4. A booking request starts as pending and moves no money.
5. Owner confirmation atomically debits the guest and creates a wallet hold. It may fail for insufficient balance or a date conflict.
6. Held money becomes host pending earnings and is released by the backend after the configured post-stay period.
7. Only pending bookings may be cancelled. Confirmed-booking refunds and disputes are out of scope.
8. Cancelling or declining updates the visible booking card; it does not remove it.
9. Category-hidden fields must be cleared from state and independently omitted from the submitted payload.

## Current Flutter baseline

The implementation agent must not assume the old prompt describes existing code. At handoff time:

- Add Listing uses hardcoded Arabic category labels instead of API categories.
- Add Listing state does not retain category ID, property type, listing type, title, or city.
- The publish action only displays a success dialog; it does not call `POST /listings`.
- Media uses Picsum placeholder URLs and location uses a painted placeholder with default coordinates.
- Daily-rental details use mock records and a mock calendar modal.
- No bookings feature repository/provider/screens currently exist.
- `AppRoutes.bookings` exists, but the router does not register a bookings page.
- The authentication redirect loses the originally requested route and query string.
- Wallet parsing already sees transaction direction but filters only by `referenceType`; wallet summary ignores `heldBalance` and `pendingEarnings`.
- The current broad `rent_short` search can include event halls in the daily-rental feed.
- The Dio error interceptor can lose structured validation messages and contains debug logging that should not be extended.

## Dependency gate

Flutter development can use mocks/tests while backend work proceeds, but production enablement depends on the backend plan being deployed and verified:

- `GET /listing-categories` returns an active Event Hall category.
- Listing persistence normalizes category-specific fields.
- Booking and availability endpoints reject event halls with a clear `400` contact-only response.
- Booking confirmation is atomic and notification failures are best-effort after commit.
- Due hold release credits the host once and marks the booking completed.
- `GET /wallet/transactions` accepts `type=credit|debit` separately from `referenceType`.

Do not expose a production Event Hall creation CTA until this gate passes.

## Implementation order

Complete and verify the plans in this order:

1. [Add Listing and shared category foundation](docs/plans/event-hall-parity/01-add-listing.md)
2. [Event Hall discovery and details](docs/plans/event-hall-parity/02-event-halls.md)
3. [Daily-rental availability and booking](docs/plans/event-hall-parity/03-daily-rental-bookings.md)
4. [Wallet and booking management](docs/plans/event-hall-parity/04-wallet-and-booking-management.md)
5. [End-to-end verification and rollout](docs/plans/event-hall-parity/05-end-to-end-rollout.md)

Each file is intended to be independently implementable and testable. Do not begin a later phase until the preceding acceptance gate passes.

## Shared API contracts after backend completion

| Operation | Contract |
| --- | --- |
| Categories | `GET /listing-categories` returns active category records including `id`, `name`, `nameAr`, `propertyType`, `listingType`, and `isActive`. |
| Create listing | `POST /listings` retains its existing DTO and supports `maxGuests`, `checkInTime`, `checkOutTime`, `minNights`, `pricePerHalfDay`, and `includedServices`. |
| Listing calendar | `GET /listings/:id/calendar?year=YYYY&month=M` is daily-rental-only after backend enforcement. |
| Availability | `POST /bookings/check-availability/:listingId` accepts daily-rental `checkInDate` and `checkOutDate`; event halls return `400`. |
| Booking request | `POST /bookings` creates a pending daily-rental request. |
| Booking lists | `GET /bookings/my/guest` and `GET /bookings/my/owner` return paginated bookings with listing relations. |
| Booking actions | `PATCH /bookings/:id/confirm`, `/decline`, and `/cancel`. |
| Wallet summary | `GET /wallet` returns at least `balance`, `currency`, `heldBalance`, and `pendingEarnings`. |
| Transactions | `GET /wallet/transactions` supports independent `type` and `referenceType` filters plus pagination. |

Treat backend response totals, booking statuses, balances, and blocked dates as authoritative.

## Final acceptance matrix

- [ ] Residential listing creation shows and submits only residential fields.
- [ ] Commercial listing creation shows and submits only commercial fields.
- [ ] Land listing creation shows and submits only land fields.
- [ ] Daily-rental creation includes Step 5b and submits sanitized stay settings.
- [ ] Event Hall preset routing survives login and selects the active API category.
- [ ] Event Hall creation submits hall-only fields and omits all booking settings.
- [ ] Event halls are discoverable and show capacity, pricing, services, chat, and WhatsApp.
- [ ] Event halls expose no calendar/booking controls or booking API calls.
- [ ] Event halls never appear in the Daily Rental feed.
- [ ] Daily-rental details use live data and enforce minimum nights and blocked dates.
- [ ] Guests can request and cancel pending bookings; cancelled cards remain visible.
- [ ] Owners can confirm or decline pending requests with truthful failure handling.
- [ ] Confirmation shows guest debit/held funds and host pending earnings.
- [ ] Scheduled release produces one host credit and a completed booking.
- [ ] Wallet direction filters use `type`; semantic filters use `referenceType`.
- [ ] Flutter formatting, analysis, unit/widget tests, integration tests, and target builds pass.

## Explicit non-goals

- Pixel-matching the web UI
- Whole-product Flutter/web parity outside these flows
- Making event halls bookable
- Confirmed-booking cancellation, refunds, or disputes
- A new English localization framework
- Client-side emulation of wallet movement or hold release

