import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';

// ── Repository ────────────────────────────────────────────────────────────────

class PropertyAdvertisementLicenseRepository {
  /// createLicense — إنشاء سجل ترخيص إعلان عقاري
  ///
  /// Called from step7_review when the user taps "نشر الإعلان"
  /// and advertiserType is owner, agent, or broker (not host).
  ///
  /// The listing has NOT been created yet at this point.
  /// The returned licenseId is stored in provider state and passed
  /// to POST /listings in the next step so backend can link them.
  ///
  /// After creation, the backend notifies admin users that a new
  /// license is pending their review.
  ///
  /// Null fields should be stripped before calling this method
  /// using ParseHelpers.buildBody() — see add_listing_screen.dart
  ///
  /// [data] - cleaned license body (no null values).
  /// Required keys depend on advertiserType:
  ///   owner/agent: advertiserType, ownershipDocumentType, ownershipDocumentNumber,
  ///                propertyOwnerIdType, propertyOwnerIdNumber, + conditional fields
  ///   broker:      advertiserType, falLicenseNumber, brokerageContractNumber,
  ///                propertyOwnerIdType, propertyOwnerIdNumber
  ///
  /// Returns the id of the created license record.
  /// Flutter stores this id then passes it when creating the listing.
  Future<String> createLicense(Map<String, dynamic> data) async {
    // POST /property-advertisement-licenses
    // Response is already unwrapped by Dio interceptor
    // Returns the full license object; we extract the id field
    final res = await apiClient.post(
      ApiEndpoints.propertyAdvertisementLicenses,
      data: data,
    );
    return res.data['id'] as String;
  }
}
