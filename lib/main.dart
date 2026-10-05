import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hris_mobile/features/approval/cubit/approval_cubit.dart';
import 'package:hris_mobile/features/approval/cubit/approval_detail_cubit.dart';
import 'package:hris_mobile/features/attendance-history/cubit/attendance_history_cubit.dart';
import 'package:hris_mobile/features/auth/login/cubit/login_cubit.dart';
import 'package:hris_mobile/features/auth/profile/cubit/photo_cubit.dart';
import 'package:hris_mobile/features/face/cubit/face_enroll_cubit.dart';
import 'package:hris_mobile/features/leave/cubit/leave_cubit.dart';
import 'package:hris_mobile/features/leave/cubit/leave_form_cubit.dart';
import 'package:hris_mobile/features/overtime/cubit/overtime/overtime_cubit.dart';
import 'package:hris_mobile/features/overtime/cubit/overtime_form/overtime_form_cubit.dart';
import 'package:hris_mobile/features/shift-swap/cubit/shift_swap_cubit.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'constant/route/app_route.dart';
import 'constant/theme/app_theme.dart';
import 'features/attendance/cubit/attendance_cubit.dart';
import 'features/attendance_request/cubit/attendance_request_cubit.dart';
import 'helper/dio_service.dart';



const appEnv = String.fromEnvironment('ENV', defaultValue: 'development');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('id_ID', null);

  final envFile =
      appEnv == "production" ? ".env.production" : ".env.development";

  await dotenv.load(fileName: envFile);


  DioService.onUnauthorized = () => router.go('/login');

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => LoginCubit()),
        BlocProvider(create: (_) => AttendanceCubit()),
        BlocProvider(create: (_) => AttendanceHistoryCubit()),
        BlocProvider(create: (_) => AttendanceRequestCubit()),
        BlocProvider(create: (_) => ApprovalCubit()),
        BlocProvider(create: (_) => ApprovalDetailCubit()),
        BlocProvider(create: (_) => LeaveCubit()),
        BlocProvider(create: (_) => LeaveFormCubit()),
        BlocProvider(create: (_) => PhotoCubit()),
        BlocProvider(create: (_) => FaceEnrollCubit()),
        BlocProvider(create: (_) => OvertimeCubit()),
        BlocProvider(create: (_) => OvertimeFormCubit()),
        BlocProvider(create: (_) => ShiftSwapCubit(),)
        
      ],
      child: MaterialApp.router(
        routerConfig: router,
        theme: AppTheme.light,
        debugShowCheckedModeBanner: false,
      ),
    ),
  );
}