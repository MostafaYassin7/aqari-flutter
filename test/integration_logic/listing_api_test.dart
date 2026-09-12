import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:aqar_app/core/network/api_client.dart';
import 'package:aqar_app/core/network/api_failure.dart';
import 'package:aqar_app/features/add_listing/data/add_listing_repository.dart';
import 'package:aqar_app/features/add_listing/presentation/providers/add_listing_provider.dart';

class RecordingAdapter implements HttpClientAdapter {
  late RequestOptions request;
  Object body = {
    'success': true,
    'data': {
      'urls': ['https://example.com/photo.png'],
    },
  };
  int status = 200;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    request = options;
    if (requestStream != null) await requestStream.drain<void>();
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(
    () => SharedPreferences.setMockInitialValues({
      'aqar_auth_token': 'test-token',
    }),
  );
  test(
    'authenticated multipart uses backend files field, image MIME and query folder',
    () async {
      final adapter = RecordingAdapter();
      final dio = createApiClient()..httpClientAdapter = adapter;
      final repo = AddListingRepository(dio);
      final result = await repo.upload(
        XFile.fromData(
          Uint8List.fromList([137, 80, 78, 71, 13, 10, 26, 10]),
          name: 'photo.png',
        ),
        (_) {},
      );
      expect(result, 'https://example.com/photo.png');
      expect(adapter.request.path, '/media/upload');
      expect(adapter.request.headers['Authorization'], 'Bearer test-token');
      expect(adapter.request.queryParameters, {'folder': 'listings'});
      final data = adapter.request.data as FormData;
      expect(data.files.single.key, 'files');
      expect(data.files.single.value.contentType.toString(), 'image/png');
    },
  );
  test(
    'real Dio interceptor preserves validation on 400 and success:false envelopes',
    () async {
      final adapter = RecordingAdapter();
      final dio = createApiClient()..httpClientAdapter = adapter;
      for (final status in [400, 200]) {
        adapter.status = status;
        adapter.body = {
          'success': false,
          'message': [
            'city should not be empty',
            'minNights must not be less than 1',
          ],
        };
        try {
          await dio.post('/listings');
          fail('expected rejection');
        } on DioException catch (e) {
          expect(e.error, isA<ApiFailure>());
          expect(
            (e.error as ApiFailure).fieldErrors.keys,
            containsAll(['city', 'minNights']),
          );
          expect(e.message, contains('city should not be empty'));
        }
      }
    },
  );
  test(
    'license endpoints and response IDs match owner, broker and host contracts',
    () async {
      final adapter = RecordingAdapter();
      final repo = AddListingRepository(
        createApiClient()..httpClientAdapter = adapter,
      );
      for (final role in ['owner', 'agent', 'broker', 'host']) {
        final external = role == 'host' || role == 'broker';
        adapter.body = {
          'success': true,
          'data': {
            if (external) 'isValid': true,
            external ? 'licenseId' : 'id': 'license-id',
          },
        };
        expect(
          await repo.prepareLicense(AddListingState(role: role)),
          'license-id',
        );
        expect(
          adapter.request.path,
          '/property-advertisement-licenses${external ? '/validate-$role' : ''}',
        );
      }
      adapter.body = {
        'success': true,
        'data': {'isValid': false, 'message': 'رخصة غير صالحة'},
      };
      expect(
        () => repo.prepareLicense(const AddListingState(role: 'host')),
        throwsA(isA<ApiFailure>()),
      );
    },
  );
}
