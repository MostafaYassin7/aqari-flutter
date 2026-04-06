import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';

// ── Review model ──────────────────────────────────────────────────────────────

class UserReview {
  final String id;
  final String reviewerName;
  final String reviewerPhotoUrl;
  final double rating;
  final String text;
  final DateTime date;

  const UserReview({
    required this.id,
    required this.reviewerName,
    required this.reviewerPhotoUrl,
    required this.rating,
    required this.text,
    required this.date,
  });
}

// ── Public profile model ──────────────────────────────────────────────────────

class PublicProfile {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final String photoUrl;
  final bool isBroker;
  final bool isVerified;
  final bool hasAqarPlus;
  final String? establishmentName;
  final String? establishmentLogoUrl;
  final double rating;
  final int reviewCount;
  final DateTime memberSince;
  final DateTime lastActive;
  final String? bio;
  final int totalListings;
  final int totalDeals;
  final int responseRate; // 0–100 percentage
  final List<String> listingIds;
  final List<UserReview> reviews;
  // star level 1–5 → count of reviews at that level
  final Map<int, int> ratingBreakdown;

  const PublicProfile({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    required this.photoUrl,
    required this.isBroker,
    required this.isVerified,
    required this.hasAqarPlus,
    this.establishmentName,
    this.establishmentLogoUrl,
    required this.rating,
    required this.reviewCount,
    required this.memberSince,
    required this.lastActive,
    this.bio,
    required this.totalListings,
    required this.totalDeals,
    required this.responseRate,
    required this.listingIds,
    required this.reviews,
    required this.ratingBreakdown,
  });
}

// ── Mock data ─────────────────────────────────────────────────────────────────

final _now = DateTime.now();

final _mockProfiles = <String, PublicProfile>{
  'usr_001': PublicProfile(
    id: 'usr_001',
    name: 'محمد العتيبي',
    phone: '+966 50 123 4567',
    photoUrl: 'https://picsum.photos/seed/user001/400/400',
    isBroker: true,
    isVerified: true,
    hasAqarPlus: true,
    establishmentName: 'مكتب العتيبي للعقارات',
    establishmentLogoUrl: 'https://picsum.photos/seed/logo001/200/200',
    rating: 4.8,
    reviewCount: 47,
    memberSince: DateTime(2021, 3, 15),
    lastActive: _now.subtract(const Duration(hours: 2)),
    bio:
        'وسيط عقاري معتمد بخبرة أكثر من 10 سنوات في سوق العقارات السعودي. '
        'متخصص في بيع وتأجير الفلل والشقق الفاخرة والأراضي التجارية في الرياض وجدة والدمام. '
        'أؤمن بأن الشفافية والأمانة هما أساس كل صفقة ناجحة، وأسعى دائماً لتحقيق أفضل قيمة لعملائي.',
    totalListings: 24,
    totalDeals: 132,
    responseRate: 98,
    listingIds: ['1', '2', '3', '9', '10'],
    ratingBreakdown: {5: 33, 4: 9, 3: 3, 2: 1, 1: 1},
    reviews: [
      UserReview(
        id: 'r1',
        reviewerName: 'سلطان الحربي',
        reviewerPhotoUrl: 'https://picsum.photos/seed/rev1/200/200',
        rating: 5,
        text:
            'تجربة ممتازة، محمد محترف ودقيق جداً في تفاصيل العقار. أنهى الصفقة في وقت قياسي وبأفضل سعر. أنصح به بشدة لكل من يبحث عن وسيط موثوق.',
        date: _now.subtract(const Duration(days: 5)),
      ),
      UserReview(
        id: 'r2',
        reviewerName: 'نورة العمري',
        reviewerPhotoUrl: 'https://picsum.photos/seed/rev2/200/200',
        rating: 5,
        text:
            'الأستاذ محمد ساعدنا في إيجاد شقتنا الأولى. كان صبوراً ومتفهماً لاحتياجاتنا. شكراً جزيلاً على المتابعة المستمرة حتى بعد إتمام الصفقة.',
        date: _now.subtract(const Duration(days: 18)),
      ),
      UserReview(
        id: 'r3',
        reviewerName: 'خالد المطيري',
        reviewerPhotoUrl: 'https://picsum.photos/seed/rev3/200/200',
        rating: 4,
        text:
            'خدمة جيدة جداً وسريعة الاستجابة. الوسيط على دراية تامة بالمنطقة وأسعار السوق. سأتعامل معه مجدداً في المستقبل.',
        date: _now.subtract(const Duration(days: 35)),
      ),
      UserReview(
        id: 'r4',
        reviewerName: 'ريم الشمري',
        reviewerPhotoUrl: 'https://picsum.photos/seed/rev4/200/200',
        rating: 5,
        text:
            'وسيط محترف وأمين. ساعدنا في بيع عقار كنا نحاول بيعه منذ أشهر وأنهى الصفقة خلال أسبوعين فقط.',
        date: _now.subtract(const Duration(days: 52)),
      ),
      UserReview(
        id: 'r5',
        reviewerName: 'بدر العنزي',
        reviewerPhotoUrl: 'https://picsum.photos/seed/rev5/200/200',
        rating: 5,
        text:
            'من أفضل الوسطاء الذين تعاملت معهم. يهتم بتفاصيل كل عقار ويقدم نصائح صادقة دون مبالغة.',
        date: _now.subtract(const Duration(days: 70)),
      ),
    ],
  ),
  'usr_002': PublicProfile(
    id: 'usr_002',
    name: 'فهد الدوسري',
    phone: '+966 55 987 6543',
    photoUrl: 'https://picsum.photos/seed/user002/400/400',
    isBroker: true,
    isVerified: true,
    hasAqarPlus: false,
    establishmentName: 'الدوسري للعقارات',
    establishmentLogoUrl: 'https://picsum.photos/seed/logo002/200/200',
    rating: 4.5,
    reviewCount: 28,
    memberSince: DateTime(2022, 6, 10),
    lastActive: _now.subtract(const Duration(days: 1)),
    bio:
        'وسيط عقاري متخصص في الإيجارات السكنية بمنطقة جدة. خبرة 6 سنوات في السوق '
        'مع تركيز على خدمة العملاء وإيجاد أفضل الخيارات بأسعار منافسة.',
    totalListings: 12,
    totalDeals: 65,
    responseRate: 87,
    listingIds: ['4', '5', '7'],
    ratingBreakdown: {5: 18, 4: 7, 3: 2, 2: 1, 1: 0},
    reviews: [
      UserReview(
        id: 'r6',
        reviewerName: 'عبدالله القحطاني',
        reviewerPhotoUrl: 'https://picsum.photos/seed/rev6/200/200',
        rating: 5,
        text:
            'فهد وسيط ممتاز، سريع الاستجابة ومعرفته بالمنطقة عالية جداً. أنصح به للراغبين في الإيجار بجدة.',
        date: _now.subtract(const Duration(days: 10)),
      ),
      UserReview(
        id: 'r7',
        reviewerName: 'مها السلمي',
        reviewerPhotoUrl: 'https://picsum.photos/seed/rev7/200/200',
        rating: 4,
        text:
            'تعاملت معه لإيجاد شقة للإيجار. كان مفيداً ومتعاوناً رغم كثرة خياراتنا.',
        date: _now.subtract(const Duration(days: 40)),
      ),
      UserReview(
        id: 'r8',
        reviewerName: 'حسن الزهراني',
        reviewerPhotoUrl: 'https://picsum.photos/seed/rev8/200/200',
        rating: 4,
        text:
            'محترف ومنظم في عمله. يُحدّث العملاء باستمرار ويُسهّل إجراءات التعاقد.',
        date: _now.subtract(const Duration(days: 65)),
      ),
    ],
  ),
  'usr_003': PublicProfile(
    id: 'usr_003',
    name: 'منيرة الزهراني',
    phone: '+966 56 321 0987',
    photoUrl: 'https://picsum.photos/seed/user003/400/400',
    isBroker: false,
    isVerified: false,
    hasAqarPlus: false,
    rating: 4.2,
    reviewCount: 8,
    memberSince: DateTime(2023, 1, 20),
    lastActive: _now.subtract(const Duration(days: 3)),
    bio: null,
    totalListings: 2,
    totalDeals: 8,
    responseRate: 70,
    listingIds: ['8'],
    ratingBreakdown: {5: 4, 4: 2, 3: 1, 2: 1, 1: 0},
    reviews: [
      UserReview(
        id: 'r9',
        reviewerName: 'وليد الغامدي',
        reviewerPhotoUrl: 'https://picsum.photos/seed/rev9/200/200',
        rating: 4,
        text: 'تعامل محترم وواضح. العقار كان بالضبط كما وصفته.',
        date: _now.subtract(const Duration(days: 20)),
      ),
      UserReview(
        id: 'r10',
        reviewerName: 'أسماء الحربي',
        reviewerPhotoUrl: 'https://picsum.photos/seed/rev10/200/200',
        rating: 5,
        text: 'منيرة شخص أمين وصادق في التعامل. أنصح بالتواصل معها.',
        date: _now.subtract(const Duration(days: 55)),
      ),
    ],
  ),
};

// ── Provider ──────────────────────────────────────────────────────────────────

final publicProfileProvider = Provider.family<PublicProfile?, String>((
  ref,
  id,
) {
  final currentUser = ref.watch(authProvider.select((state) => state.user));
  if (currentUser != null && currentUser.id == id) {
    final name = currentUser.name?.trim();
    final email = currentUser.email?.trim();
    final bio = currentUser.bio?.trim();

    return PublicProfile(
      id: currentUser.id,
      name: (name == null || name.isEmpty) ? 'مستخدم عقار' : name,
      phone: currentUser.phone,
      email: (email == null || email.isEmpty) ? null : email,
      photoUrl: currentUser.profilePhoto ?? '',
      isBroker: currentUser.isOwnerOrBroker,
      isVerified: currentUser.isVerified,
      hasAqarPlus: false,
      rating: 0,
      reviewCount: 0,
      memberSince: currentUser.createdAt,
      lastActive: currentUser.lastActive ?? DateTime.now(),
      bio: (bio == null || bio.isEmpty) ? null : bio,
      totalListings: 0,
      totalDeals: 0,
      responseRate: 0,
      listingIds: const [],
      reviews: const [],
      ratingBreakdown: const {},
    );
  }

  return _mockProfiles[id];
});
