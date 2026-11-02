import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hris_mobile/constant/bottom_bar/bottom_main.dart';
import 'package:hris_mobile/constant/splash/splash_page.dart';
import 'package:hris_mobile/features/approval/presentation/approval_detail_page.dart';
import 'package:hris_mobile/features/auth/change-password/presentation/change_password_page.dart';

import '../../features/auth/login/presentation/login_page.dart';


final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();


final GoRouter router = GoRouter(
  navigatorKey: navigatorKey,
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashPage(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => LoginPage(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const BottomMain(),
    ),

    /// Tidak ada tombol kembali di halaman ini, dan itu disengaja: backend
    /// menolak seluruh endpoint lain sampai passwordnya diganti, jadi
    /// membiarkan orang keluar cuma menghasilkan aplikasi yang tidak bisa
    /// memuat apa pun.
    GoRoute(
      path: '/change-password',
      builder: (context, state) => ChangePasswordPage(
      ),
    ),

    GoRoute(
  path: '/approval/:id',
  builder: (context, state) => ApprovalDetailPage(
    approvalId: state.pathParameters['id']!,
  ),
),
    // GoRoute(
    //   path: '/home',
    //   builder: (context, state) => const BottomMain(),
    // ),
  ],
);