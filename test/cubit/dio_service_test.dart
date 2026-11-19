import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_mobile/helper/dio_service.dart';
import 'package:hris_mobile/helper/push_routing.dart';

import '../helpers/test_env.dart';

void main() {
  setUp(() => setUpTestEnv());

  test('getInstance mengembalikan instance yang sama & baseUrl dari .env', () async {
    final a = await DioService.getInstance();
    final b = await DioService.getInstance();
    expect(identical(a, b), isTrue);
    expect(a.options.baseUrl, 'http://fake.invalid');
  });

  test('token disisipkan sebagai Bearer', () async {
    final api = await installFakeApi((_) => const FakeReply(200, {'ok': true}));
    final dio = await DioService.getInstance();
    await dio.get('/me');
    expect(api.requests.single.headers['Authorization'], 'Bearer test-token');
  });

  test('tanpa token → tidak ada header Authorization', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final api = await installFakeApi((_) => const FakeReply(200, {}));
    await (await DioService.getInstance()).get('/me');
    expect(api.requests.single.headers.containsKey('Authorization'), isFalse);
  });

  test('401 menghapus sesi dan memanggil onUnauthorized, tanpa melempar', () async {
    var called = 0;
    DioService.onUnauthorized = () => called++;
    addTearDown(() => DioService.onUnauthorized = null);
    await installFakeApi((_) => const FakeReply(401, {'message': 'Unauthorized'}));
    final res = await (await DioService.getInstance()).get('/me');
    expect(res.statusCode, 401);
    expect(called, 1);
    expect(await const FlutterSecureStorage().read(key: 'token'), isNull);
  });

  test('4xx tidak melempar (validateStatus < 500), 5xx melempar', () async {
    await installFakeApi((o) => FakeReply(o.path == '/a' ? 422 : 500, {'message': 'x'}));
    final dio = await DioService.getInstance();
    expect((await dio.get('/a')).statusCode, 422);
    await expectLater(dio.get('/b'), throwsA(anything));
  });

  group('PushRouting (bagian publik yang bisa diuji)', () {
    test('consumeIfReady tanpa tujuan tertunda tidak melakukan apa-apa', () async {
      PushRouting.clear();
      await PushRouting.consumeIfReady();
    });
    // _targetOf privat dan hanya terjangkau lewat OneSignal click listener;
    // tidak bisa diuji tanpa mengubah lib/ (lihat saran di laporan).
  });
}
