import '../../core/utils/parse_helpers.dart';
import 'listing.dart';
import '../domain/property_rules.dart';

class DailyRental {
  final Listing? source;
  final String propertyType, listingType;
  PropertyRules get rules => PropertyRules(propertyType, listingType);
  final int? maxGuests;
  final int minNights;
  final String checkInTime, checkOutTime;
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
    this.source,
    this.propertyType = 'apartment',
    this.listingType = 'rent_short',
    this.maxGuests,
    this.minNights = 1,
    this.checkInTime = '',
    this.checkOutTime = '',
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

  factory DailyRental.fromListing(Listing l) => DailyRental(
    source: l,
    propertyType: l.propertyType,
    listingType: l.listingType,
    id: l.id,
    name: l.title,
    city: l.city,
    district: l.district,
    category: l.category,
    imageUrls: l.imageUrls,
    pricePerNight: l.price,
    rating: 0,
    reviewCount: 0,
    area: l.area.toDouble(),
    bedrooms: l.bedrooms,
    bathrooms: l.bathrooms,
    livingRooms: l.livingRooms,
    description: l.description,
    maxGuests: l.maxGuests,
    minNights: l.minNights ?? 1,
    checkInTime: l.checkInTime ?? '',
    checkOutTime: l.checkOutTime ?? '',
  );

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
      source: Listing.fromJson(json),
      propertyType: (json['propertyType'] ?? '').toString(),
      listingType: (json['listingType'] ?? '').toString(),
      maxGuests: optionalPositiveInt(json['maxGuests']),
      minNights: optionalPositiveInt(json['minNights']) ?? 1,
      checkInTime: optionalText(json['checkInTime']) ?? '',
      checkOutTime: optionalText(json['checkOutTime']) ?? '',
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
