import 'package:flutter/material.dart';

import '../../../shared/models/rental.dart';

// ── Host model ────────────────────────────────────────────────────────────────

class RentalHost {
  final String name;
  final String photoUrl;
  final bool isVerified;
  final String responseRate;
  final String responseTime;
  final String memberSince;
  final double rating;
  final int reviewCount;

  const RentalHost({
    required this.name,
    required this.photoUrl,
    required this.isVerified,
    required this.responseRate,
    required this.responseTime,
    required this.memberSince,
    required this.rating,
    required this.reviewCount,
  });
}

const _hosts = [
  RentalHost(
    name: 'أحمد المطيري',
    photoUrl: 'https://picsum.photos/seed/host1/100/100',
    isVerified: true,
    responseRate: '98٪',
    responseTime: 'في غضون ساعة',
    memberSince: 'عضو منذ 2020',
    rating: 4.9,
    reviewCount: 312,
  ),
  RentalHost(
    name: 'منيرة الزهراني',
    photoUrl: 'https://picsum.photos/seed/host2/100/100',
    isVerified: true,
    responseRate: '100٪',
    responseTime: 'في غضون ساعتين',
    memberSince: 'عضو منذ 2019',
    rating: 5.0,
    reviewCount: 87,
  ),
  RentalHost(
    name: 'فيصل العتيبي',
    photoUrl: 'https://picsum.photos/seed/host3/100/100',
    isVerified: false,
    responseRate: '92٪',
    responseTime: 'في غضون بضع ساعات',
    memberSince: 'عضو منذ 2022',
    rating: 4.7,
    reviewCount: 54,
  ),
  RentalHost(
    name: 'ريم السهلي',
    photoUrl: 'https://picsum.photos/seed/host4/100/100',
    isVerified: true,
    responseRate: '99٪',
    responseTime: 'في غضون ساعة',
    memberSince: 'عضو منذ 2021',
    rating: 4.8,
    reviewCount: 173,
  ),
];

RentalHost getHostForRental(String rentalId) {
  final n = int.tryParse(rentalId.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
  return _hosts[n % _hosts.length];
}

// ── Amenity model ─────────────────────────────────────────────────────────────

class RentalAmenity {
  final String label;
  final IconData icon;
  const RentalAmenity({required this.label, required this.icon});
}

List<RentalAmenity> getAmenitiesForRental(DailyRental rental) {
  final base = <RentalAmenity>[
    const RentalAmenity(label: 'واي فاي', icon: Icons.wifi_rounded),
    const RentalAmenity(label: 'تكييف', icon: Icons.ac_unit_rounded),
    const RentalAmenity(label: 'مطبخ راكب', icon: Icons.kitchen_rounded),
    const RentalAmenity(label: 'غسالة', icon: Icons.local_laundry_service_rounded),
    const RentalAmenity(label: 'تلفاز', icon: Icons.tv_rounded),
    const RentalAmenity(label: 'موقف سيارة', icon: Icons.local_parking_rounded),
  ];

  switch (rental.category) {
    case 'فيلا':
      return [
        ...base,
        const RentalAmenity(label: 'مسبح خاص', icon: Icons.pool_rounded),
        const RentalAmenity(label: 'حديقة', icon: Icons.yard_rounded),
        const RentalAmenity(label: 'شواء', icon: Icons.outdoor_grill_rounded),
        const RentalAmenity(label: 'أمن 24 ساعة', icon: Icons.security_rounded),
      ];
    case 'شاليه':
      return [
        ...base,
        const RentalAmenity(label: 'شواء خارجي', icon: Icons.outdoor_grill_rounded),
        const RentalAmenity(label: 'حديقة', icon: Icons.yard_rounded),
        const RentalAmenity(label: 'ملعب أطفال', icon: Icons.sports_soccer_rounded),
      ];
    case 'استراحة':
      return [
        ...base,
        const RentalAmenity(label: 'مسبح', icon: Icons.pool_rounded),
        const RentalAmenity(label: 'شواء', icon: Icons.outdoor_grill_rounded),
        const RentalAmenity(label: 'ملعب', icon: Icons.sports_rounded),
        const RentalAmenity(label: 'حديقة', icon: Icons.yard_rounded),
      ];
    default: // شقة
      return [
        ...base,
        const RentalAmenity(label: 'مصعد', icon: Icons.elevator_rounded),
        const RentalAmenity(label: 'أمن 24 ساعة', icon: Icons.security_rounded),
      ];
  }
}

// ── Review model ──────────────────────────────────────────────────────────────

class RentalReview {
  final String reviewerName;
  final String reviewerPhoto;
  final double rating;
  final String date;
  final String comment;

  const RentalReview({
    required this.reviewerName,
    required this.reviewerPhoto,
    required this.rating,
    required this.date,
    required this.comment,
  });
}

// Rating breakdown (counts out of 100 reviews for bar widths)
class RatingBreakdown {
  final double five, four, three, two, one; // 0.0–1.0 fractions
  const RatingBreakdown({
    required this.five,
    required this.four,
    required this.three,
    required this.two,
    required this.one,
  });
}

const _reviewPool = [
  RentalReview(
    reviewerName: 'سلطان الدوسري',
    reviewerPhoto: 'https://picsum.photos/seed/rev1/100/100',
    rating: 5.0,
    date: 'مارس 2025',
    comment: 'إقامة رائعة جداً! المكان نظيف ومجهز بالكامل. المضيف كان متجاوباً وسريع الرد. سأعود بالتأكيد.',
  ),
  RentalReview(
    reviewerName: 'نوف الحربي',
    reviewerPhoto: 'https://picsum.photos/seed/rev2/100/100',
    rating: 5.0,
    date: 'فبراير 2025',
    comment: 'تجربة لا تُنسى! الموقع ممتاز والمرافق نظيفة. ننصح به بشدة للعائلات.',
  ),
  RentalReview(
    reviewerName: 'عمر البقمي',
    reviewerPhoto: 'https://picsum.photos/seed/rev3/100/100',
    rating: 4.0,
    date: 'يناير 2025',
    comment: 'إقامة جيدة ومريحة. الموقع قريب من الخدمات. يستحق السعر.',
  ),
  RentalReview(
    reviewerName: 'هيفاء الشمري',
    reviewerPhoto: 'https://picsum.photos/seed/rev4/100/100',
    rating: 5.0,
    date: 'ديسمبر 2024',
    comment: 'أفضل إقامة في إجازتنا! المكان فاق توقعاتنا. المضيف ودود ومتعاون.',
  ),
  RentalReview(
    reviewerName: 'محمد القرني',
    reviewerPhoto: 'https://picsum.photos/seed/rev5/100/100',
    rating: 4.0,
    date: 'نوفمبر 2024',
    comment: 'مكان جميل وهادئ. التكييف والواي فاي ممتازان. سيتم الحجز مجدداً.',
  ),
];

List<RentalReview> getReviewsForRental(String rentalId) {
  final n = int.tryParse(rentalId.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
  final start = n % _reviewPool.length;
  return List.generate(3, (i) => _reviewPool[(start + i) % _reviewPool.length]);
}

RatingBreakdown getBreakdownForRating(double rating) {
  if (rating >= 4.9) {
    return const RatingBreakdown(five: 0.85, four: 0.10, three: 0.03, two: 0.01, one: 0.01);
  } else if (rating >= 4.7) {
    return const RatingBreakdown(five: 0.75, four: 0.18, three: 0.05, two: 0.01, one: 0.01);
  } else {
    return const RatingBreakdown(five: 0.60, four: 0.25, three: 0.10, two: 0.03, one: 0.02);
  }
}
