import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hris_mobile/constant/theme/app_color.dart';
import 'package:hris_mobile/constant/theme/app_theme.dart';
import 'package:hris_mobile/helper/dio_service.dart';
import 'package:intl/date_symbol_data_local.dart';

/// Lingkungan uji bersama: dotenv palsu, secure storage di memori, format
/// tanggal id_ID, dan Google Fonts tanpa unduhan.
Future<void> setUpTestEnv({String? token = 'test-token'}) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  dotenv.testLoad(fileInput: 'API_BASE_URL=http://fake.invalid');
  FlutterSecureStorage.setMockInitialValues({'token': ?token});
  await initializeDateFormatting('id_ID');
  AppColor.use(Brightness.light);
}

/// Memuat Roboto dari SDK Flutter dengan nama keluarga Inter, supaya ukuran
/// teks mendekati aslinya (font bawaan flutter_test memakai glyph persegi
/// 1em yang jauh lebih lebar dari Inter, sehingga uji overflow jadi
/// terlalu pesimistis). Kalau berkas tidak ditemukan, diam-diam dilewati.
Future<void> loadApproximateFonts() async {
  final exe = File(Platform.resolvedExecutable);
  Directory? dir = exe.parent;
  File? regular;
  for (var i = 0; i < 8 && dir != null; i++) {
    final f = File('${dir.path}/material_fonts/Roboto-Regular.ttf');
    final g = File('${dir.path}/artifacts/material_fonts/Roboto-Regular.ttf');
    if (f.existsSync()) {
      regular = f;
      break;
    }
    if (g.existsSync()) {
      regular = g;
      break;
    }
    dir = dir.parent;
  }
  if (regular == null) return;
  final base = regular.parent.path;
  Future<ByteData> bytes(String name) async {
    final file = File('$base/$name');
    final data = file.existsSync() ? file.readAsBytesSync() : regular!.readAsBytesSync();
    return ByteData.view(Uint8List.fromList(data).buffer);
  }

  final families = <String, String>{
    'Inter': 'Roboto-Regular.ttf',
    'Inter_regular': 'Roboto-Regular.ttf',
    'Inter_500': 'Roboto-Medium.ttf',
    'Inter_600': 'Roboto-Medium.ttf',
    'Inter_700': 'Roboto-Bold.ttf',
    'Roboto': 'Roboto-Regular.ttf',
  };
  for (final e in families.entries) {
    final loader = FontLoader(e.key)..addFont(bytes(e.value));
    await loader.load();
  }
  final icons = File('$base/MaterialIcons-Regular.otf');
  if (icons.existsSync()) {
    final loader = FontLoader('MaterialIcons')
      ..addFont(Future.value(ByteData.view(icons.readAsBytesSync().buffer)));
    await loader.load();
  }
}

/// Balasan palsu untuk [FakeAdapter].
class FakeReply {
  final int status;
  final Object? body;
  const FakeReply(this.status, this.body);
}

typedef FakeHandler = FutureOr<FakeReply> Function(RequestOptions options);

/// Pengganti jaringan untuk Dio: tidak ada permintaan yang keluar dari proses.
class FakeAdapter implements HttpClientAdapter {
  FakeHandler handler;
  final List<RequestOptions> requests = [];

  FakeAdapter(this.handler);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final reply = await handler(options);
    final body = reply.body;
    if (body is List<int>) {
      return ResponseBody.fromBytes(body, reply.status, headers: {
        Headers.contentTypeHeader: ['application/pdf'],
      });
    }
    return ResponseBody.fromString(jsonEncode(body), reply.status, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

/// Memasang [FakeAdapter] di Dio tunggal milik [DioService].
///
/// DioService tidak menyediakan cara mengganti instance, tapi Dio yang
/// dikembalikannya bisa diganti adapternya — itu yang dipakai di sini.
Future<FakeAdapter> installFakeApi(FakeHandler handler) async {
  final dio = await DioService.getInstance();
  final adapter = FakeAdapter(handler);
  dio.httpClientAdapter = adapter;
  return adapter;
}

/// Routing sederhana: path → balasan. Path yang tidak dikenal → 404.
FakeHandler routes(Map<String, Object? Function(RequestOptions)> map) {
  return (o) {
    final fn = map[o.path];
    if (fn == null) {
      return const FakeReply(404, {'statusCode': 404, 'message': 'Tidak ditemukan', 'error': 'NotFound'});
    }
    final r = fn(o);
    return r is FakeReply ? r : FakeReply(200, r);
  };
}

/// Membungkus halaman dengan tema aplikasi.
Widget wrapApp(Widget child, {Brightness brightness = Brightness.light}) {
  AppColor.use(brightness);
  return MaterialApp(
    theme: brightness == Brightness.dark ? AppTheme.dark : AppTheme.light,
    locale: const Locale('id', 'ID'),
    home: child,
  );
}

/// Layar ponsel kecil 360x640 dp.
void useSmallPhone(WidgetTester tester, {double textScale = 1.0}) {
  tester.view.physicalSize = const Size(360 * 3, 640 * 3);
  tester.view.devicePixelRatio = 3;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(() {
    tester.view.reset();
    tester.platformDispatcher.clearTextScaleFactorTestValue();
    AppColor.use(Brightness.light);
  });
}

/// Mengumpulkan semua FlutterError (mis. RenderFlex overflow) selama
/// [body] berjalan, supaya bisa dilaporkan sebagai daftar alih-alih
/// menggagalkan uji di error pertama.
Future<List<String>> collectFlutterErrors(Future<void> Function() body) async {
  final errors = <String>[];
  final old = FlutterError.onError;
  FlutterError.onError = (d) => errors.add(d.exceptionAsString().split('\n').first);
  try {
    await body();
  } finally {
    FlutterError.onError = old;
  }
  return errors;
}
