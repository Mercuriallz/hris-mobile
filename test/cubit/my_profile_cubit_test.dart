import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_mobile/features/auth/profile/cubit/my_profile_cubit.dart';
import 'package:hris_mobile/features/auth/profile/cubit/my_profile_state.dart';
import 'package:hris_mobile/features/auth/profile/model/my_profile_model.dart';
import 'package:hris_mobile/helper/session_events.dart';

import '../helpers/test_env.dart';

void main() {
  setUp(() => setUpTestEnv());

  group('MyProfileCubit', () {
    blocTest<MyProfileCubit, MyProfileState>(
      'sukses → Loading, Loaded',
      setUp: () => installFakeApi(routes({
        '/me': (_) => {
              'statusCode': 200,
              'data': {'fullName': 'Budi', 'profile': {'nationalId': '3201234567890001'}},
            },
      })),
      build: MyProfileCubit.new,
      act: (c) => c.fetch(),
      expect: () => [isA<MyProfileLoading>(), isA<MyProfileLoaded>()],
      verify: (c) => expect((c.state as MyProfileLoaded).profile.profile!.nationalId, '3201234567890001'),
    );

    blocTest<MyProfileCubit, MyProfileState>(
      'gagal → Error dengan pesan server',
      setUp: () => installFakeApi((_) => const FakeReply(404, {'message': 'Akun belum terhubung ke karyawan'})),
      build: MyProfileCubit.new,
      act: (c) => c.fetch(),
      expect: () => [isA<MyProfileLoading>(), MyProfileError('Akun belum terhubung ke karyawan')],
    );

    blocTest<MyProfileCubit, MyProfileState>(
      'silent gagal tidak mengganti data',
      setUp: () => installFakeApi((_) => const FakeReply(500, {})),
      build: MyProfileCubit.new,
      seed: () => MyProfileLoaded(MyProfileData(fullName: 'Budi')),
      act: (c) => c.fetch(silent: true),
      expect: () => <MyProfileState>[],
    );

    test('sesi berakhir → dikosongkan', () async {
      final cubit = MyProfileCubit();
      addTearDown(cubit.close);
      cubit.emit(MyProfileLoaded(MyProfileData(fullName: 'Budi')));
      SessionEvents.notifyCleared();
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state, isA<MyProfileInitial>());
    });
  });
}
