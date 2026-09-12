import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aqar_app/features/add_listing/presentation/providers/add_listing_provider.dart';
import 'package:aqar_app/features/add_listing/presentation/listing_ui_rules.dart';
import 'package:aqar_app/features/add_listing/presentation/data/listing_categories.dart';
import 'package:aqar_app/features/add_listing/presentation/data/listing_locations.dart';

void main() {
  for (final role in ['owner', 'agent', 'broker', 'host']) {
    for (final category in listingCategoryOptions) {
      test('$role / ${category.id}: correct step sequence', () {
        final s = AddListingState(
          role: role,
          propertyType: category.propertyType,
          listingType: category.listingType,
        );
        final daily =
            category.listingType == 'rent_short' &&
            category.propertyType != 'event_hall';
        expect(s.steps, [
          'role',
          if (role == 'owner' || role == 'agent') 'ownerInfo',
          'license',
          'category',
          'media',
          'info',
          'features',
          'details',
          if (daily) 'booking',
          'location',
          'review',
        ]);
      });
    }
  }
  for (final role in ['owner', 'agent']) {
    for (final idType in ['national', 'commercial', 'unified']) {
      for (final documentType in ['deed', 'other']) {
        test(
          '$role/$idType/$documentType: only visible identity requirements',
          () {
            final draft = {'idType': idType, 'documentType': documentType};
            final empty = AddListingState(role: role, draft: draft);
            final keys = {
              'document',
              'ownerId',
              if (idType == 'national') 'birth',
              if (role == 'agent') ...'agency agentId agentBirth'.split(' '),
            };
            expect(listingStepErrors(empty, 'license').keys.toSet(), keys);
            final complete = empty.copyWith(
              draft: {
                ...draft,
                for (final key in keys)
                  key: key.contains('irth') ? '1990-01-01' : '123',
              },
            );
            expect(listingStepErrors(complete, 'license'), isEmpty);
            expect(
              listingStepErrors(
                empty.copyWith(draft: {...draft, 'skipLicense': 'true'}),
                'license',
              ),
              isEmpty,
            );
          },
        );
      }
    }
  }
  test('broker and host cannot use the owner skip flag', () {
    expect(
      listingStepErrors(
        const AddListingState(role: 'broker', draft: {'skipLicense': 'true'}),
        'license',
      ).keys,
      containsAll(['adLicense', 'brokerOwnerId']),
    );
    expect(
      listingStepErrors(
        const AddListingState(role: 'host', draft: {'skipLicense': 'true'}),
        'license',
      ).keys,
      ['tourism'],
    );
  });
  test('photos, description, features, address and district are optional', () {
    const s = AddListingState(
      propertyType: 'apartment',
      price: '500',
      area: '100',
      draft: {'title': 'شقة', 'city': 'Riyadh', 'pin': 'selected'},
    );
    for (final step in ['media', 'info', 'features', 'details', 'location']) {
      expect(listingStepErrors(s, step), isEmpty, reason: step);
    }
  });
  test('city and deliberately selected coordinates are required', () {
    expect(
      listingStepErrors(
        const AddListingState(address: 'عنوان'),
        'location',
      ).keys,
      containsAll(['city', 'pin']),
    );
    expect(
      listingStepErrors(
        const AddListingState(
          draft: {'city': 'Riyadh', 'pin': 'selected'},
          lat: 91,
        ),
        'location',
      ).keys,
      ['pin'],
    );
  });
  test('title, positive finite price and area are required', () {
    for (final invalid in ['', '0', '-1', 'NaN', 'Infinity', 'abc']) {
      final errors = listingStepErrors(
        AddListingState(
          price: invalid,
          area: invalid,
          draft: const {'title': ' '},
        ),
        'info',
      );
      expect(errors.keys, containsAll(['title', 'price', 'area']));
    }
    expect(
      listingStepErrors(
        const AddListingState(
          price: '0.5',
          area: '0.5',
          draft: {'title': 'عنوان'},
        ),
        'info',
      ),
      isEmpty,
    );
  });
  test('commission is optional and only checked while enabled', () {
    const s = AddListingState(
      price: '500',
      area: '100',
      draft: {'title': 'عنوان'},
      hasCommission: true,
    );
    expect(listingStepErrors(s, 'info'), isEmpty);
    expect(
      listingStepErrors(s.copyWith(commissionPercent: '101'), 'info').keys,
      ['commission'],
    );
    expect(
      listingStepErrors(
        s.copyWith(commissionPercent: '101', hasCommission: false),
        'info',
      ),
      isEmpty,
    );
  });
  test('text length boundaries match the web', () {
    final s = AddListingState(
      price: '500',
      area: '100',
      draft: {'title': 'a' * 100},
      description: 'a' * 2000,
    );
    expect(listingStepErrors(s, 'info'), isEmpty);
    expect(
      listingStepErrors(
        s.copyWith(draft: {'title': 'a' * 101}, description: 'a' * 2001),
        'info',
      ).keys,
      containsAll(['title', 'description']),
    );
  });
  test(
    'daily minimum nights defaults to one; capacity and times remain optional',
    () {
      const s = AddListingState(
        propertyType: 'chalet',
        listingType: 'rent_short',
      );
      expect(s.value('minNights'), '1');
      expect(listingStepErrors(s, 'booking'), isEmpty);
      for (final value in ['', '0', '-1', '1.5', 'abc']) {
        expect(
          listingStepErrors(
            s.copyWith(draft: {'minNights': value}),
            'booking',
          ).keys,
          ['minNights'],
        );
      }
    },
  );
  test('hall optional pricing and capacity, and no daily rules', () {
    const s = AddListingState(
      propertyType: 'event_hall',
      listingType: 'rent_short',
    );
    expect(listingStepErrors(s, 'details'), isEmpty);
    expect(
      listingStepErrors(s.copyWith(draft: {'halfDay': '0'}), 'details'),
      isEmpty,
    );
    expect(
      listingStepErrors(
        s.copyWith(draft: {'capacity': '0', 'halfDay': '-1'}),
        'details',
      ).keys,
      containsAll(['capacity', 'halfDay']),
    );
    expect(
      listingStepErrors(s.copyWith(draft: {'minNights': '0'}), 'booking'),
      isEmpty,
    );
  });
  test(
    'changing category clears incompatible fields but preserves shared inputs',
    () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final n = c.read(addListingProvider.notifier);
      n.selectType('event_hall', 'rent_short', 'قاعة');
      n.field('capacity', '200');
      n.field('catering', 'true');
      n.setPrice('4000');
      n.field('title', 'عنوان');
      n.selectType('land', 'sale', 'أرض');
      final s = c.read(addListingProvider);
      expect(s.value('capacity'), '');
      expect(s.value('catering'), '');
      expect(s.price, '4000');
      expect(s.value('title'), 'عنوان');
      expect(s.features, isEmpty);
      n.selectType('event_hall', 'sale', 'قاعة');
      expect(c.read(addListingProvider).listingType, 'rent_short');
    },
  );
  test('identity switching clears stale national ID and birth date', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    final n = c.read(addListingProvider.notifier);
    n.field('ownerId', '123');
    n.field('birth', '1990-01-01');
    n.field('brokerOwnerId', '456');
    n.field('idType', 'commercial');
    final s = c.read(addListingProvider);
    expect(s.value('ownerId'), '');
    expect(s.value('birth'), '');
    expect(s.value('brokerOwnerId'), '456');
  });
  test(
    'category fixtures have unique identities and include all three journeys',
    () {
      expect(
        listingCategoryOptions.map((c) => c.id).toSet().length,
        listingCategoryOptions.length,
      );
      expect(listingCategoryOptions.map((c) => c.listingType).toSet(), {
        'sale',
        'rent_long',
        'rent_short',
      });
      expect(
        listingCategoryOptions
            .where((c) => c.propertyType == 'event_hall')
            .length,
        1,
      );
      expect(listingCities['Riyadh'], 'الرياض');
      expect(listingDistricts['Riyadh']?['Al Malaz'], 'الملز');
    },
  );
}
