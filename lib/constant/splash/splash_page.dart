import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hris_mobile/helper/app_update_service.dart';
import 'package:hris_mobile/helper/push_routing.dart';

import '../../features/auth/login/cubit/login_cubit.dart';
import '../route/app_route.dart';
import '../theme/app_color.dart';
import '../theme/app_text.dart';
import '../theme/app_widget.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _decide();
  }

 Future<void> _decide() async {
  // Tahan sebentar. Kalau pengecekan sesi selesai seketika, splash cuma
  // berkedip sepersekian detik dan terasa seperti glitch.
  final results = await Future.wait([
    context.read<LoginCubit>().hasSession(),
    Future<void>.delayed(const Duration(milliseconds: 800)),
  ]);
  if (!mounted) return;

  final hasSession = results.first as bool;
  router.go(hasSession ? '/home' : '/login');


  if (hasSession) unawaited(PushRouting.consumeIfReady());

  // Setelah navigasi, bukan sebelumnya: dialog Play tidak boleh menahan
  // splash, dan pengecekannya butuh jaringan yang bisa lambat.
  unawaited(AppUpdateService.check());
}

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppColor.isDark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColor.surface,
        body: Stack(
          children: [
            // Dua cahaya biru tipis di sudut berseberangan. Cukup untuk
            // memberi kedalaman tanpa mengalahkan logo di tengah.
            Positioned(
              top: -140,
              right: -120,
              child: SoftGlow(size: 360, color: AppColor.primaryLight),
            ),
            Positioned(
              bottom: -160,
              left: -140,
              child: SoftGlow(size: 380, color: AppColor.primary),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset(
                    'assets/images/workonix-logo.svg',
                    height: 52,
                  ),
                  const SizedBox(height: 14),
                  Text('Absensi & HR dalam genggaman', style: AppText.caption),
                ],
              ),
            ),
            Positioned(
              left: 24,
              right: 24,
              bottom: 0,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Text(
                    '© ${DateTime.now().year} Workonix',
                    textAlign: TextAlign.center,
                    style: AppText.label.copyWith(color: AppColor.textDisabled),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
