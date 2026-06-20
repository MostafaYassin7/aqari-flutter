import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';

class PropertyAdvertisementLicenseRepository {
  // Called at step 0b for مالك/وكيل — creates permanent license record for admin review.
  // Returns the id of the created license; Flutter passes it when creating the listing.
  Future<String> createOwnerAgentLicense(Map<String, dynamic> data) async {
    final res = await apiClient.post(
      ApiEndpoints.propertyAdvertisementLicenses,
      data: data,
    );
    return res.data['id'] as String;
  }

  // Called at step 0c for مسوق — validates with REGA via backend.
  // Returns { isValid: bool, licenseId?: string, message?: string }
  Future<Map<String, dynamic>> validateBrokerLicense({
    required String adLicenseNumber,
    required String ownerIdType,
    required String ownerIdNumber,
  }) async {
    final res = await apiClient.post(
      '${ApiEndpoints.propertyAdvertisementLicenses}/validate-broker',
      data: {
        'adLicenseNumber': adLicenseNumber,
        'ownerIdType': ownerIdType,
        'ownerIdNumber': ownerIdNumber,
      },
    );
    return res.data as Map<String, dynamic>;
  }

  // Called at step 0d for مضيف — validates with Ministry of Tourism via backend.
  // Returns { isValid: bool, licenseId?: string, message?: string }
  Future<Map<String, dynamic>> validateHostLicense({
    required String tourismLicenseNumber,
  }) async {
    final res = await apiClient.post(
      '${ApiEndpoints.propertyAdvertisementLicenses}/validate-host',
      data: {'tourismLicenseNumber': tourismLicenseNumber},
    );
    return res.data as Map<String, dynamic>;
  }
}
