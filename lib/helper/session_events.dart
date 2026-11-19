import 'dart:async';

/// Kabar bahwa sesi login berakhir (keluar, atau token ditolak 401).
///
/// Cubit yang hidup sepanjang aplikasi dan menyimpan data pribadi (Surat dari
/// HR, slip gaji) mendengarkan ini untuk mengosongkan diri, supaya akun
/// berikutnya yang masuk di HP yang sama tidak melihat data akun sebelumnya.
class SessionEvents {
  SessionEvents._();

  static final StreamController<void> _cleared = StreamController<void>.broadcast();

  static Stream<void> get cleared => _cleared.stream;

  static void notifyCleared() => _cleared.add(null);
}
