# Phase 5: End-to-End Verification and Rollout

## Outcome

Prove the completed Flutter flows match the web product rules against the deployed backend, then enable them in dependency-safe order.

## Automated quality gates

Run from the Flutter repository:

```sh
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
```

Run the project’s integration-test command for affected journeys. If no integration harness exists, add `integration_test` using Flutter’s SDK package and document the exact device/emulator command in the repository README or test directory.

Build at least the supported mobile targets used by the team:

```sh
flutter build apk
flutter build ios --no-codesign
```

If environment-specific credentials prevent a target build, record the exact external prerequisite; do not treat an unrelated signing failure as a feature pass.

## Backend readiness gate

Before enabling Event Hall production entry points, verify on the target API:

1. `GET /listing-categories` contains one active `event_hall` category with `listingType=rent_short`.
2. A valid Event Hall listing can be created with capacity, half-day price, and included services.
3. Event Hall availability and booking requests both return the intended contact-only `400`.
4. A daily-rental request can be created pending.
5. Owner confirmation with insufficient guest funds changes no booking/wallet/hold/date state.
6. Successful confirmation performs one debit, one invoice, one hold, date blocking, and confirmed status.
7. A forced-due hold release performs one host credit/invoice and sets booking completed.
8. Repeating confirmation/release cannot duplicate effects.
9. `GET /wallet/transactions?type=credit` and `type=debit` return the correct directions while `referenceType=booking` continues to filter by purpose.

Backend failures in this gate block Flutter production rollout; they are not worked around in the client.

## Integration journeys

Automate where practical and manually smoke-test every scenario below on both a small Android device and an iPhone-size simulator.

### Category-aware creation

- Residential: correct fields visible; hidden commercial/Event Hall/daily fields absent from payload.
- Commercial: bathrooms/floor/age/street/facade only; no bedroom/kitchen/furnishing payload.
- Land: street width/facade only.
- Daily rental: Step 5b present; minimum stay and optional times/capacity submitted.
- Event Hall: preset survives unauthenticated login; hall category selected; hall-only fields submitted; Step 5b absent.
- Switch categories after filling each specialized form and confirm stale values are cleared from state, review, and request body.
- Invalid title, price, area, city, coordinates, minimum nights, or API field response keeps the user on the relevant step.

### Event Hall browsing

- Event Hall appears in its dedicated feed and not in Daily Rentals.
- Detail shows full-day/half-day pricing, capacity, and service chips.
- Missing optional fields render cleanly.
- Chat opens the correct listing conversation.
- WhatsApp opens the normalized advertiser number.
- No calendar, booking CTA, or booking network call occurs.

### Daily-rental booking

- Past dates and backend-blocked dates cannot be selected.
- Checkout is not blocked as an occupied night.
- A range containing a blocked night is rejected.
- Minimum-night rule is enforced.
- Availability is rechecked before booking creation.
- Login return restores dates but does not auto-submit.
- Successful booking appears pending and causes no immediate wallet change.

### Booking management and wallet

Use separate guest and host accounts:

- Guest cancels pending; the card stays visible as cancelled.
- Owner declines pending; both views reconcile to the returned terminal status.
- Insufficient guest balance leaves the request pending and displays the backend error.
- After top-up, owner confirmation succeeds; guest balance decreases, held balance increases, and a booking debit appears.
- Host sees pending earnings but no spendable credit before release.
- Confirmed booking exposes chat but no cancellation/refund control.
- Force the hold due, run release, refresh both clients, and verify host balance/credit plus completed booking.
- Repeat the release and verify no second credit or status regression.
- Filter transactions independently by credit/debit and booking/top-up purpose.

## Observability and failure handling

- Remove or gate token/body `print` logging before release; never log JWTs, phone numbers, booking notes, or wallet payloads in production.
- Preserve backend messages for actionable `400` responses while providing Arabic fallbacks for offline, unauthorized, and server failures.
- Log unexpected parsing/network failures through the app’s approved diagnostics mechanism without exposing secrets.
- All mutation buttons must prevent duplicate taps and reconcile state after ambiguous timeouts by refetching.

## Rollout sequence

1. Deploy and verify backend migrations/services.
2. Deploy the web flow and confirm the shared contract in staging.
3. Merge Flutter phases behind existing environment/release controls; keep Event Hall CTA hidden if the production category gate fails.
4. Run the complete staging matrix with separate guest/host accounts.
5. Release Flutter to internal testers, monitor API `400/409/5xx` rates for listing/booking/wallet endpoints, then promote normally.
6. After release, verify the live Event Hall feed and one safe end-to-end daily-rental transaction using controlled accounts.

## Definition of done

- Every checklist item in the master plan is checked with test or smoke-test evidence.
- No mock data or fake success behavior remains on the affected production paths.
- Flutter and web follow the same category, booking, and wallet rules.
- Event Hall remains contact-only at UI and API boundaries.
- Required automated checks and supported builds pass.
- Known external rollout prerequisites are documented with owners rather than hidden as client fallbacks.

