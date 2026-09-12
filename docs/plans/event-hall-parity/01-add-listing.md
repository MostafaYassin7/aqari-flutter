# Phase 1: Add Listing and Shared Category Foundation

## Outcome

Replace the mock/hardcoded Flutter listing wizard with a live, category-aware creation flow that uses the same category rules and listing payload semantics as the web app.

## Prerequisites

- Read the Flutter, web, and backend instructions and inspect current DTOs before editing.
- Preserve existing advertiser/license behavior from the web flow. The Flutter implementation must send a valid `advertiserType` and `licenseId` where required rather than inventing a mobile-only shortcut.
- Backend may be locally mocked during development, but the production CTA remains gated on the active `event_hall` category.

## Shared types and category behavior

Add `PropertyType.eventHall = 'event_hall'` and centralize category behavior in one helper used by state cleanup, step generation, review rendering, detail rendering, and payload construction.

The helper must define:

- Residential: `apartment`, `villa`, `house`, `floor`, `chalet`, `rest_house`, and `farm`.
- Commercial: `shop`, `commercial_office`, `warehouse`, and `building`.
- Land: `land`.
- Event Hall: `event_hall`.
- Daily rental: `listingType == rent_short && propertyType != event_hall`.
- Bookable: identical to daily rental. Never equate all `rent_short` listings with bookable listings.

Add included-service constants using the backend values:

- `catering`
- `sound_system`
- `projector`
- `decoration`
- `security`
- `parking`

Provide Arabic labels centrally. Unknown values returned by the API should display safely as their raw value rather than crash.

## Category loading and state

Replace the private hardcoded category list in Step 1 with active records from `GET /listing-categories`, sorted by the backend response. Reuse or relocate the existing categories provider rather than creating duplicate network state.

Store the selected `ListingCategory` or these immutable fields together:

- `categoryId`
- `categoryNameAr`
- `propertyType`
- `listingType`

Never derive API enum values back from an Arabic label.

Extend `AddListingState` with:

- Required listing data: `title`, `city`, `district`, nullable latitude/longitude or an explicit `locationSelected` flag.
- Advertiser/license data required to match the web flow.
- Bookable data: `maxGuests`, `checkInTime`, `checkOutTime`, `minNights` defaulting to 1.
- Event Hall data: `pricePerHalfDay`, `includedServices`.
- Submission state: submitting flag, general error, and field-error map.

Use a nullable-copy sentinel consistently for every nullable field. Do not use non-null default coordinates as evidence that a user selected a location.

When category changes:

- Clear every field not supported by the new property group.
- Clear daily-rental timing/minimum-night fields for Event Hall.
- Clear Event Hall half-day price/services for daily rentals.
- Clear all six bookable fields for non-short-term listings.
- Reset validation errors belonging to hidden fields.

## Preset route and authentication return

Register `/add-listing` so its builder reads optional `propertyType` from `GoRouterState.uri.queryParameters` and passes it into the wizard.

For `/add-listing?propertyType=event_hall`:

1. Load active categories.
2. Select the single active category whose `propertyType` matches.
3. Preserve the selection unless the user explicitly changes it.
4. If no match exists, block the wizard with an Arabic error and retry action. Do not select the first category.

Update authentication redirects to preserve the full intended local URI in an encoded `returnTo` parameter. Propagate it through login, phone, OTP, and registration, then return after authentication. Accept only local paths beginning with `/`; reject external URLs to avoid open redirects.

## Dynamic wizard

Generate a list of step descriptors with stable IDs instead of hardcoded indexes. Review edit actions must resolve a step ID at runtime so inserting Step 5b does not send the user to the wrong page.

Step 5 fields:

| Group | Visible fields |
| --- | --- |
| Residential | Bedrooms, living rooms, bathrooms, floor, property age, street width, facade, and supported residential feature toggles |
| Commercial | Bathrooms, floor, property age, street width, facade |
| Land | Street width and facade |
| Event Hall | Optional capacity, optional half-day price, included-service checkboxes |

For Event Hall, hide rooms, bathrooms, floor, age, street width, facade, furnishing, kitchen, elevator, car entrance, and unrelated generic feature controls.

Insert `Step5bBookingSettings` only for daily rentals. It contains:

- Optional maximum guests, integer >= 1 when present.
- Minimum stay, integer >= 1 and default 1.
- Optional check-in and check-out time, formatted exactly `HH:mm` using platform-appropriate time pickers.

## Real media, location, validation, and submission

Replace Picsum simulation with `image_picker`. Upload selected files using the existing authenticated media endpoint and retain upload progress/error state. The first successfully uploaded URL is the cover ordering. Do not call `POST /listings` unless required uploads succeed.

Replace the painted map/default coordinate behavior with `GoogleMap` using the already-declared package. Require a deliberate tap/drag selection and store finite latitude/longitude within valid bounds. City remains a separate required input; address/district remain optional unless the backend contract changes.

Client validation before submission:

- Non-empty title.
- Numeric price > 0.
- Numeric area > 0.
- Selected city.
- Valid, explicitly selected coordinates.
- `minNights >= 1` for daily rentals.
- Optional numeric capacity >= 1.
- Optional half-day price > 0.
- Times are valid `HH:mm` strings.

Update the Dio error layer to preserve string or list validation messages and expose a typed failure containing general and field errors. Do not replace backend field errors with generic English status messages.

Build the request in a pure, unit-tested payload builder. It must:

- Send `categoryId`, `propertyType`, and `listingType` from the selected API category.
- Send numbers as numbers and booleans as booleans.
- Include advertiser/license values required by the selected role.
- Include only the category-compatible details listed above.
- For daily rental, send `maxGuests`, times, and `minNights`, including the value 1.
- For Event Hall, send `maxGuests`, `pricePerHalfDay`, and a non-empty services list; omit empty optional values.
- For all other types, omit all six bookable/Event Hall fields.

Review must render the same sanitized interpretation that will be submitted. On API field errors, remain in the wizard and navigate to the first affected step. Disable duplicate publish taps. Reset state and show success only after the API confirms creation.

## Tests

Unit tests:

- Property-group membership and bookability, especially `event_hall + rent_short`.
- State clearing across every category transition.
- Payload whitelisting with intentionally injected stale hidden values.
- Numeric, time, coordinate, and minimum-night validation.
- Structured Dio field-error parsing.

Widget/provider tests:

- API categories loading, empty/error/retry, and selection.
- Preset selection and unavailable preset blocking.
- Dynamic step count and stable review edit destinations.
- Every Step 5 field matrix and daily-only Step 5b.
- Upload and submission loading/error/success states.

## Acceptance gate

- Residential, commercial, land, daily-rental, and Event Hall submissions match their permitted payload fields.
- The preset survives login and selects Event Hall after category loading.
- Invalid or unavailable data produces actionable field-level UI.
- No mock photos, fake map coordinates, or fake publish success remain in this flow.

