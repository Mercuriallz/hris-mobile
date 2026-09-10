// import 'package:dio/dio.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'package:logger/logger.dart';

// import '../utils/token_storage.dart';

// /// Satu Dio untuk seluruh aplikasi, diakses lewat [DioClient.dio].
// ///
// /// Singleton, bukan disuntikkan lewat konstruktor, supaya cubit bisa dibuat
// /// tanpa argumen — `BlocProvider(create: (_) => LoginCubit())` — sesuai pola
// /// yang sudah dipakai di proyekmu.
// ///
// /// Token disisipkan lewat interceptor, bukan diteruskan sebagai parameter ke
// /// setiap panggilan. Dengan begitu tidak ada satu pun tempat yang bisa lupa
// /// mengirimkannya, dan penanganan token kedaluwarsa cukup ditulis sekali.
// class DioClient {
//   DioClient._();

//   static late final Dio dio;
//   static final TokenStorage _tokenStorage = TokenStorage();
//   static final Logger _logger = Logger();

//   /// Dipanggil saat server menolak token. Diisi di main.dart supaya lapisan
//   /// jaringan tidak perlu tahu apa pun tentang rute.
//   static void Function()? onUnauthorized;

//   static bool _initialized = false;

//   static void initialize() {
//     if (_initialized) return;
//     _initialized = true;

//     dio = Dio(
//       BaseOptions(
//         baseUrl: dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:3001',
//         connectTimeout: const Duration(seconds: 15),
//         receiveTimeout: const Duration(seconds: 20),
//         contentType: Headers.jsonContentType,

//         // Status 4xx TIDAK dianggap error transport, supaya body-nya bisa
//         // dibaca. Penolakan seperti "Anda 340 meter dari kantor" datang
//         // sebagai 409 dengan pesan yang memang perlu ditampilkan, bukan
//         // ditelan jadi "request failed".
//         validateStatus: (status) => status != null && status < 500,
//       ),
//     );

//     dio.interceptors.add(
//       InterceptorsWrapper(
//         onRequest: (options, handler) async {
//           final token = await _tokenStorage.readToken();
//           if (token != null && token.isNotEmpty) {
//             options.headers['Authorization'] = 'Bearer $token';
//           }
//           _logger.d('${options.method} ${options.path}');
//           handler.next(options);
//         },
//         onResponse: (response, handler) {
//           final status = response.statusCode ?? 0;

//           // Karena validateStatus meloloskan 4xx, penolakan diubah jadi
//           // DioException di sini — supaya pemanggil cukup menangani satu
//           // jalur kegagalan.
//           if (status >= 400) {
//             if (status == 401) {
//               _tokenStorage.clearSession();
//               onUnauthorized?.call();
//             }

//             handler.reject(
//               DioException(
//                 requestOptions: response.requestOptions,
//                 response: response,
//                 type: DioExceptionType.badResponse,
//               ),
//               true,
//             );
//             return;
//           }

//           handler.next(response);
//         },
//         onError: (e, handler) {
//           _logger.w('${e.requestOptions.path} gagal: ${e.message}');
//           handler.next(e);
//         },
//       ),
//     );
//   }
// }