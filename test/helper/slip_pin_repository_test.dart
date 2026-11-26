import 'package:flutter_test/flutter_test.dart';
import 'package:hris_mobile/features/salary_slip/helper/slip_unlock.dart';
import 'package:hris_mobile/features/salary_slip/repository/salary_slip_pin_repository.dart';
import 'package:hris_mobile/features/salary_slip/repository/salary_slip_repository.dart';

import '../helpers/test_env.dart';

void main() {
  setUp(() async {
    await setUpTestEnv();
    SlipUnlock.instance.clear();
  });

  group('SalarySlipPinRepository', () {
    test('verifikasi benar menyimpan token di memori', () async {
      await installFakeApi(routes({
        '/me/salary-slip-pin/verify': (_) => {'data': {'unlockToken': 'tok-123', 'expiresInSeconds': 300}},
      }));
      final r = await SalarySlipPinRepository().verify('482916');
      expect(r.ok, isTrue);
      expect(SlipUnlock.instance.token, 'tok-123');
    });

    test('PIN salah (422) → pesan dan sisa percobaan, token tidak tersimpan', () async {
      await installFakeApi((_) => const FakeReply(422, {'message': 'PIN salah. Sisa percobaan 3.', 'remainingAttempts': 3}));
      final r = await SalarySlipPinRepository().verify('000001');
      expect(r.ok, isFalse);
      expect(r.remainingAttempts, 3);
      expect(r.locked, isFalse);
      expect(SlipUnlock.instance.token, isNull);
    });

    test('terkunci (429) ditandai locked', () async {
      await installFakeApi((_) => const FakeReply(429, {'message': 'Dikunci 15 menit.'}));
      final r = await SalarySlipPinRepository().verify('000001');
      expect(r.locked, isTrue);
    });

    test('status membaca hasPin', () async {
      await installFakeApi(routes({
        '/me/salary-slip-pin': (_) => {'data': {'hasPin': true, 'lockedUntil': null}},
      }));
      final s = await SalarySlipPinRepository().status();
      expect(s!.hasPin, isTrue);
      expect(s.isLocked, isFalse);
    });
  });

  group('SalarySlipRepository + PIN', () {
    test('permintaan slip membawa header token buka-kunci', () async {
      SlipUnlock.instance.set('tok-abc');
      String? header;
      await installFakeApi(routes({
        '/me/salary-slips': (o) {
          header = o.headers['X-Slip-Unlock'] as String?;
          return {'data': []};
        },
      }));
      await SalarySlipRepository().getMine();
      expect(header, 'tok-abc');
    });

    test('403 SlipPinRequired → token dibuang, PIN diminta lagi, pesan jelas', () async {
      SlipUnlock.instance.set('tok-lama');
      var expired = 0;
      final sub = SlipUnlock.instance.onExpired.listen((_) => expired++);
      addTearDown(sub.cancel);
      await installFakeApi((_) => const FakeReply(403, {'message': 'Slip gaji dilindungi PIN.', 'error': 'SlipPinRequired'}));
      final r = await SalarySlipRepository().getMine();
      await Future<void>.delayed(Duration.zero);
      expect(r.isLeft(), isTrue);
      expect(SlipUnlock.instance.token, isNull);
      expect(expired, 1);
    });
  });
}
