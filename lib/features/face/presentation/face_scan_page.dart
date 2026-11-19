import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import '../../../constant/theme/app_color.dart';
import '../../../constant/theme/app_text.dart';
import '../../../helper/face_embedding_service.dart';


const int _stableFramesRequired = 8;


const double _minFaceRatio = 0.22;
const double _maxFaceRatio = 0.70;

/// Seberapa jauh pusat wajah boleh bergeser dari tengah layar, dalam
/// proporsi lebar dan tinggi bingkai kamera.
const double _maxOffsetX = 0.25;
const double _maxOffsetY = 0.30;

const double _ovalWidth = 260;
const double _ovalHeight = 340;

/// Jeda centang "Berhasil" sebelum halaman ditutup. Cukup lama untuk
/// terlihat, cukup singkat supaya tidak terasa menunggu.
const Duration _successHold = Duration(milliseconds: 650);


enum ScanGuidance {
  starting,
  searching,
  tooFar,
  tooClose,
  moveLeft,
  moveRight,
  moveUp,
  moveDown,
  multipleFaces,
  eyesClosed,
  holdStill,
  capturing,
  done,
}

/// Tiga nada umpan balik: belum ada wajah, wajah ada tapi perlu dibetulkan,
/// dan posisi sudah benar.
enum _Tone { idle, adjust, ready }


class FaceScanPage extends StatefulWidget {
  final String title;
  final String instruction;

  const FaceScanPage({
    super.key,
    this.title = 'Pindai Wajah',
    this.instruction = 'Posisikan wajah di dalam bingkai',
  });

  @override
  State<FaceScanPage> createState() => _FaceScanPageState();
}

class _FaceScanPageState extends State<FaceScanPage>
    with WidgetsBindingObserver {
  CameraController? _controller;
  FaceDetector? _detector;

  ScanGuidance _guidance = ScanGuidance.starting;
  int _stableFrames = 0;


  bool _busy = false;

  bool _captured = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _start();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {

    if (state == AppLifecycleState.inactive) {
      _controller?.dispose();
      _controller = null;
    } else if (state == AppLifecycleState.resumed && mounted && !_captured) {
      _start();
    }
  }

  Future<void> _start() async {
    try {
      final cameras = await availableCameras();

      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        front,

        ResolutionPreset.medium,
        enableAudio: false,

        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );

      await controller.initialize();

      _detector = FaceDetector(
        options: FaceDetectorOptions(

          performanceMode: FaceDetectorMode.fast,
          enableClassification: true,
          enableLandmarks: false,
          enableTracking: false,
          minFaceSize: 0.15,
        ),
      );

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _controller = controller;
        _guidance = ScanGuidance.searching;
      });

      await controller.startImageStream(_onFrame);
    } catch (e) {
      debugPrint('Kamera gagal disiapkan: $e');
      if (mounted) {
        setState(() => _error =
            'Kamera tidak bisa dibuka. Periksa izinnya di pengaturan HP.');
      }
    }
  }

  Future<void> _onFrame(CameraImage image) async {
    if (_busy || _captured || _detector == null) return;
    _busy = true;

    try {
      final input = _toInputImage(image);
      if (input == null) return;

      final faces = await _detector!.processImage(input);
      if (!mounted || _captured) return;

      final next = _evaluate(faces, image);

      if (next == ScanGuidance.holdStill) {
        // Getaran kecil saat posisi pertama kali terkunci, supaya orang tahu
        // dia tinggal diam tanpa harus membaca teksnya.
        if (_guidance != ScanGuidance.holdStill) {
          HapticFeedback.selectionClick();
        }

        _stableFrames += 1;

        if (_stableFrames >= _stableFramesRequired) {
          await _capture();
          return;
        }

        // Dibangun ulang tiap bingkai stabil, bukan cuma saat petunjuknya
        // berganti — cincin progresnya perlu maju selangkah demi selangkah.
        setState(() => _guidance = next);
        return;
      }

      _stableFrames = 0;
      if (next != _guidance) setState(() => _guidance = next);
    } catch (e) {
      debugPrint('Bingkai gagal diproses: $e');
    } finally {
      _busy = false;
    }
  }

  ScanGuidance _evaluate(List<Face> faces, CameraImage image) {
    if (faces.isEmpty) return ScanGuidance.searching;
    if (faces.length > 1) return ScanGuidance.multipleFaces;

    final face = faces.first;
    final camera = _controller?.description;

    // Di Android, ML Kit mengembalikan kotak wajah dalam koordinat gambar yang
    // sudah diputar tegak, sementara CameraImage tetap berukuran mendatar.
    // Tanpa ditukar, lebar dan tinggi bingkainya terbalik dan semua
    // perhitungan posisi di bawah ini meleset. Di iOS koordinatnya sudah
    // sesuai ukuran gambarnya.
    final sensor = camera?.sensorOrientation ?? 0;
    final swap = Platform.isAndroid && (sensor == 90 || sensor == 270);
    final frameWidth = (swap ? image.height : image.width).toDouble();
    final frameHeight = (swap ? image.width : image.height).toDouble();

    final ratio = face.boundingBox.height / frameHeight;

    if (ratio < _minFaceRatio) return ScanGuidance.tooFar;
    if (ratio > _maxFaceRatio) return ScanGuidance.tooClose;

    // Pratinjau kamera depan dicerminkan, jadi posisi di layar adalah
    // kebalikan posisi di gambar. Petunjuk arahnya mengikuti yang dilihat
    // orangnya di layar, seperti bercermin.
    final mirrored = camera?.lensDirection == CameraLensDirection.front;
    final rawX = face.boundingBox.center.dx / frameWidth;
    final dx = (mirrored ? 1 - rawX : rawX) - 0.5;
    final dy = face.boundingBox.center.dy / frameHeight - 0.5;

    if (dx.abs() > _maxOffsetX || dy.abs() > _maxOffsetY) {
      // Satu arah saja, yang paling meleset. Dua petunjuk sekaligus
      // ("geser kiri dan naik") membuat orang mengoreksi keduanya setengah.
      if (dx.abs() / _maxOffsetX >= dy.abs() / _maxOffsetY) {
        return dx < 0 ? ScanGuidance.moveRight : ScanGuidance.moveLeft;
      }
      return dy < 0 ? ScanGuidance.moveDown : ScanGuidance.moveUp;
    }

    final leftOpen = face.leftEyeOpenProbability;
    final rightOpen = face.rightEyeOpenProbability;

    if (leftOpen != null && rightOpen != null) {
      if (leftOpen < 0.3 && rightOpen < 0.3) return ScanGuidance.eyesClosed;
    }

    return ScanGuidance.holdStill;
  }

  InputImage? _toInputImage(CameraImage image) {
    final camera = _controller?.description;
    if (camera == null) return null;

    final rotation =
        InputImageRotationValue.fromRawValue(camera.sensorOrientation);
    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw as int);
    if (format == null) return null;


    if (image.planes.isEmpty) return null;

    return InputImage.fromBytes(
      bytes: image.planes.first.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes.first.bytesPerRow,
      ),
    );
  }

  Future<void> _capture() async {
    if (_captured) return;
    _captured = true;

    if (mounted) setState(() => _guidance = ScanGuidance.capturing);

    try {
      // Aliran dihentikan sebelum mengambil foto. Beberapa perangkat gagal
      // memotret saat alirannya masih jalan, dan gagalnya berupa pengecualian
      // yang pesannya tidak menyebut alirannya.
      await _controller?.stopImageStream();
      final file = await _controller!.takePicture();

      if (!mounted) {
        await deleteTempPhoto(file.path);
        return;
      }

      HapticFeedback.mediumImpact();
      setState(() => _guidance = ScanGuidance.done);

      await Future.delayed(_successHold);

      // Ditutup selama jeda centang: fotonya tidak akan dipakai siapa pun.
      if (!mounted) {
        await deleteTempPhoto(file.path);
        return;
      }

      Navigator.pop(context, file.path);
    } catch (e) {
      debugPrint('Gagal mengambil foto: $e');

      _captured = false;
      _stableFrames = 0;

      if (mounted) {
        setState(() => _guidance = ScanGuidance.searching);
        await _controller?.startImageStream(_onFrame);
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    _detector?.close();
    super.dispose();
  }

  ({String text, IconData? icon, _Tone tone}) get _guidanceInfo {
    switch (_guidance) {
      case ScanGuidance.starting:
        return (text: 'Menyiapkan kamera...', icon: null, tone: _Tone.idle);
      case ScanGuidance.searching:
        return (
          text: widget.instruction,
          icon: Icons.face_retouching_natural,
          tone: _Tone.idle,
        );
      case ScanGuidance.tooFar:
        return (
          text: 'Dekatkan wajah ke kamera',
          icon: Icons.zoom_in,
          tone: _Tone.adjust,
        );
      case ScanGuidance.tooClose:
        return (
          text: 'Jauhkan sedikit',
          icon: Icons.zoom_out,
          tone: _Tone.adjust,
        );
      case ScanGuidance.moveLeft:
        return (
          text: 'Geser ke kiri',
          icon: Icons.arrow_back,
          tone: _Tone.adjust,
        );
      case ScanGuidance.moveRight:
        return (
          text: 'Geser ke kanan',
          icon: Icons.arrow_forward,
          tone: _Tone.adjust,
        );
      case ScanGuidance.moveUp:
        return (
          text: 'Naikkan sedikit',
          icon: Icons.arrow_upward,
          tone: _Tone.adjust,
        );
      case ScanGuidance.moveDown:
        return (
          text: 'Turunkan sedikit',
          icon: Icons.arrow_downward,
          tone: _Tone.adjust,
        );
      case ScanGuidance.multipleFaces:
        return (
          text: 'Pastikan hanya Anda di dalam bingkai',
          icon: Icons.group_off_outlined,
          tone: _Tone.adjust,
        );
      case ScanGuidance.eyesClosed:
        return (
          text: 'Buka mata',
          icon: Icons.visibility_outlined,
          tone: _Tone.adjust,
        );
      case ScanGuidance.holdStill:
        return (
          text: 'Tahan sebentar...',
          icon: Icons.check_circle_outline,
          tone: _Tone.ready,
        );
      case ScanGuidance.capturing:
        return (text: 'Mengambil foto', icon: null, tone: _Tone.ready);
      case ScanGuidance.done:
        return (text: 'Berhasil', icon: Icons.check, tone: _Tone.ready);
    }
  }

  Color _ringColor(_Tone tone) => switch (tone) {
        _Tone.idle => Colors.white.withValues(alpha: 0.7),
        _Tone.adjust => AppColor.warning,
        _Tone.ready => AppColor.success,
      };

  double get _progress => switch (_guidance) {
        ScanGuidance.capturing || ScanGuidance.done => 1,
        ScanGuidance.holdStill => _stableFrames / _stableFramesRequired,
        _ => 0,
      };

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.videocam_off_outlined,
                  size: 44, color: AppColor.textDisabled),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center, style: AppText.body),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () {
                  setState(() => _error = null);
                  _start();
                },
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    final controller = _controller;
    final info = _guidanceInfo;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (controller != null && controller.value.isInitialized)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: controller.value.previewSize?.height ?? 1,
                height: controller.value.previewSize?.width ?? 1,
                child: CameraPreview(controller),
              ),
            )
          else
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),

          // Bingkai oval sebagai sasaran.
          //
          // Bukan hiasan: tanpa sasaran yang terlihat, "posisikan wajah di
          // tengah" tidak memberi tahu seberapa besar dan di mana. Area di
          // luarnya digelapkan supaya sasarannya tidak bisa salah dibaca, dan
          // warnanya ikut status — itu umpan balik yang terbaca tanpa membaca.
          //
          // Cincin progres di tepinya menunjukkan berapa lama lagi harus
          // diam. Tanpa itu, "tahan sebentar" tidak punya ujung, dan orang
          // yang bergerak sedikit tidak tahu hitungannya kembali ke nol.
          TweenAnimationBuilder<Color?>(
            tween: ColorTween(end: _ringColor(info.tone)),
            duration: const Duration(milliseconds: 250),
            builder: (context, ringColor, _) => TweenAnimationBuilder<double>(
              tween: Tween(end: _progress),
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              builder: (context, progress, _) => CustomPaint(
                painter: _OvalOverlayPainter(
                  ringColor: ringColor ?? Colors.white,
                  progressColor: AppColor.success,
                  progress: progress,
                ),
              ),
            ),
          ),

          if (_guidance == ScanGuidance.done)
            Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.4, end: 1),
                duration: const Duration(milliseconds: 420),
                curve: Curves.elasticOut,
                builder: (context, scale, child) =>
                    Transform.scale(scale: scale, child: child),
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: AppColor.success,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, size: 56, color: Colors.white),
                ),
              ),
            ),

          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        color: Colors.white,
                        tooltip: 'Batal',
                      ),
                      Expanded(
                        child: Text(
                          widget.title,
                          textAlign: TextAlign.center,
                          style: AppText.bodyStrong
                              .copyWith(color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),

                const Spacer(),

                Padding(
                  padding: const EdgeInsets.all(20),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween(
                          begin: const Offset(0, 0.25),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    ),
                    child: _GuidancePill(
                      key: ValueKey(_guidance),
                      text: info.text,
                      icon: info.icon,
                      tone: info.tone,
                      busy: _guidance == ScanGuidance.capturing,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GuidancePill extends StatelessWidget {
  final String text;
  final IconData? icon;
  final _Tone tone;
  final bool busy;

  const _GuidancePill({
    super.key,
    required this.text,
    required this.icon,
    required this.tone,
    required this.busy,
  });

  @override
  Widget build(BuildContext context) {
    final ready = tone == _Tone.ready;
    final iconColor = switch (tone) {
      _Tone.idle => Colors.white,
      _Tone.adjust => AppColor.warning,
      _Tone.ready => Colors.white,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: ready
            ? AppColor.success.withValues(alpha: 0.92)
            : Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (busy) ...[
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
          ] else if (icon != null) ...[
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: AppText.body.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

/// Menggelapkan layar di luar oval, menggambar tepi oval, dan cincin progres
/// yang berputar searah jarum jam dari atas.
class _OvalOverlayPainter extends CustomPainter {
  final Color ringColor;
  final Color progressColor;
  final double progress;

  const _OvalOverlayPainter({
    required this.ringColor,
    required this.progressColor,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final oval = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: _ovalWidth,
      height: _ovalHeight,
    );

    final dim = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addOval(oval);
    canvas.drawPath(dim, Paint()..color = Colors.black.withValues(alpha: 0.55));

    canvas.drawOval(
      oval,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = ringColor,
    );

    if (progress > 0) {
      canvas.drawArc(
        oval,
        -math.pi / 2,
        2 * math.pi * progress.clamp(0, 1),
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..strokeCap = StrokeCap.round
          ..color = progressColor,
      );
    }
  }

  @override
  bool shouldRepaint(_OvalOverlayPainter old) =>
      old.ringColor != ringColor ||
      old.progressColor != progressColor ||
      old.progress != progress;
}
