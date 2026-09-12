import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aqar_app/features/add_listing/presentation/providers/add_listing_provider.dart';
import 'package:aqar_app/features/add_listing/domain/listing_payload.dart';
import 'package:aqar_app/shared/domain/property_rules.dart';
import 'package:aqar_app/core/router/auth_return.dart';

void main() {
  for (final type in [
    ...PropertyRules.residential,
    ...PropertyRules.commercial,
    'land',
    'event_hall',
    'other',
  ]) {
    for (final listingType in ['sale', 'rent_long', 'rent_short']) {
      test(
        'payload whitelist $type/$listingType with injected hidden fields',
        () {
          final s = AddListingState(
            propertyType: type,
            listingType: listingType,
            bedrooms: 3,
            isFurnished: true,
            streetWidth: '20',
            price: '1200',
            area: '100',
            draft: {
              'categoryId': 'server-category',
              'title': 'عنوان',
              'capacity': '8',
              'halfDay': '500',
              'minNights': '2',
              'checkIn': '14:00',
              'checkOut': '12:00',
              'catering': 'true',
              'licenseId': 'server-license',
            },
          );
          final payload = listingPayload(s);
          expect(payload['categoryId'], 'server-category');
          expect(payload['totalPrice'], 1200);
          for (final key in [
            'bedrooms',
            'isFurnished',
            'streetWidth',
            'maxGuests',
            'pricePerHalfDay',
            'includedServices',
            'minNights',
            'checkInTime',
            'checkOutTime',
          ]) {
            expect(
              payload.containsKey(key),
              s.rules.allowedFields.contains(key),
              reason: key,
            );
          }
          if (type == 'event_hall') {
            expect(payload.keys, isNot(contains('minNights')));
          }
        },
      );
    }
  }
  test(
    'role change invalidates license; ordinary title change preserves it',
    () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final n = c.read(addListingProvider.notifier);
      n.field('licenseId', 'license');
      n.field('title', 'new');
      expect(c.read(addListingProvider).value('licenseId'), 'license');
      n.setRole('agent');
      expect(c.read(addListingProvider).value('licenseId'), '');
      n.field('licenseId', 'license');
      n.field('phone', '123');
      expect(c.read(addListingProvider).value('licenseId'), '');
    },
  );
  test(
    'server category ID changes with selection and never leaks across categories',
    () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final n = c.read(addListingProvider.notifier);
      n.selectType('apartment', 'sale', 'شقة', categoryId: 'server-id');
      expect(c.read(addListingProvider).categoryId, 'server-id');
      n.selectType('land', 'sale', 'أرض');
      expect(c.read(addListingProvider).categoryId, isNot('server-id'));
    },
  );
  test('license whitelists identity and role-specific fields', () {
    for (final kind in ['national', 'commercial', 'unified']) {
      final payload = listingLicensePayload(
        AddListingState(
          role: 'owner',
          draft: {
            'idType': kind,
            'ownerId': '123',
            'birth': '1990-01-01',
            'agentId': 'stale',
            'phone': '555',
          },
        ),
      );
      expect(payload.containsKey('agentNationalIdNumber'), false);
      expect(payload.containsKey('propertyOwnerBirthDate'), kind == 'national');
      expect(payload['propertyOwnerPhone'], '555');
    }
    expect(
      listingLicensePayload(
        const AddListingState(
          role: 'host',
          draft: {'tourism': 'T1', 'ownerId': 'stale'},
        ),
      ),
      {'tourismLicenseNumber': 'T1'},
    );
  });
  test('auth return keeps local route and query; blocks external paths', () {
    const target = '/add-listing?preset=event_hall';
    expect(
      Uri.parse(authRoute('/login', target)).queryParameters['returnTo'],
      target,
    );
    for (final path in [
      'https://evil.test',
      '//evil.test',
      '/%2f%2fevil.test',
      '/\\evil.test',
    ]) {
      expect(safeReturnTo(path), isNull);
    }
  });
}
