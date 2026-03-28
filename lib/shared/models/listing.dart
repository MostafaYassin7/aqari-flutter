import 'package:flutter/foundation.dart';

import '../../core/utils/parse_helpers.dart';

@immutable
class Listing {
  final String id;
  final String title;
  final String city;
  final String district;
  final String category;
  final String propertyType;
  final double price;
  final int area;
  final int bedrooms;
  final int bathrooms;
  final int livingRooms;
  final String description;
  final List<String> imageUrls;
  final double lat;
  final double lng;
  final String listingType;
  final String status;
  final String ownerName;

  const Listing({
    required this.id,
    required this.title,
    required this.city,
    required this.district,
    required this.category,
    this.propertyType = '',
    required this.price,
    required this.area,
    required this.bedrooms,
    required this.bathrooms,
    required this.livingRooms,
    required this.description,
    required this.imageUrls,
    this.lat = 0.0,
    this.lng = 0.0,
    this.listingType = '',
    this.status = '',
    this.ownerName = '',
  });

  factory Listing.fromJson(Map<String, dynamic> json) {
    // Algolia uses objectID, PostgreSQL uses id
    final id = (json['id'] ?? json['objectID'] ?? '').toString();

    // Category: nested object {id, name}, categoryName, or raw string
    final catRaw = json['category'] ?? json['categoryName'];
    final category = catRaw is Map
        ? (catRaw['name'] ?? '').toString()
        : (catRaw ?? '').toString();

    // Coordinates: Algolia → _geoloc, PostgreSQL → latitude/longitude
    double lat = 0.0, lng = 0.0;
    if (json['_geoloc'] != null) {
      final geo = json['_geoloc'] as Map<String, dynamic>;
      lat = ParseHelpers.toDouble(geo['lat']);
      lng = ParseHelpers.toDouble(geo['lng']);
    } else {
      lat = ParseHelpers.toDouble(json['latitude']);
      lng = ParseHelpers.toDouble(json['longitude']);
    }

    // Images: prefer photos array, fall back to coverPhoto
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

    return Listing(
      id: id,
      title: (json['title'] ?? '').toString(),
      city: (json['city'] ?? '').toString(),
      district: (json['district'] ?? '').toString(),
      category: category,
      propertyType: (json['propertyType'] ?? '').toString(),
      price: ParseHelpers.toDouble(json['totalPrice']),
      area: ParseHelpers.toDouble(json['area']).toInt(),
      bedrooms: ParseHelpers.toInt(json['bedrooms']),
      bathrooms: ParseHelpers.toInt(json['bathrooms']),
      livingRooms: ParseHelpers.toInt(json['livingRooms']),
      description: (json['description'] ?? '').toString(),
      imageUrls: imageUrls,
      lat: lat,
      lng: lng,
      listingType: (json['listingType'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      ownerName: (json['ownerName'] ?? '').toString(),
    );
  }
}

/// Formats a price number to Arabic real estate style.
String formatPrice(double price) {
  if (price >= 1000000) {
    final m = price / 1000000;
    final str = m == m.truncateToDouble()
        ? m.toInt().toString()
        : m.toStringAsFixed(1);
    return '$str مليون ريال';
  }
  final formatted = price.toInt().toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]},',
  );
  return '$formatted ريال';
}
