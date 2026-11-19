import 'package:bloc_test/bloc_test.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_mobile/features/warning_letter/cubit/warning_letter_cubit.dart';
import 'package:hris_mobile/features/warning_letter/cubit/warning_letter_state.dart';
import 'package:hris_mobile/features/warning_letter/model/warning_letter_model.dart';

import '../helpers/test_env.dart';

Map<String, dynamic> letter(String id, {String? viewedAt, String status = 'active', String level = 'sp1'}) => {
      'id': id,
      'level': level,
      'issuedDate': '2026-10-01',
      'expiresDate': '2027-04-01',
      'violation': 'v$id',
      'status': status,
      'viewedAt': viewedAt,
    };

void main() {
  setUp(() => setUpTestEnv());

  group('WarningLetterCubit', () {
    blocTest<WarningLetterCubit, WarningLetterState>(
      'fetch sukses → Loading, Loaded; unreadCount menghitung yang belum dibuka',
      setUp: () => installFakeApi(routes({
        '/me/warning-letters': (_) => {
              'data': [letter('a'), letter('b', viewedAt: '2026-10-02T00:00:00Z'), letter('c')]
            },
      })),
      build: WarningLetterCubit.new,
      act: (c) => c.fetch(),
      expect: () => [isA<WarningLetterLoading>(), isA<WarningLetterLoaded>()],
      verify: (c) {
        expect((c.state as WarningLetterLoaded).letters.map((l) => l.id), ['a', 'b', 'c']);
        expect(c.unreadCount, 2);
      },
    );

    blocTest<WarningLetterCubit, WarningLetterState>(
      'fetch 4xx → Error dengan pesan server',
      setUp: () => installFakeApi((_) => const FakeReply(403, {'message': 'Akses ditolak'})),
      build: WarningLetterCubit.new,
      act: (c) => c.fetch(),
      expect: () => [isA<WarningLetterLoading>(), WarningLetterError('Akses ditolak')],
    );

    blocTest<WarningLetterCubit, WarningLetterState>(
      'fetch gagal koneksi → pesan koneksi',
      setUp: () => installFakeApi((o) => throw DioException(requestOptions: o, type: DioExceptionType.connectionError)),
      build: WarningLetterCubit.new,
      act: (c) => c.fetch(),
      expect: () => [
        isA<WarningLetterLoading>(),
        WarningLetterError('Tidak bisa menghubungi server. Periksa koneksi internet Anda.'),
      ],
    );

    blocTest<WarningLetterCubit, WarningLetterState>(
      'fetch silent yang gagal mempertahankan data lama',
      setUp: () => installFakeApi((_) => const FakeReply(500, {'message': 'x'})),
      build: WarningLetterCubit.new,
      seed: () => WarningLetterLoaded([WarningLetter.fromJson(letter('a'))]),
      act: (c) => c.fetch(silent: true),
      expect: () => <WarningLetterState>[],
      verify: (c) => expect(c.unreadCount, 1),
    );

    blocTest<WarningLetterCubit, WarningLetterState>(
      'data null → daftar kosong',
      setUp: () => installFakeApi((_) => const FakeReply(200, {'data': null})),
      build: WarningLetterCubit.new,
      act: (c) => c.fetch(),
      expect: () => [isA<WarningLetterLoading>(), WarningLetterLoaded(const [])],
    );

    blocTest<WarningLetterCubit, WarningLetterState>(
      'satu baris rusak (tanpa id) → Error umum, bukan crash',
      setUp: () => installFakeApi((_) => FakeReply(200, {
            'data': [letter('a'), {'level': 'sp1'}]
          })),
      build: WarningLetterCubit.new,
      act: (c) => c.fetch(),
      expect: () => [isA<WarningLetterLoading>(), WarningLetterError('Terjadi kesalahan. Coba lagi.')],
    );

    blocTest<WarningLetterCubit, WarningLetterState>(
      'markViewed menurunkan unreadCount tanpa memuat ulang',
      build: WarningLetterCubit.new,
      seed: () => WarningLetterLoaded([
        WarningLetter.fromJson(letter('a')),
        WarningLetter.fromJson(letter('b')),
      ]),
      act: (c) => c.markViewed('a'),
      expect: () => [isA<WarningLetterLoaded>()],
      verify: (c) {
        expect(c.unreadCount, 1);
        final ls = (c.state as WarningLetterLoaded).letters;
        expect(ls.firstWhere((l) => l.id == 'a').isUnread, isFalse);
        expect(ls.firstWhere((l) => l.id == 'b').isUnread, isTrue);
      },
    );

    blocTest<WarningLetterCubit, WarningLetterState>(
      'markViewed id tak dikenal / sudah dibaca → tidak emit',
      build: WarningLetterCubit.new,
      seed: () => WarningLetterLoaded([WarningLetter.fromJson(letter('a', viewedAt: 'x'))]),
      act: (c) => c
        ..markViewed('zzz')
        ..markViewed('a'),
      expect: () => <WarningLetterState>[],
    );

    blocTest<WarningLetterCubit, WarningLetterState>(
      'markViewed sebelum daftar dimuat → diabaikan; unreadCount 0',
      build: WarningLetterCubit.new,
      act: (c) => c.markViewed('a'),
      expect: () => <WarningLetterState>[],
      verify: (c) => expect(c.unreadCount, 0),
    );

    blocTest<WarningLetterCubit, WarningLetterState>(
      'reset → Initial',
      build: WarningLetterCubit.new,
      seed: () => WarningLetterLoaded([WarningLetter.fromJson(letter('a'))]),
      act: (c) => c.reset(),
      expect: () => [isA<WarningLetterInitial>()],
      verify: (c) => expect(c.unreadCount, 0),
    );
  });
}
