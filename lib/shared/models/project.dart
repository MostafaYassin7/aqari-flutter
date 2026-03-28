import '../../core/utils/parse_helpers.dart';

enum ProjectAvailability { ready, offPlan }

extension ProjectAvailabilityLabel on ProjectAvailability {
  String get label =>
      this == ProjectAvailability.ready ? 'جاهز' : 'على الخارطة';
}

class Project {
  final String id;
  final String name;
  final String developerName;
  final String city;
  final String projectType;
  final List<String> imageUrls;
  final double startingPrice;
  final String description;
  final ProjectAvailability availability;

  const Project({
    required this.id,
    required this.name,
    required this.developerName,
    required this.city,
    required this.projectType,
    required this.imageUrls,
    required this.startingPrice,
    required this.description,
    required this.availability,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
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

    return Project(
      id: (json['id'] ?? '').toString(),
      name: (json['title'] ?? json['name'] ?? '').toString(),
      developerName: developerName,
      city: (json['city'] ?? '').toString(),
      projectType: (json['projectType'] ?? json['type'] ?? '').toString(),
      imageUrls: imageUrls,
      startingPrice: ParseHelpers.toDouble(
        json['priceFrom'] ?? json['startingPrice'],
      ),
      description: (json['description'] ?? '').toString(),
      availability: availability,
    );
  }
}
