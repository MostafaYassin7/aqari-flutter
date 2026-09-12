# Phase 2: Event Hall Discovery and Contact-Only Details

## Outcome

Make Event Halls discoverable and fully describable in Flutter while guaranteeing that users can contact the advertiser but cannot access booking or availability features.

## Prerequisites

- Phase 1 shared property helpers and listing parsing are complete.
- The local/staging category endpoint returns one active `event_hall` category.
- Backend booking and availability rejection is implemented or represented by contract tests/mocks.

## Data model and repository behavior

Extend the live `Listing` model to parse:

- `maxGuests`
- `pricePerHalfDay`
- `includedServices`
- `checkInTime`
- `checkOutTime`
- `minNights`
- The nested `__owner__` object: owner ID if returned, name, phone, profile photo, and role.

Use tolerant numeric parsing because decimal database values can arrive as strings. Missing optional fields become null/empty collections, not zero values that look intentional.

Do not infer Event Hall from an Arabic category name. Use `propertyType == event_hall` only.

## Discovery surfaces

Add a dedicated Event Halls entry from the same home/discovery level used by the web product. Its listing request must filter on `propertyType=event_hall`; it must not rely only on `listingType=rent_short`.

The Event Halls screen must support:

- Initial loading skeleton/progress.
- Empty state.
- Network error and explicit retry.
- Refresh and existing pagination conventions where supported.
- Navigation to `/property/:id` using the live listing ID.
- Add Listing CTA to `/add-listing?propertyType=event_hall`.

Update Daily Rental discovery defensively:

- Extend `DailyRental` with `propertyType`, or parse daily results through `Listing`.
- Remove every `propertyType=event_hall` item from daily-rental provider state before rendering, even if the backend search returns all `rent_short` results.
- Never route an Event Hall into the rental details/calendar screen.

## Event Hall detail rendering

Use the live `/listings/:id` response. Remove mock owner/contact data from the Event Hall path.

Render:

- Capacity when present: `الطاقة الاستيعابية: N ضيف`.
- Full-day price from `totalPrice`.
- Optional half-day price from `pricePerHalfDay`.
- Included services as Arabic chips using the shared constants.
- Existing description, media, location, advertiser, and listing metadata.

Do not render zero/empty placeholders for absent optional hall fields.

## Contact-only enforcement in Flutter

For `PropertyTypeGroup.isEventHall`:

- Show chat and WhatsApp actions.
- Hide the calendar, date selection, minimum-night text, booking CTA, booking confirmation sheet, and booking status actions.
- Do not initialize booking providers or fire calendar/availability requests.
- Do not expose a deep link that starts a booking for the hall.

Chat uses the existing find-or-create flow with the live listing owner ID and listing ID. Disable it with an Arabic explanation if owner identity is missing.

Add `url_launcher` and open WhatsApp with an encoded `https://wa.me/<normalized-number>` URL. Normalize Saudi/international numbers without changing a known country code. If phone is unavailable or launch fails, show an Arabic error rather than a success placeholder.

The backend remains the security boundary. If a stale/deep-linked client request receives the contact-only `400`, display the backend message and return to the contact-only detail state.

## Tests

Unit tests:

- Event Hall model parsing for numeric strings, missing optionals, services, and owner contact.
- Daily-rental filtering excludes Event Hall even though both are `rent_short`.
- WhatsApp number/URI construction and invalid-number handling.

Widget tests:

- Feed loading, retry, empty, populated, and Add Listing preset navigation.
- Detail rendering with full fields and with all optional hall fields absent.
- Service labels and unknown-service fallback.
- Chat and WhatsApp enabled/disabled states.
- No booking/calendar widget exists for Event Hall and no booking repository method is invoked.

Contract test:

- An attempted Event Hall availability or booking request returns and surfaces the expected contact-only `400`.

## Acceptance gate

- Event halls are discoverable separately and do not appear in Daily Rentals.
- Hall details use live API data and show correct price/capacity/services.
- Chat and WhatsApp work with live owner data.
- No Event Hall screen calls or exposes booking functionality.

