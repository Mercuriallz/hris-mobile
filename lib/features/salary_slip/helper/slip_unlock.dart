import 'dart:async';

import '../../../helper/session_events.dart';

/// Token buka-kunci slip gaji, hanya di memori.
///
/// Sengaja tidak disimpan ke penyimpanan: begitu aplikasi ditutup atau pengguna
/// keluar dari halaman Slip Gaji, PIN diminta lagi. Server juga membatasi
/// umur token ini, jadi menyalin token dari memori tidak berguna lama.
class SlipUnlock {
  SlipUnlock._() {
    SessionEvents.cleared.listen((_) => clear());
  }

  static final SlipUnlock instance = SlipUnlock._();

  String? _token;
  final StreamController<void> _expired = StreamController<void>.broadcast();

  String? get token => _token;
  bool get isUnlocked => _token != null;

  /// Header yang harus menyertai setiap permintaan slip gaji.
  Map<String, String> get headers => _token == null ? const {} : {'X-Slip-Unlock': _token!};

  void set(String token) => _token = token;

  void clear() => _token = null;

  /// Server menolak token (kedaluwarsa atau PIN diganti): kunci lagi dan beri tahu halaman yang menampilkan slip.
  Stream<void> get onExpired => _expired.stream;

  void expire() {
    _token = null;
    _expired.add(null);
  }
}
