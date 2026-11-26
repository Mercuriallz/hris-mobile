import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_mobile/features/salary_slip/helper/slip_unlock.dart';
import 'package:hris_mobile/features/salary_slip/presentation/salary_slip_pin_gate.dart';
import 'package:hris_mobile/features/salary_slip/repository/salary_slip_pin_repository.dart';

import '../helpers/test_env.dart';

/// Repository palsu: hasilnya diatur per tes, tanpa jaringan.
class FakePinRepo extends SalarySlipPinRepository {
  SlipPinStatus? statusResult = const SlipPinStatus(hasPin: false);
  SlipPinResult Function(String pin)? onCreate;
  SlipPinResult Function(String pin)? onVerify;
  SlipPinResult Function(String password, String pin)? onReset;
  final created = <String>[];
  final verified = <String>[];

  @override
  Future<SlipPinStatus?> status() async => statusResult;

  @override
  Future<SlipPinResult> create(String pin) async {
    created.add(pin);
    return onCreate?.call(pin) ?? const SlipPinResult.success();
  }

  @override
  Future<SlipPinResult> verify(String pin) async {
    verified.add(pin);
    return onVerify?.call(pin) ?? const SlipPinResult.success();
  }

  @override
  Future<SlipPinResult> reset(String password, String newPin) async =>
      onReset?.call(password, newPin) ?? const SlipPinResult.success();
}

Future<void> typePin(WidgetTester t, String pin) async {
  for (final d in pin.split('')) {
    await t.tap(find.byKey(Key('pin-$d')));
    await t.pump();
  }
  await t.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    await setUpTestEnv();
    await loadApproximateFonts();
  });
  setUp(() => SlipUnlock.instance.clear());

  Widget gate(FakePinRepo repo) => wrapApp(SalarySlipGate(repository: repo, child: const Scaffold(body: Text('ISI SLIP'))));

  group('belum punya PIN', () {
    testWidgets('wajib membuat PIN dulu: isi slip belum terlihat, PIN diulang, baru terbuka', (t) async {
      final repo = FakePinRepo();
      await t.pumpWidget(gate(repo));
      await t.pumpAndSettle();

      expect(find.text('Buat PIN slip gaji'), findsOneWidget);
      expect(find.text('ISI SLIP'), findsNothing);

      await typePin(t, '482916');
      expect(find.text('Ulangi PIN'), findsOneWidget);
      expect(repo.created, isEmpty);

      await typePin(t, '482916');
      expect(repo.created, ['482916']);
      expect(find.text('ISI SLIP'), findsOneWidget);
    });

    testWidgets('PIN ulangan tidak sama → ulang dari awal, tidak dikirim ke server', (t) async {
      final repo = FakePinRepo();
      await t.pumpWidget(gate(repo));
      await t.pumpAndSettle();
      await typePin(t, '482916');
      await typePin(t, '482917');

      expect(find.text('PIN tidak sama. Ulangi dari awal.'), findsOneWidget);
      expect(find.text('Buat PIN slip gaji'), findsOneWidget);
      expect(repo.created, isEmpty);
      expect(find.text('ISI SLIP'), findsNothing);
    });

    testWidgets('server menolak PIN lemah → pesan server tampil, tetap di layar buat PIN', (t) async {
      final repo = FakePinRepo()..onCreate = (_) => const SlipPinResult.failure('PIN terlalu mudah ditebak.');
      await t.pumpWidget(gate(repo));
      await t.pumpAndSettle();
      await typePin(t, '111111');
      await typePin(t, '111111');

      expect(find.text('PIN terlalu mudah ditebak.'), findsOneWidget);
      expect(find.text('ISI SLIP'), findsNothing);
    });
  });

  group('sudah punya PIN', () {
    FakePinRepo withPin() => FakePinRepo()..statusResult = const SlipPinStatus(hasPin: true);

    testWidgets('slip terkunci sampai PIN benar', (t) async {
      final repo = withPin();
      await t.pumpWidget(gate(repo));
      await t.pumpAndSettle();
      expect(find.text('Masukkan PIN'), findsOneWidget);
      expect(find.text('ISI SLIP'), findsNothing);

      await typePin(t, '482916');
      expect(repo.verified, ['482916']);
      expect(find.text('ISI SLIP'), findsOneWidget);
    });

    testWidgets('PIN salah → pesan dengan sisa percobaan, isian dikosongkan, slip tetap terkunci', (t) async {
      final repo = withPin()
        ..onVerify = (_) => const SlipPinResult.failure('PIN salah. Sisa percobaan 4.', remainingAttempts: 4);
      await t.pumpWidget(gate(repo));
      await t.pumpAndSettle();
      await typePin(t, '000001');

      expect(find.text('PIN salah. Sisa percobaan 4.'), findsOneWidget);
      expect(find.text('ISI SLIP'), findsNothing);
      // Bisa mencoba lagi.
      repo.onVerify = null;
      await typePin(t, '482916');
      expect(find.text('ISI SLIP'), findsOneWidget);
    });

    testWidgets('terkunci (429) → papan angka tidak lagi menerima input', (t) async {
      final repo = withPin()
        ..onVerify = (_) => const SlipPinResult.failure('Dikunci 15 menit.', locked: true);
      await t.pumpWidget(gate(repo));
      await t.pumpAndSettle();
      await typePin(t, '000001');
      expect(find.text('Dikunci 15 menit.'), findsOneWidget);

      await typePin(t, '482916');
      expect(repo.verified, ['000001']); // ketukan berikutnya diabaikan
      expect(find.text('ISI SLIP'), findsNothing);
    });

    testWidgets('Lupa PIN: kata sandi dan PIN baru, lalu slip terbuka', (t) async {
      String? sentPassword, sentPin;
      final repo = withPin()
        ..onReset = (p, n) {
          sentPassword = p;
          sentPin = n;
          return const SlipPinResult.success();
        };
      await t.pumpWidget(gate(repo));
      await t.pumpAndSettle();

      await t.tap(find.text('Lupa PIN?'));
      await t.pumpAndSettle();
      await t.enterText(find.byKey(const Key('reset-password')), 'Rahasia-123');
      await t.enterText(find.byKey(const Key('reset-pin')), '739204');
      await t.enterText(find.byKey(const Key('reset-pin2')), '739204');
      await t.tap(find.text('Simpan'));
      await t.pumpAndSettle();

      expect((sentPassword, sentPin), ('Rahasia-123', '739204'));
      expect(find.text('ISI SLIP'), findsOneWidget);
    });

    testWidgets('Lupa PIN: PIN baru dan ulangannya beda → tidak dikirim', (t) async {
      var called = false;
      final repo = withPin()..onReset = (_, _) { called = true; return const SlipPinResult.success(); };
      await t.pumpWidget(gate(repo));
      await t.pumpAndSettle();
      await t.tap(find.text('Lupa PIN?'));
      await t.pumpAndSettle();
      await t.enterText(find.byKey(const Key('reset-password')), 'x');
      await t.enterText(find.byKey(const Key('reset-pin')), '739204');
      await t.enterText(find.byKey(const Key('reset-pin2')), '739205');
      await t.tap(find.text('Simpan'));
      await t.pumpAndSettle();
      expect(find.text('PIN baru dan ulangannya tidak sama.'), findsOneWidget);
      expect(called, isFalse);
    });

    testWidgets('token buka-kunci dibuang saat keluar dari halaman, dan sesi habis meminta PIN lagi', (t) async {
      final repo = withPin();
      await t.pumpWidget(gate(repo));
      await t.pumpAndSettle();
      SlipUnlock.instance.set('token-uji'); // seolah PIN benar sudah menghasilkan token
      await typePin(t, '482916');
      expect(find.text('ISI SLIP'), findsOneWidget);

      SlipUnlock.instance.expire(); // server menolak token
      await t.pumpAndSettle();
      expect(find.text('Masukkan PIN'), findsOneWidget);
      expect(find.text('ISI SLIP'), findsNothing);

      SlipUnlock.instance.set('token-lagi');
      await t.pumpWidget(const SizedBox()); // halaman ditutup
      expect(SlipUnlock.instance.token, isNull);
    });
  });

  testWidgets('gagal memeriksa status → ErrorState, Coba Lagi memuat ulang', (t) async {
    final repo = FakePinRepo()..statusResult = null;
    await t.pumpWidget(gate(repo));
    await t.pumpAndSettle();
    expect(find.text('Coba Lagi'), findsOneWidget);
    expect(find.text('ISI SLIP'), findsNothing);

    repo.statusResult = const SlipPinStatus(hasPin: false);
    await t.tap(find.text('Coba Lagi'));
    await t.pumpAndSettle();
    expect(find.text('Buat PIN slip gaji'), findsOneWidget);
  });

  for (final b in Brightness.values) {
    testWidgets('360x640 ${b.name}: layar PIN tanpa overflow', (t) async {
      t.view.physicalSize = const Size(360, 640);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      final repo = FakePinRepo()..statusResult = const SlipPinStatus(hasPin: true);
      repo.onVerify = (_) => const SlipPinResult.failure('PIN salah. Sisa percobaan 4.', remainingAttempts: 4);
      await t.pumpWidget(wrapApp(SalarySlipGate(repository: repo, child: const SizedBox()), brightness: b));
      await t.pumpAndSettle();
      await typePin(t, '000001');
      expect(t.takeException(), isNull);
    });
  }
}
