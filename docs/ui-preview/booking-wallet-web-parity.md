# Daily-rental booking and wallet UI review

UI preview only. No booking, payment, wallet movement, availability request, or chat message is sent.

References: web `BookingPanel.tsx`, `AvailabilityCalendar.tsx`, account bookings and wallet pages, and `EventHallDetailClient.tsx`. Flutter retains its existing details, calendar, balance card, transaction rows and chip styling.

## Reviewed interactions

- Book now opens date selection when no valid range exists, then the confirmation sheet.
- Past and occupied calendar cells are disabled. Navigation spans the current month through twelve months ahead.
- Selecting an earlier/equal date restarts check-in. A blocked range clears both dates. A too-short stay uses the newly tapped date as check-in, matching web.
- Night counts use calendar dates, independent of daylight-saving hour changes.
- Guest count is optional. Supplied values must be positive integers and respect capacity only when provided. Notes are optional, max 500 characters.
- Sample rental `rent_01` demonstrates capacity six, two-night minimum and arrival/departure times. Other fixtures demonstrate absent optional settings; they do not acquire invented capacity or time defaults.
- Pending request result explains that funds are held on host confirmation. My Bookings and chat destinations remain local previews.
- Guest cancellation is available only for pending requests. Hosts can confirm/decline pending requests; decline reason is optional. Confirmed bookings expose chat. Confirmation explains the web's seven-day post-stay release timing.
- Event halls remain contact-only, with WhatsApp and chat previews and no calendar or booking button.
- Wallet quick amounts match web: 100, 500, 1000, 5000 SAR; custom amount must be finite and at least 100. Payment screen uses fixed sample card data.
- Held balance and pending earnings are hidden when zero. Existing transaction-purpose chips remain; direction chips use the same Flutter styling.
- UI_PREVIEW offers booking success/unavailable/error, booking-list empty/error, wallet zero-summary, and payment-failure scenarios.

## Verification

177 Flutter tests passed with `--dart-define=UI_PREVIEW=true`, including 20 booking/calendar/wallet checks. Widget coverage includes Arabic RTL at 360px, enlarged text and an open-keyboard inset, plus the calendar at 320px with 1.6× text. Regression tests cover payment failure/retry preserving amount and booking failure/retry preserving fields and adding exactly one pending request. Analyzer reported no errors; six existing warnings remain. iPhone 17 Pro preview hot-reloaded successfully.

The iPhone preview is open for interactive review. Android emulator boot succeeded, but the native app build is blocked because `/Users/mostafayassin/Library/Android/sdk/ndk/28.2.13676358/source.properties` is missing. No SDK installation was removed or changed. Flutter’s automatic Gradle configuration edits from this attempted run were reverted. Android-specific visual checks remain. Availability and payment outcomes use fixtures; server checks and integration are deferred to the logic phase.

Calendar confirmation now fits narrow screens with large text. Booking fields and date editing disable during the submission preview; advancing booking/payment dismisses the keyboard.
