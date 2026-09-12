# Listing UI parity audit

Reference: `../aqari-web-finaly/src/app/[locale]/add-listing/`, `src/store/add-listing.store.ts`, `src/lib/property-types.ts`, and `src/data/saudi-cities.ts`.

The existing Flutter category grid, detail counters, facade pills, compact inputs, switches, and review sections are reused. The new pin map is retained. Three role cards and two service cards mirror the web entry. Owner/agent selection within the ownership step exposes the agent branch already supported by the web store.

## Step paths

| Advertiser | Before category | Shared remainder |
| --- | --- | --- |
| Owner | Role, owner information, ownership/license data | Category, photos, information, features, details, optional daily settings, location, review |
| Agent | Same as owner, with agency and agent identity/birth fields | Same |
| Broker | Role, advertisement license and owner identity | Same |
| Host | Role, tourism license | Same |

Daily settings appear for `rent_short` except `event_hall`. Hall details and browsing never create a calendar or booking checkout. The marketing service remains unavailable.

## Fields and checks

- Owner/agent: document type defaults to electronic deed; owner identity defaults to national ID. Document number and the selected identity number are required. National identity also requires birth date and exposes the Hijri flag and optional phone. Commercial registration and unified 700 hide national birth/phone inputs. Multiple-owner ID is optional. Agent requires agency number, agent ID and birth date; agent phone is optional. Switching identity clears incompatible national data. Confirmed skip advances directly and previews a draft outcome.
- Broker: advertisement license and national/commercial owner identity number are required. Host: tourism license is required. Each exposes local accepted/invalid/error verification previews; no real verification occurs.
- Categories: 30 local preview records preserve the category/property/listing-type combinations from the category seed, including the hall category. These are fixtures, not a claim about deployed category availability. Future API connection must replace the fixture source.
- Photos: optional; JPG/JPEG/PNG/WEBP, maximum 15 MiB each; local selection, deletion, ordering and first-photo cover. No video field. No upload or three-photo minimum.
- Information: title required, up to 100 characters; price and area required, finite and positive. Description optional, up to 2000 characters. Usage choice and commission toggle retained; optional commission percentage, when entered while enabled, accepts 0–100.
- Features: optional. Residential shows water/electricity/sewage/private roof/in villa/two entrances/special entrance. Land shows only utilities. Other groups show no additional features.
- Residential details: original room counters, floor, age, street width, facade, furnishing/kitchen/extra unit/car entrance/elevator. Commercial: bathroom counter, floor, age, street width, facade. Land: street width and facade. Other: no additional detail fields. Details are optional; number controls retain nonnegative bounds.
- Halls: optional positive integer capacity, optional nonnegative half-day price, optional catering/sound/projector/decoration/security/parking selections.
- Daily settings: optional positive integer capacity; required integer minimum nights, default 1; optional arrival/departure time pickers.
- Location: same city/district option values and labels as the web. City and explicitly selected valid map coordinates required. District and address optional. District clears when city changes; pin placement survives step navigation. The map is a local visual preview, not geocoding.
- Review: original section styling with edit links keyed by step identity. Rechecks fields before presenting the appropriate draft/review/publication preview. No actual submission or saved server draft.

## Verification

143 branch/state tests and 13 widget tests cover the available category/role combinations, identity/document variants, skip rules, optional fields, limits, stale-field clearing, restored controls, review editing, and required-field labels. Widget tests load a local SDK font to avoid external requests; simulator review uses the application's Cairo font.

## Preview launch

`flutter run --dart-define=UI_PREVIEW=true`

Preview mode starts at home and blocks API calls before reading authentication. Optional `--dart-define=PREVIEW_ROUTE=/add-listing` opens the wizard directly.

The current simulator build lives in `/private/tmp/aqari-ui-preview-ios` because the workspace's existing iOS 13 target conflicts with its installed Maps plugin. Only that temporary copy uses an iOS 15 target. Production native configuration was not upgraded for this UI work.
