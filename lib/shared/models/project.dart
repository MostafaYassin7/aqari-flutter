import 'package:flutter/foundation.dart';

import '../../core/utils/parse_helpers.dart';

enum ProjectAvailability { ready, offPlan }

extension ProjectAvailabilityLabel on ProjectAvailability {
  String get label =>
      this == ProjectAvailability.ready ? 'جاهز' : 'على الخارطة';
}

@immutable
class ProjectUnit {
  final String id;
  final String unitType;
  final double area;
  final double? price;
  final double? priceFrom;
  final double? priceTo;
  final int floor;
  final String availability;

  const ProjectUnit({
    required this.id,
    required this.unitType,
    required this.area,
    this.price,
    this.priceFrom,
    this.priceTo,
    required this.floor,
    required this.availability,
  });

  factory ProjectUnit.fromJson(Map<String, dynamic> json) {
    return ProjectUnit(
      id: (json['id'] ?? '').toString(),
      unitType: (json['unitType'] ?? '').toString(),
      area: ParseHelpers.toDouble(json['area']),
      price: json['price'] != null
          ? ParseHelpers.toDouble(json['price'])
          : null,
      priceFrom: json['priceFrom'] != null
          ? ParseHelpers.toDouble(json['priceFrom'])
          : null,
      priceTo: json['priceTo'] != null
          ? ParseHelpers.toDouble(json['priceTo'])
          : null,
      floor: ParseHelpers.toInt(json['floor']),
      availability: (json['availability'] ?? '').toString(),
    );
  }

  String get displayPrice {
    if (price != null && price! > 0) return _fmtNum(price!.round());
    if (priceFrom != null && priceTo != null) {
      return '${_fmtNum(priceFrom!.round())} – ${_fmtNum(priceTo!.round())}';
    }
    if (priceFrom != null) return 'من ${_fmtNum(priceFrom!.round())}';
    return '—';
  }

  String _fmtNum(int n) => n.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]},',
  );
}

class Project {
  final String id;
  final String name;
  final String developerName;
  final String city;
  final String district;
  final String projectType;
  final List<String> imageUrls;
  final double startingPrice;
  final double? priceTo;
  final String description;
  final String address;
  final double lat;
  final double lng;
  final int totalUnits;
  final String? deliveryDate;
  final ProjectAvailability availability;
  final List<ProjectUnit> units;

  const Project({
    required this.id,
    required this.name,
    required this.developerName,
    required this.city,
    this.district = '',
    required this.projectType,
    required this.imageUrls,
    required this.startingPrice,
    this.priceTo,
    required this.description,
    this.address = '',
    this.lat = 0.0,
    this.lng = 0.0,
    this.totalUnits = 0,
    this.deliveryDate,
    required this.availability,
    this.units = const [],
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    // Images: prefer __media__ array, then photos, then coverPhoto
    List<String> imageUrls = [];
    final media = json['__media__'];
    if (media is List && media.isNotEmpty) {
      imageUrls = media
          .whereType<Map>()
          .map((m) => (m['url'] ?? '').toString())
          .where((u) => u.isNotEmpty)
          .toList();
    }
    if (imageUrls.isEmpty) {
      final photos = json['photos'];
      if (photos is List && photos.isNotEmpty) {
        imageUrls = photos.map((e) => e.toString()).toList();
      }
    }
    final cover = json['coverPhoto'];
    if (imageUrls.isEmpty && cover != null && cover.toString().isNotEmpty) {
      imageUrls = [cover.toString()];
    }
    if (imageUrls.isEmpty) imageUrls = [''];

    // Developer name: may be a nested object or flat field
    String developerName = '';
    final dev = json['developer'];
    if (dev is Map) {
      developerName = (dev['name'] ?? dev['companyName'] ?? '').toString();
    } else {
      developerName = (json['developerName'] ?? json['developer_name'] ?? '')
          .toString();
    }

    // Availability from status field
    final status = (json['status'] ?? '').toString();
    final availability = status == 'ready'
        ? ProjectAvailability.ready
        : ProjectAvailability.offPlan;

    // Parse units
    List<ProjectUnit> units = [];
    final rawUnits = json['__units__'];
    if (rawUnits is List) {
      units = rawUnits
          .whereType<Map>()
          .map((u) => ProjectUnit.fromJson(Map<String, dynamic>.from(u)))
          .toList();
    }

    return Project(
      id: (json['id'] ?? '').toString(),
      name: (json['title'] ?? json['name'] ?? '').toString(),
      developerName: developerName,
      city: (json['city'] ?? '').toString(),
      district: (json['district'] ?? '').toString(),
      projectType: (json['projectType'] ?? json['type'] ?? '').toString(),
      imageUrls: imageUrls,
      startingPrice: ParseHelpers.toDouble(
        json['priceFrom'] ?? json['startingPrice'],
      ),
      priceTo: json['priceTo'] != null
          ? ParseHelpers.toDouble(json['priceTo'])
          : null,
      description: (json['description'] ?? '').toString(),
      address: (json['address'] ?? '').toString(),
      lat: ParseHelpers.toDouble(json['latitude'] ?? json['lat']),
      lng: ParseHelpers.toDouble(json['longitude'] ?? json['lng']),
      totalUnits: ParseHelpers.toInt(json['totalUnits']),
      deliveryDate: json['deliveryDate']?.toString(),
      availability: availability,
      units: units,
    );
  }
}
