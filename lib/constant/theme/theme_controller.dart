import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_color.dart';

/// Menyimpan pilihan mode tampilan dan menukar palet [AppColor].
///
/// Banyak widget membaca [AppColor] langsung, bukan lewat `Theme.of`, jadi
/// mereka tidak ikut dibangun ulang saat tema berganti. Karena itu setiap kali
/// palet berubah, seluruh pohon widget ditandai kotor — sekali, saat ganti
/// mode, bukan tiap frame.
class ThemeController extends ValueNotifier<ThemeMode>
    with WidgetsBindingObserver {
  ThemeController._() : super(ThemeMode.system);

  static final instance = ThemeController._();

  static const _key = 'theme_mode';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    value = ThemeMode.values.firstWhere(
      (m) => m.name == saved,
      orElse: () => ThemeMode.system,
    );
    AppColor.use(_effectiveBrightness);
    WidgetsBinding.instance.addObserver(this);
  }

  Future<void> setMode(ThemeMode mode) async {
    if (mode == value) return;
    value = mode;
    _applyPalette();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode.name);
  }

  Brightness get _effectiveBrightness => switch (value) {
        ThemeMode.light => Brightness.light,
        ThemeMode.dark => Brightness.dark,
        ThemeMode.system =>
          WidgetsBinding.instance.platformDispatcher.platformBrightness,
      };

  @override
  void didChangePlatformBrightness() {
    if (value == ThemeMode.system) _applyPalette();
  }

  void _applyPalette() {
    final brightness = _effectiveBrightness;
    final wasDark = AppColor.isDark;
    AppColor.use(brightness);
    if (wasDark != AppColor.isDark) _rebuildAll();
  }

  static void _rebuildAll() {
    void visit(Element e) {
      e.markNeedsBuild();
      e.visitChildren(visit);
    }

    WidgetsBinding.instance.rootElement?.visitChildren(visit);
  }
}
