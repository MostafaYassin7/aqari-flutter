# TestFlight 1.0.0 (31)

Theme and licensing-introduction update on top of build 30.

- Light/dark/system settings now control MaterialApp and persist across launches.
- Shared surfaces, cards, text, dividers, sheets, chips, and icons follow the selected app theme; fixed light backgrounds no longer inherit dark-theme text.
- Field labels remain visible above their inputs, with stronger hint and selected-state contrast.
- Restored the owner/agent licensing introduction: green notice, dedicated card, numbered steps, requirements, and the next-step explanation. Removed unconditional preview-only explanatory copy from that production step.
- Preserved existing navigation and backend submission behavior. Gold button labels and map price labels remain legible in both themes.

Verification:

- Flutter analyzer: no issues.
- Default suite: 248 passed; 28 opt-in/preview checks skipped.
- Separate visual review: 22 screenshots/tests passed across 11 screens in light and dark mode using cached Cairo and Material icon fonts.
- Explicit light-on-dark-device, dark-on-light-device, automatic mode, theme persistence, and licensing-card contrast tests passed.
- Visual review files: `/private/tmp/aqari-theme-review` (local, generated; not app assets).

Build command:

```sh
flutter build ipa --release --build-name=1.0.0 --build-number=31 --dart-define=UI_PREVIEW=false --dart-define=API_BASE_URL=https://api.aqora.sa/api/v1 --dart-define=EVENT_HALL_CREATION_READY=true --export-options-plist=ios/ExportOptions.plist
```

Upload the verified `build/ios/ipa/aQora-1.0.0-31.ipa` through Transporter. The fixes are not present in build 30.
