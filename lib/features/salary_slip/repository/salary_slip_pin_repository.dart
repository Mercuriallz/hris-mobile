import 'package:dio/dio.dart';

import '../../../helper/dio_service.dart';
import '../../../helper/error_message.dart';
import '../helper/slip_unlock.dart';

class SlipPinStatus {
  final bool hasPin;
  final DateTime? lockedUntil;

  const SlipPinStatus({required this.hasPin, this.lockedUntil});

  bool get isLocked => lockedUntil != null && lockedUntil!.isAfter(DateTime.now());
}

/// Hasil operasi PIN. Satu bentuk untuk sukses dan gagal supaya layar bisa
/// menampilkan sisa percobaan atau waktu kunci tanpa menebak dari teks.
class SlipPinResult {
  final bool ok;
  final String? message;
  final int? remainingAttempts;
  final bool locked;

  const SlipPinResult.success() : ok = true, message = null, remainingAttempts = null, locked = false;

  const SlipPinResult.failure(this.message, {this.remainingAttempts, this.locked = false}) : ok = false;
}

/// PIN pribadi untuk membuka slip gaji. Server yang memeriksa PIN, aplikasi
/// hanya menyimpan token buka-kunci di memori (lihat [SlipUnlock]).
class SalarySlipPinRepository {
  static const _path = '/me/salary-slip-pin';

  Future<SlipPinStatus?> status() async {
    final dio = await DioService.getInstance();
    try {
      final r = await dio.get(_path);
      if (r.statusCode != 200) return null;
      final d = (r.data['data'] as Map?) ?? const {};
      final until = d['lockedUntil'] as String?;
      return SlipPinStatus(hasPin: d['hasPin'] == true, lockedUntil: until == null ? null : DateTime.tryParse(until)?.toLocal());
    } catch (_) {
      return null;
    }
  }

  Future<SlipPinResult> create(String pin) => _send('POST', _path, {'pin': pin});

  Future<SlipPinResult> verify(String pin) => _send('POST', '$_path/verify', {'pin': pin});

  Future<SlipPinResult> change(String currentPin, String newPin) =>
      _send('PATCH', _path, {'currentPin': currentPin, 'newPin': newPin});

  /// Lupa PIN: dibuktikan dengan kata sandi akun.
  Future<SlipPinResult> reset(String password, String newPin) =>
      _send('POST', '$_path/reset', {'password': password, 'newPin': newPin});

  Future<SlipPinResult> _send(String method, String path, Map<String, dynamic> body) async {
    final dio = await DioService.getInstance();
    try {
      final r = await dio.request(path, data: body, options: Options(method: method));
      final code = r.statusCode ?? 0;
      if (code == 200 || code == 201) {
        final token = (r.data['data'] as Map?)?['unlockToken'] as String?;
        if (token == null) return const SlipPinResult.failure('Respons server tidak lengkap. Coba lagi.');
        SlipUnlock.instance.set(token);
        return const SlipPinResult.success();
      }
      final data = r.data is Map ? r.data as Map : const {};
      return SlipPinResult.failure(
        errorMessageFromResponse(r),
        remainingAttempts: data['remainingAttempts'] as int?,
        locked: code == 429,
      );
    } catch (e) {
      return SlipPinResult.failure(errorMessage(e));
    }
  }
}
