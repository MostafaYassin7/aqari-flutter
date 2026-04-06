import '../../core/utils/parse_helpers.dart';

class DailyRental {
  final String id;
  final String name;
  final String city;
  final String district;
  final String category; // شقة، شاليه، استراحة، فيلا
  final List<String> imageUrls;
  final double pricePerNight;
  final double rating;
  final int reviewCount;
  final double area;
  final int bedrooms;
  final int bathrooms;
  final int livingRooms;
  final String description;

  const DailyRental({
    required this.id,
    required this.name,
    required this.city,
    required this.district,
    required this.category,
    required this.imageUrls,
    required this.pricePerNight,
    required this.rating,
    required this.reviewCount,
    required this.area,
    required this.bedrooms,
    required this.bathrooms,
    this.livingRooms = 1,
    required this.description,
  });

  // Daily rentals come from /listings?listingType=rent_short
  factory DailyRental.fromJson(Map<String, dynamic> json) {
    // Images
    final photos = json['photos'];
    List<String> imageUrls = [];
    if (photos is List && photos.isNotEmpty) {
      imageUrls = photos.map((e) => e.toString()).toList();
    }
    final cover = json['coverPhoto'];
    if (imageUrls.isEmpty && cover != null && cover.toString().isNotEmpty) {
      imageUrls = [cover.toString()];
    }
    if (imageUrls.isEmpty) imageUrls = [''];

    // Category: nested object or raw string
    final catRaw = json['category'];
    final category = catRaw is Map
        ? (catRaw['name'] ?? '').toString()
        : (catRaw ?? '').toString();

    return DailyRental(
      id: (json['id'] ?? json['objectID'] ?? '').toString(),
      name: (json['title'] ?? json['name'] ?? '').toString(),
      city: (json['city'] ?? '').toString(),
      district: (json['district'] ?? '').toString(),
      category: category,
      imageUrls: imageUrls,
      pricePerNight: ParseHelpers.toDouble(json['totalPrice']),
      rating: ParseHelpers.toDouble(json['averageRating'] ?? json['rating']),
      reviewCount: ParseHelpers.toInt(
        json['ratingsCount'] ?? json['reviewCount'],
      ),
      area: ParseHelpers.toDouble(json['area']),
      bedrooms: ParseHelpers.toInt(json['bedrooms']),
      bathrooms: ParseHelpers.toInt(json['bathrooms']),
      livingRooms: ParseHelpers.toInt(json['livingRooms']),
      description: (json['description'] ?? '').toString(),
    );
  }
}
