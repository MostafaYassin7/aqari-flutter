# Current integration verification

The approved UI was snapshotted locally before edits. Archived screens have not been restored. Current Flutter routes, role/service cards, step order and component styles are retained.

Target API confirmed by user: https://api.aqora.sa/api/v1. Two supplied accounts authenticated; credentials/tokens exist only in a private temporary directory outside the repository. No financial mutations performed yet.

Fresh read-only observations:
- Categories: 16 active/returned records, including one active event_hall/rent_short category.
- Wallet: balance, currency, heldBalance, pendingEarnings present.
- Guest and owner booking lists: data, total, pages envelope.

Phase 1 implementation in progress: shared whitelist; structured errors and safe network diagnostics; server categories in existing cards; role-specific license requests and retained IDs; real authenticated uploads; real coordinates in existing map area; actual creation response and error routing; encoded local authentication return. Production Hall creation remains disabled until the complete deployed readiness matrix is verified.

Fresh checks: 49 payload/auth/API contract tests passed. Remaining acceptance items are tracked as incomplete; prior archived reports are not evidence.

Known environment prerequisites: native iOS preview currently uses a temporary copy with iOS 15 deployment target. Repository deployment settings are unchanged. Android NDK installation lacks source.properties; Android native builds currently fail before application compilation.

## Current simulator testing

The actual workspace app now builds and launches on iPhone 17 Pro against the live API, with UI_PREVIEW=false. The iOS deployment target is now 15.0 and the photo-library permission description has been added. This supersedes the temporary-preview status above. The expanded integration suite passes 67 tests.

At the user's request, event-hall creation is enabled in the simulator for interactive verification with the command below. This is a testing override, not evidence that the full deployed financial readiness matrix has passed. Normal builds retain the disabled default until verification is complete. Submissions in this simulator use the real API.

```sh
flutter run -d 6DDC165B-2C62-493B-971D-B9D2AADF97A7 --dart-define=UI_PREVIEW=false --dart-define=API_BASE_URL=https://api.aqora.sa/api/v1 --dart-define=EVENT_HALL_CREATION_READY=true
```
