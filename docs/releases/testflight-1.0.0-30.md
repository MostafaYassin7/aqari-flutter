# TestFlight 1.0.0 (30)

Signed App Store IPA: `build/ios/ipa/aQora-1.0.0-30.ipa`.

- Bundle: `com.aqar.aqarApp`; signing team: `YA4QLWGFXN`.
- Live API: `https://api.aqora.sa/api/v1`.
- UI preview disabled; event-hall creation enabled for this testing build.
- iOS minimum: 15.0. Photo-library and camera purpose descriptions included.
- IPA version and permissions inspected after export. Distribution signature passed `codesign --verify --deep --strict` using the host trust store. Entitlements include `beta-reports-active=true`, `get-task-allow=false`, and the expected application/team identifiers.
- Latest default suite: 244 passed, 6 preview/live opt-in checks skipped. Separate listing/booking UI preview suite: 176 passed.
- Live repository checks passed for reads, five category-specific drafts (deleted), pending cancellation/decline, and the user-authorized one-night confirmation with one debit/invoice, held funds, blocked date, and duplicate-confirmation rejection.
- MyFatoorah top-up testing accepted as already completed by the user. Hold release was not forced or verified live. Android excluded at the user's request.

Build command:

```sh
flutter build ipa --release --build-name=1.0.0 --build-number=30 --dart-define=UI_PREVIEW=false --dart-define=API_BASE_URL=https://api.aqora.sa/api/v1 --dart-define=EVENT_HALL_CREATION_READY=true --export-options-plist=ios/ExportOptions.plist
```

Delivery: drag the IPA into Transporter and select Deliver. Upload and App Store Connect processing are not completed by producing this artifact.
