class ListingCategory {
  final String id;
  final String name;
  final String nameAr;
  final String? icon;
  final String propertyType;
  final String listingType;
  final int sortOrder;
  final bool isActive;

  const ListingCategory({
    required this.id,
    required this.name,
    required this.nameAr,
    this.icon,
    required this.propertyType,
    required this.listingType,
    required this.sortOrder,
    required this.isActive,
  });

  factory ListingCategory.fromJson(Map<String, dynamic> json) {
    return ListingCategory(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      nameAr: json['nameAr'] as String? ?? '',
      icon: json['icon'] as String?,
      propertyType: json['propertyType'] as String? ?? '',
      listingType: json['listingType'] as String? ?? '',
      sortOrder: json['sortOrder'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}
