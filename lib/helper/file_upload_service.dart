import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as p;

import 'dio_service.dart';
import 'error_message.dart';

/// Mengunggah berkas ke object storage dan mengembalikan idnya.
///
/// Unggahan dipisah dari pengajuan, bukan dikirim jadi satu multipart.
/// Alasannya: foto bisa dua megabita di jaringan seluler yang buruk, dan
/// kalau gagal di tengah, orangnya harus mengisi ulang seluruh formulir.
/// Dengan dipisah, yang perlu diulang cuma unggahannya.
class FileUploadService {
  /// [category] menentukan folder di storage — 'attendance_selfie',
  /// 'leave_attachment', 'overtime_proof'.
  Future<String> upload(String filePath, String category) async {
    final dio = await DioService.getInstance();
    var logger = Logger();

    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          filePath,
          filename: p.basename(filePath),
        ),
      });

      final response = await dio.post(
        "/me/files",
        queryParameters: {"category": category},
        data: formData,
      );

      logger.d("upload $category +> ${response.statusCode}");
      logger.d("upload response +> ${response.data}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final id = response.data?['data']?['id'];

        if (id == null) {
          throw const FileUploadFailure(
            'Server tidak mengembalikan id berkas. Coba unggah lagi.',
          );
        }

        return id.toString();
      }

      throw FileUploadFailure(errorMessageFromResponse(response));
    } on FileUploadFailure {
      rethrow;
    } on DioException catch (e) {
      throw FileUploadFailure(errorMessage(e));
    } catch (e) {
      throw FileUploadFailure('Foto gagal diunggah: $e');
    }
  }
}

class FileUploadFailure implements Exception {
  final String message;

  const FileUploadFailure(this.message);

  @override
  String toString() => message;
}