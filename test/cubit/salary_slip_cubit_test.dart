import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_mobile/features/salary_slip/cubit/salary_slip_cubit.dart';
import 'package:hris_mobile/features/salary_slip/cubit/salary_slip_state.dart';
import 'package:hris_mobile/features/salary_slip/model/salary_slip_model.dart';

import '../helpers/test_env.dart';

Map<String, dynamic> slip(String id, String month, [Object net = '1000']) =>
    {'id': id, 'month': month, 'startDate': '$month-01', 'endDate': '$month-28', 'netPay': net};

void main() {
  setUp(() => setUpTestEnv());

  group('SalarySlipCubit', () {
    blocTest<SalarySlipCubit, SalarySlipState>(
      'mengurutkan bulan terbaru di atas, apa pun urutan server (melewati batas tahun)',
      setUp: () => installFakeApi(routes({
        '/me/salary-slips': (_) => {
              'data': [
                slip('a', '2025-12'),
                slip('b', '2026-02'),
                slip('c', '2025-11'),
                slip('d', '2026-01'),
              ]
            },
      })),
      build: SalarySlipCubit.new,
      act: (c) => c.fetch(),
      expect: () => [isA<SalarySlipLoading>(), isA<SalarySlipLoaded>()],
      verify: (c) => expect(
        (c.state as SalarySlipLoaded).slips.map((s) => s.month),
        ['2026-02', '2026-01', '2025-12', '2025-11'],
      ),
    );

    blocTest<SalarySlipCubit, SalarySlipState>(
      'kosong → Loaded([])',
      setUp: () => installFakeApi((_) => const FakeReply(200, {'data': []})),
      build: SalarySlipCubit.new,
      act: (c) => c.fetch(),
      expect: () => [isA<SalarySlipLoading>(), SalarySlipLoaded(const [])],
    );

    blocTest<SalarySlipCubit, SalarySlipState>(
      'gagal → Error; silent gagal → tetap data lama',
      setUp: () => installFakeApi((_) => const FakeReply(404, {'message': 'Karyawan tidak ditemukan'})),
      build: SalarySlipCubit.new,
      act: (c) => c.fetch(),
      expect: () => [isA<SalarySlipLoading>(), SalarySlipError('Karyawan tidak ditemukan')],
    );

    blocTest<SalarySlipCubit, SalarySlipState>(
      'silent gagal tidak mengganti data',
      setUp: () => installFakeApi((_) => const FakeReply(500, {})),
      build: SalarySlipCubit.new,
      seed: () => SalarySlipLoaded([SalarySlip.fromJson(slip('a', '2026-01'))]),
      act: (c) => c.fetch(silent: true),
      expect: () => <SalarySlipState>[],
    );

    blocTest<SalarySlipCubit, SalarySlipState>(
      'silent sukses dengan nominal berubah → emit Loaded baru',
      setUp: () => installFakeApi((_) => FakeReply(200, {
            'data': [slip('a', '2026-01', '2000')]
          })),
      build: SalarySlipCubit.new,
      seed: () => SalarySlipLoaded([SalarySlip.fromJson(slip('a', '2026-01'))]),
      act: (c) => c.fetch(silent: true),
      expect: () => [isA<SalarySlipLoaded>()],
      verify: (c) => expect((c.state as SalarySlipLoaded).slips.single.takeHomePay, 2000),
    );

    blocTest<SalarySlipCubit, SalarySlipState>(
      'reset → Initial',
      build: SalarySlipCubit.new,
      seed: () => SalarySlipLoaded(const []),
      act: (c) => c.reset(),
      expect: () => [isA<SalarySlipInitial>()],
    );

    test('Catatan: SalarySlipCubit tidak punya unreadCount/markViewed (hanya WarningLetterCubit)', () {
      final c = SalarySlipCubit();
      expect(c.state, isA<SalarySlipInitial>());
      c.close();
    });
  });
}
