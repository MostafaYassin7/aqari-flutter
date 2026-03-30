import 'package:flutter/foundation.dart';

import '../../core/utils/parse_helpers.dart';

@immutable
class Listing {
  final String id;
  final String userId;
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
  final String adNumber;
  final String facade;
  final int floor;
  final int propertyAge;
  final double streetWidth;
  final bool hasWater;
  final bool hasElectricity;
  final bool hasSewage;
  final bool hasPrivateRoof;
  final bool isInVilla;
  final bool hasTwoEntrances;
  final bool hasSpecialEntrance;
  final bool isFurnished;
  final bool hasKitchen;
  final bool hasExtraUnit;
  final bool hasCarEntrance;
  final bool hasElevator;
  final bool commission;
  final double commissionPercent;
  final double pricePerMeter;
  final int viewCount;
  final int messageCount;
  final int favoriteCount;

  const Listing({
    required this.id,
    this.userId = '',
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
    this.adNumber = '',
    this.facade = '',
    this.floor = 0,
    this.propertyAge = 0,
    this.streetWidth = 0.0,
    this.hasWater = false,
    this.hasElectricity = false,
    this.hasSewage = false,
    this.hasPrivateRoof = false,
    this.isInVilla = false,
    this.hasTwoEntrances = false,
    this.hasSpecialEntrance = false,
    this.isFurnished = false,
    this.hasKitchen = false,
    this.hasExtraUnit = false,
    this.hasCarEntrance = false,
    this.hasElevator = false,
    this.commission = false,
    this.commissionPercent = 0.0,
    this.pricePerMeter = 0.0,
    this.viewCount = 0,
    this.messageCount = 0,
    this.favoriteCount = 0,
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

    // Images: prefer __media__ array, then photos, then coverPhoto
    List<String> imageUrls = [];
    final media = json['__media__'];
    if (media is List && media.isNotEmpty) {
      final sorted =
          List<Map<String, dynamic>>.from(
            media.whereType<Map>().map((e) => Map<String, dynamic>.from(e)),
          )..sort((a, b) {
            // Cover photo first, then by order
            if (a['isCover'] == true && b['isCover'] != true) return -1;
            if (b['isCover'] == true && a['isCover'] != true) return 1;
            return (a['order'] as int? ?? 0).compareTo(b['order'] as int? ?? 0);
          });
      imageUrls = sorted
          .map((e) => (e['url'] ?? '').toString())
          .where((url) => url.isNotEmpty)
          .toList();
    }
    if (imageUrls.isEmpty) {
      final photos = json['photos'];
      if (photos is List && photos.isNotEmpty) {
        imageUrls = photos.map((e) => e.toString()).toList();
      }
    }
    if (imageUrls.isEmpty) {
      final cover = json['coverPhoto'];
      if (cover != null && cover.toString().isNotEmpty) {
        imageUrls = [cover.toString()];
      }
    }
    if (imageUrls.isEmpty) imageUrls = [''];

    return Listing(
      id: id,
      userId: (json['userId'] ?? '').toString(),
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
      adNumber: (json['adNumber'] ?? '').toString(),
      facade: (json['facade'] ?? '').toString(),
      floor: ParseHelpers.toInt(json['floor']),
      propertyAge: ParseHelpers.toInt(json['propertyAge']),
      streetWidth: ParseHelpers.toDouble(json['streetWidth']),
      hasWater: json['hasWater'] == true,
      hasElectricity: json['hasElectricity'] == true,
      hasSewage: json['hasSewage'] == true,
      hasPrivateRoof: json['hasPrivateRoof'] == true,
      isInVilla: json['isInVilla'] == true,
      hasTwoEntrances: json['hasTwoEntrances'] == true,
      hasSpecialEntrance: json['hasSpecialEntrance'] == true,
      isFurnished: json['isFurnished'] == true,
      hasKitchen: json['hasKitchen'] == true,
      hasExtraUnit: json['hasExtraUnit'] == true,
      hasCarEntrance: json['hasCarEntrance'] == true,
      hasElevator: json['hasElevator'] == true,
      commission: json['commission'] == true,
      commissionPercent: ParseHelpers.toDouble(json['commissionPercent']),
      pricePerMeter: ParseHelpers.toDouble(json['pricePerMeter']),
      viewCount: ParseHelpers.toInt(
        json['viewCount'] ??
            (json['stats'] is Map ? json['stats']['viewCount'] : null),
      ),
      messageCount: ParseHelpers.toInt(
        json['messageCount'] ??
            (json['stats'] is Map ? json['stats']['messageCount'] : null),
      ),
      favoriteCount: ParseHelpers.toInt(
        json['stats'] is Map ? json['stats']['favoriteCount'] : null,
      ),
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
