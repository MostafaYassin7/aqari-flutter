import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_failure.dart';
import '../../../core/diagnostics/safe_diagnostics.dart';
import '../presentation/providers/add_listing_provider.dart';
import '../domain/listing_payload.dart';

final addListingRepositoryProvider = Provider(
  (ref) => AddListingRepository(apiClient),
);
final listingImagePickerProvider = Provider((ref) => ImagePicker());

/// Enable only after the target environment's full readiness matrix is verified.
final eventHallCreationEnabledProvider = Provider<bool>(
  (ref) => const bool.fromEnvironment('EVENT_HALL_CREATION_READY'),
);

class AddListingRepository {
  final Dio dio;
  AddListingRepository(this.dio);
  Future<String> upload(XFile file, void Function(double) progress) async {
    var bytes = await file.readAsBytes();
    String? imageType(List<int> data) {
      if (data.length >= 3 &&
          data[0] == 255 &&
          data[1] == 216 &&
          data[2] == 255) {
        return 'jpeg';
      }
      if (data.length >= 8 &&
          data[0] == 137 &&
          data[1] == 80 &&
          data[2] == 78 &&
          data[3] == 71) {
        return 'png';
      }
      if (data.length >= 12 &&
          String.fromCharCodes(data.take(4)) == 'RIFF' &&
          String.fromCharCodes(data.sublist(8, 12)) == 'WEBP') {
        return 'webp';
      }
      return null;
    }

    var type = imageType(bytes);
    if (type == null) {
      try {
        bytes = await FlutterImageCompress.compressWithList(
          bytes,
          format: CompressFormat.jpeg,
          quality: 90,
        );
      } catch (_) {
        throw const ApiFailure(
          'تعذر قراءة الصورة. اختر صورة JPG أو PNG أو WebP.',
        );
      }
      type = imageType(bytes);
    }
    if (type == null) {
      throw const ApiFailure(
        'صيغة الصورة غير مدعومة. اختر JPG أو PNG أو WebP.',
      );
    }
    if (bytes.length > 15 * 1024 * 1024) {
      throw const ApiFailure('الصورة أكبر من ١٥ ميجابايت. اختر صورة أصغر.');
    }
    final filename =
        '${file.name.replaceFirst(RegExp(r'\.[^.]+$'), '')}.${type == 'jpeg' ? 'jpg' : type}';
    final response = await dio.post(
      '/media/upload',
      queryParameters: {'folder': 'listings'},
      data: FormData.fromMap({
        'files': [
          MultipartFile.fromBytes(
            bytes,
            filename: filename,
            contentType: DioMediaType('image', type),
          ),
        ],
      }),
      onSendProgress: (sent, total) => progress(total > 0 ? sent / total : 0),
    );
    final data = response.data;
    if (data is! Map ||
        data['urls'] is! List ||
        (data['urls'] as List).length != 1) {
      throw const ApiFailure('لم يُرجع الخادم رابط الصورة. أعد المحاولة.');
    }
    final url = '${data['urls'][0]}';
    final uri = Uri.tryParse(url);
    if (uri == null ||
        !{'http', 'https'}.contains(uri.scheme) ||
        uri.host.isEmpty) {
      throw const ApiFailure('رابط الصورة غير صالح. أعد المحاولة.');
    }
    return url;
  }

  Future<String> prepareLicense(AddListingState state) async {
    final role = state.role;
    final external = role == 'host' || role == 'broker';
    final response = await dio.post(
      '/property-advertisement-licenses${external ? '/validate-$role' : ''}',
      data: listingLicensePayload(state),
    );
    final data = response.data;
    if (data is! Map || (external && data['isValid'] != true)) {
      throw ApiFailure(
        data is Map
            ? '${data['message'] ?? 'الترخيص غير صالح. تحقق من البيانات.'}'
            : 'تعذر التحقق من الترخيص',
      );
    }
    final id = data[external ? 'licenseId' : 'id'];
    if (id is! String || id.isEmpty) {
      throw const ApiFailure('تعذر الحصول على الترخيص. حاول مجدداً.');
    }
    return id;
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> payload) async {
    final response = await dio.post('/listings', data: payload);
    if (response.data is! Map ||
        response.data['id'] is! String ||
        (response.data['id'] as String).isEmpty) {
      reportDiagnostic(DiagnosticEvent.parsingFailure);
      throw const ApiFailure(
        'تعذر تأكيد إنشاء الإعلان. تحقق من إعلاناتك قبل إعادة المحاولة.',
        {},
        null,
        true,
      );
    }
    return Map<String, dynamic>.from(response.data);
  }
}
