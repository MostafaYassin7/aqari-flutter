import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aqar_app/core/network/api_client.dart';
import 'package:aqar_app/features/add_listing/data/add_listing_repository.dart';
import 'package:aqar_app/features/add_listing/domain/listing_payload.dart';
import 'package:aqar_app/features/add_listing/presentation/providers/add_listing_provider.dart';
import 'package:aqar_app/features/home/data/listings_repository.dart';
import 'package:aqar_app/shared/domain/property_rules.dart';
import 'package:aqar_app/shared/models/listing_category.dart';

// Creates private drafts only, then deletes exactly the IDs created by this run.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'live category-specific Flutter payloads persist as private drafts',
    () async {
      final previousHttpOverrides = HttpOverrides.current;
      HttpOverrides.global = null;
      addTearDown(() => HttpOverrides.global = previousHttpOverrides);
      final directory = Platform.environment['AQARI_TEST_AUTH_DIR']!;
      final auth = jsonDecode(
        await File('$directory/second.json').readAsString(),
      );
      SharedPreferences.setMockInitialValues({
        'aqar_auth_token': auth['token'],
      });
      final dio = createApiClient();
      final run = DateTime.now().microsecondsSinceEpoch.toString();
      final createdIds = <String>[];
      final ledger = File('$directory/draft-check-$run.json');
      final repo = AddListingRepository(dio);
      try {
        final categories = (await ListingsRepository().getListingCategories())
            .where((c) => c.isActive)
            .toList();
        final cases = <String, bool Function(ListingCategory)>{
          'residential': (c) =>
              PropertyRules.residential.contains(c.propertyType) &&
              c.listingType != 'rent_short',
          'commercial': (c) =>
              PropertyRules.commercial.contains(c.propertyType) &&
              c.listingType != 'rent_short',
          'land': (c) => c.propertyType == 'land',
          'daily': (c) =>
              c.propertyType != 'event_hall' && c.listingType == 'rent_short',
          'hall': (c) =>
              c.propertyType == 'event_hall' && c.listingType == 'rent_short',
        };
        for (final entry in cases.entries) {
          final category = categories.where(entry.value).first;
          final state = AddListingState(
            propertyType: category.propertyType,
            listingType: category.listingType,
            role: 'owner',
            price: '100',
            area: '200',
            lat: 24.7136,
            lng: 46.6753,
            isResidential: entry.key != 'commercial',
            draft: {
              'categoryId': category.id,
              'title': 'Flutter integration draft $run ${entry.key}',
              'city': 'الرياض',
              'skipLicense': 'true',
              'capacity': '4',
              'minNights': '2',
              'checkIn': '14:00',
              'checkOut': '12:00',
              'halfDay': '0',
              'catering': 'true',
            },
          );
          final created = await repo.create(listingPayload(state));
          createdIds.add(created['id'] as String);
          await ledger.writeAsString(
            jsonEncode({'ids': createdIds, 'cleanupComplete': false}),
          );
          expect(created['status'], 'draft');
          expect(created['categoryId'], category.id);
          if (entry.key == 'hall') {
            expect(created['maxGuests'], 4);
            expect(double.parse('${created['pricePerHalfDay']}'), 0);
            expect(created['includedServices'], contains('catering'));
            expect(created['minNights'], isNull);
          } else if (entry.key == 'daily') {
            expect(created['minNights'], 2);
            expect(created['checkInTime'], '14:00');
            expect(created['pricePerHalfDay'], isNull);
          } else {
            expect(created['maxGuests'], isNull);
            expect(created['includedServices'], isNull);
          }
        }
      } finally {
        try {
          for (final id in createdIds) {
            await dio.delete('/listings/${Uri.encodeComponent(id)}');
          }
          await ledger.writeAsString(
            jsonEncode({'ids': createdIds, 'cleanupComplete': true}),
          );
        } finally {
          dio.close(force: true);
        }
      }
    },
    skip: Platform.environment['AQARI_LIVE_DRAFT_CHECKS'] != 'true',
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
