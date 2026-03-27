import 'package:flutter/material.dart';

import '../../../shared/models/listing.dart';

// ── Owner model ───────────────────────────────────────────────────────────────

class PropertyOwner {
  final String name;
  final String photoUrl;
  final double rating;
  final int reviewCount;
  final String lastActive;
  final String type; // مالك or وسيط

  const PropertyOwner({
    required this.name,
    required this.photoUrl,
    required this.rating,
    required this.reviewCount,
    required this.lastActive,
    required this.type,
  });
}

const _owners = [
  PropertyOwner(
    name: 'محمد العمري',
    photoUrl: 'https://picsum.photos/seed/owner1/100/100',
    rating: 4.9,
    reviewCount: 47,
    lastActive: 'منذ ساعتين',
    type: 'وسيط',
  ),
  PropertyOwner(
    name: 'عبدالله الغامدي',
    photoUrl: 'https://picsum.photos/seed/owner2/100/100',
    rating: 4.7,
    reviewCount: 31,
    lastActive: 'منذ 5 ساعات',
    type: 'مالك',
  ),
  PropertyOwner(
    name: 'سارة الحربي',
    photoUrl: 'https://picsum.photos/seed/owner3/100/100',
    rating: 5.0,
    reviewCount: 62,
    lastActive: 'نشط الآن',
    type: 'وسيط',
  ),
  PropertyOwner(
    name: 'خالد الشمري',
    photoUrl: 'https://picsum.photos/seed/owner4/100/100',
    rating: 4.6,
    reviewCount: 19,
    lastActive: 'منذ يوم',
    type: 'مالك',
  ),
  PropertyOwner(
    name: 'نورة القحطاني',
    photoUrl: 'https://picsum.photos/seed/owner5/100/100',
    rating: 4.8,
    reviewCount: 38,
    lastActive: 'منذ 3 ساعات',
    type: 'وسيط',
  ),
];

PropertyOwner getOwnerForListing(String listingId) {
  final idx = (int.tryParse(listingId) ?? 0) % _owners.length;
  return _owners[idx];
}

// ── Feature model ─────────────────────────────────────────────────────────────

class PropertyFeature {
  final String label;
  final IconData icon;
  const PropertyFeature({required this.label, required this.icon});
}

List<PropertyFeature> getFeaturesForListing(Listing listing) {
  final base = <PropertyFeature>[
    const PropertyFeature(label: 'ماء', icon: Icons.water_drop_rounded),
    const PropertyFeature(label: 'كهرباء', icon: Icons.electric_bolt_rounded),
  ];

  switch (listing.category) {
    case 'شقة':
    case 'دوبلكس':
      return [
        ...base,
        const PropertyFeature(label: 'تكييف مركزي', icon: Icons.ac_unit_rounded),
        const PropertyFeature(label: 'موقف سيارة', icon: Icons.local_parking_rounded),
        const PropertyFeature(label: 'مطبخ راكب', icon: Icons.kitchen_rounded),
        const PropertyFeature(label: 'مصعد', icon: Icons.elevator_rounded),
        const PropertyFeature(label: 'أمن 24 ساعة', icon: Icons.security_rounded),
        const PropertyFeature(label: 'إنترنت', icon: Icons.wifi_rounded),
      ];

    case 'فيلا':
      return [
        ...base,
        const PropertyFeature(label: 'تكييف مركزي', icon: Icons.ac_unit_rounded),
        const PropertyFeature(label: 'موقف سيارة', icon: Icons.local_parking_rounded),
        const PropertyFeature(label: 'مطبخ راكب', icon: Icons.kitchen_rounded),
        const PropertyFeature(label: 'حديقة', icon: Icons.yard_rounded),
        const PropertyFeature(label: 'مسبح', icon: Icons.pool_rounded),
        const PropertyFeature(label: 'مدخل مستقل', icon: Icons.door_front_door_rounded),
        const PropertyFeature(label: 'أمن 24 ساعة', icon: Icons.security_rounded),
        const PropertyFeature(label: 'غرفة خادمة', icon: Icons.bedroom_child_rounded),
      ];

    case 'استراحة':
      return [
        ...base,
        const PropertyFeature(label: 'تكييف', icon: Icons.ac_unit_rounded),
        const PropertyFeature(label: 'مسبح', icon: Icons.pool_rounded),
        const PropertyFeature(label: 'حديقة', icon: Icons.yard_rounded),
        const PropertyFeature(label: 'موقف سيارة', icon: Icons.local_parking_rounded),
        const PropertyFeature(label: 'شواء خارجي', icon: Icons.outdoor_grill_rounded),
        const PropertyFeature(label: 'ملعب أطفال', icon: Icons.sports_soccer_rounded),
      ];

    case 'تجاري':
      return [
        ...base,
        const PropertyFeature(label: 'تكييف مركزي', icon: Icons.ac_unit_rounded),
        const PropertyFeature(label: 'موقف سيارة', icon: Icons.local_parking_rounded),
        const PropertyFeature(label: 'واجهة تجارية', icon: Icons.storefront_rounded),
        const PropertyFeature(label: 'إنترنت', icon: Icons.wifi_rounded),
      ];

    case 'أرض':
    case 'عمارة':
      return [
        ...base,
        const PropertyFeature(label: 'على شارع رئيسي', icon: Icons.add_road_rounded),
        const PropertyFeature(label: 'صك نظامي', icon: Icons.verified_rounded),
        const PropertyFeature(label: 'خدمات عامة', icon: Icons.home_work_rounded),
      ];

    default:
      return base;
  }
}
