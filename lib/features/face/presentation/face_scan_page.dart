import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import '../../../constant/theme/app_color.dart';
import '../../../constant/theme/app_text.dart';

/// Berapa bingkai berurutan yang harus bagus sebelum foto diambil.
///
/// Delapan bingkai sekitar setengah detik. Terlalu sedikit dan fotonya
/// terambil saat orangnya masih bergerak; terlalu banyak dan dia merasa
/// aplikasinya tidak merespons.
const int _stableFramesRequired = 8;

/// Proporsi tinggi bingkai yang harus ditempati wajah.
///
/// Di bawah batas bawah, wajahnya terlalu kecil dan embedding-nya jadi
/// buram. Di atas batas atas, sebagian wajah biasanya terpotong keluar
/// bingkai — dan wajah terpotong lebih buruk daripada wajah kecil, karena
/// bagian yang hilang justru yang dipakai membedakan.
const double _minFaceRatio = 0.22;
const double _maxFaceRatio = 0.70;

/// Apa yang sedang dilihat kamera.
///
/// Setiap keadaan punya arahan yang berbeda. "Wajah tidak terdeteksi" dan
/// "wajah terlalu jauh" menuntut tindakan yang berbeda, dan menggabungkannya
/// jadi satu pesan berarti orangnya menebak mana yang salah.
enum ScanGuidance {
  starting,
  searching,
  tooFar,
  tooClose,
  offCenter,
  multipleFaces,
  eyesClosed,
  holdStill,
  capturing,
}

/// Memindai wajah dengan pratinjau kamera langsung.
///
/// Mengembalikan jalur berkas foto lewat Navigator.pop, atau null kalau
/// dibatalkan.
///
/// Berbeda dari ImagePicker yang membuka kamera bawaan sistem: di sana orang
/// harus menekan shutter lalu menyetujui pratinjau — tiga ketukan untuk
/// sesuatu yang seharusnya nol. Dan yang lebih penting, arahan hanya bisa
/// diberikan SETELAH fotonya ditolak. Di sini arahannya muncul sebelum
/// fotonya diambil.
class FaceScanPage extends StatefulWidget {
  /// Ditampilkan di atas layar. Berbeda antara mendaftar dan absen.
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

  /// Mencegah bingkai menumpuk.
  ///
  /// Aliran kamera mengirim bingkai jauh lebih cepat daripada deteksi wajah
  /// selesai. Tanpa penanda ini, bingkai menumpuk di memori sampai
  /// aplikasinya mati — dan matinya bukan karena kode deteksinya salah,
  /// melainkan karena tidak ada yang menahan alirannya.
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
    // Kamera dilepas saat aplikasi ke latar belakang. Tanpa ini, kembali ke
    // aplikasi menghasilkan pratinjau yang beku — dan orangnya akan menunggu
    // arahan yang tidak akan pernah berubah.
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
        // Sedang, bukan tinggi. Wajah diperkecil ke 112 piksel sebelum
        // dihitung, jadi resolusi tinggi tidak menambah ketepatan — cuma
        // menambah waktu pemrosesan tiap bingkai.
        ResolutionPreset.medium,
        enableAudio: false,
        // Format satu bidang, supaya bytes-nya bisa langsung diberikan ke ML
        // Kit tanpa mengubah YUV ke NV21 sendiri. Konversi manual itu tempat
        // kesalahan paling sering terjadi di alur ini.
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );

      await controller.initialize();

      _detector = FaceDetector(
        options: FaceDetectorOptions(
          // Cepat, bukan akurat — berbeda dari saat menghitung embedding.
          //
          // Di sini deteksinya cuma untuk mengarahkan posisi, dan itu perlu
          // berjalan belasan kali per detik. Mode akurat memakan waktu yang
          // membuat arahannya tersendat, dan arahan yang tersendat lebih
          // buruk daripada arahan yang sedikit kurang tepat.
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
        _stableFrames += 1;

        if (_stableFrames >= _stableFramesRequired) {
          await _capture();
          return;
        }
      } else {
        // Hitungan direset begitu ada bingkai yang tidak bagus. Tanpa reset,
        // delapan bingkai bagus yang terpisah-pisah oleh gerakan akan
        // memicu pengambilan foto justru saat orangnya bergerak.
        _stableFrames = 0;
      }

      if (next != _guidance) setState(() => _guidance = next);
    } catch (e) {
      debugPrint('Bingkai gagal diproses: $e');
    } finally {
      _busy = false;
    }
  }

  /// Menilai bingkai dan menentukan arahannya.
  ScanGuidance _evaluate(List<Face> faces, CameraImage image) {
    if (faces.isEmpty) return ScanGuidance.searching;
    if (faces.length > 1) return ScanGuidance.multipleFaces;

    final face = faces.first;
    final frameHeight = image.height.toDouble();
    final ratio = face.boundingBox.height / frameHeight;

    if (ratio < _minFaceRatio) return ScanGuidance.tooFar;
    if (ratio > _maxFaceRatio) return ScanGuidance.tooClose;

    // Wajah harus dekat tengah. Yang di pinggir sering terpotong sebagian
    // saat difoto, dan potongan yang hilang itulah yang dipakai membedakan.
    final centerX = face.boundingBox.center.dx / image.width;
    final centerY = face.boundingBox.center.dy / frameHeight;

    if (centerX < 0.25 || centerX > 0.75 || centerY < 0.2 || centerY > 0.8) {
      return ScanGuidance.offCenter;
    }

    // Mata terpejam ditolak. Bukan untuk mendeteksi kehidupan — itu butuh
    // urutan gerakan — tapi karena wajah dengan mata tertutup menghasilkan
    // embedding yang berbeda cukup jauh dari wajah yang sama dengan mata
    // terbuka.
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

    // Satu bidang saja, berkat imageFormatGroup di atas. Kalau formatnya
    // YUV420 dengan tiga bidang, bagian ini butuh penggabungan manual — dan
    // itu yang sengaja dihindari.
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

      if (!mounted) return;
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

  ({String text, bool ready}) get _guidanceText {
    switch (_guidance) {
      case ScanGuidance.starting:
        return (text: 'Menyiapkan kamera...', ready: false);
      case ScanGuidance.searching:
        return (text: widget.instruction, ready: false);
      case ScanGuidance.tooFar:
        return (text: 'Dekatkan wajah ke kamera', ready: false);
      case ScanGuidance.tooClose:
        return (text: 'Jauhkan sedikit', ready: false);
      case ScanGuidance.offCenter:
        return (text: 'Posisikan wajah di tengah bingkai', ready: false);
      case ScanGuidance.multipleFaces:
        return (text: 'Pastikan hanya Anda di dalam bingkai', ready: false);
      case ScanGuidance.eyesClosed:
        return (text: 'Buka mata', ready: false);
      case ScanGuidance.holdStill:
        return (text: 'Tahan sebentar...', ready: true);
      case ScanGuidance.capturing:
        return (text: 'Mengambil foto', ready: true);
    }
  }

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
              const Icon(Icons.videocam_off_outlined,
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
    final guidance = _guidanceText;

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
          // tengah" tidak memberi tahu seberapa besar dan di mana. Warnanya
          // berubah hijau saat posisinya sudah benar — itu umpan balik yang
          // terbaca tanpa membaca.
          Center(
            child: Container(
              width: 260,
              height: 340,
              decoration: BoxDecoration(
                border: Border.all(
                  color: guidance.ready
                      ? AppColor.success
                      : Colors.white.withValues(alpha: 0.7),
                  width: guidance.ready ? 4 : 2,
                ),
                borderRadius: const BorderRadius.all(Radius.elliptical(130, 170)),
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

                // Arahan di bawah, bukan di atas oval. Mata orang yang
                // memindai wajahnya sendiri tertuju ke wajahnya di layar —
                // teks di atas oval tertutup wajahnya sendiri.
                Container(
                  margin: const EdgeInsets.all(20),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: guidance.ready
                        ? AppColor.success.withValues(alpha: 0.92)
                        : Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_guidance == ScanGuidance.capturing) ...[
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                      ] else if (guidance.ready) ...[
                        const Icon(Icons.check_circle_outline,
                            size: 18, color: Colors.white),
                        const SizedBox(width: 10),
                      ],
                      Flexible(
                        child: Text(
                          guidance.text,
                          textAlign: TextAlign.center,
                          style:
                              AppText.body.copyWith(color: Colors.white),
                        ),
                      ),
                    ],
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