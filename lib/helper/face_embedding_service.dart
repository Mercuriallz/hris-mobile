import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

/// Versi model. WAJIB dikirim bersama embedding.
///
/// Backend menyimpan versi ini saat pendaftaran dan membandingkannya saat
/// absensi. Embedding dari model berbeda menghasilkan angka yang terlihat
/// masuk akal tapi artinya kosong — jenis kesalahan yang paling berbahaya,
/// karena tidak terlihat seperti kesalahan.
///
/// UBAH INI setiap kali berkas modelnya diganti. Kalau lupa, seluruh karyawan
/// gagal cocok tanpa ada yang tahu penyebabnya.
const String kFaceModelVersion = 'mobilefacenet-v1';

const String _modelAsset = 'assets/models/mobilefacenet.tflite';

/// Kenapa perhitungan embedding gagal.
///
/// Dibedakan karena tindak lanjutnya berbeda: wajah tidak terdeteksi berarti
/// fotonya perlu diulang, sementara model gagal dimuat berarti aplikasinya
/// bermasalah dan mengulang foto tidak menolong.
enum FaceFailureReason {
  noFace,
  multipleFaces,
  faceTooSmall,
  modelUnavailable,
  processingFailed,
}

class FaceFailure implements Exception {
  final FaceFailureReason reason;
  final String message;

  const FaceFailure(this.reason, this.message);

  @override
  String toString() => message;
}

/// Menghitung embedding wajah di HP.
///
/// Dipilih di HP, bukan di server: menghitungnya di sini sekitar 100–200 ms,
/// sementara mengunggah foto lalu memprosesnya di server beberapa detik — dan
/// orangnya berdiri di depan pintu selama itu.
///
/// Fotonya TIDAK pernah dikirim ke server. Yang keluar dari HP cuma deret
/// angka hasil perhitungan ini.
class FaceEmbeddingService {
  FaceEmbeddingService._();
  static final FaceEmbeddingService instance = FaceEmbeddingService._();

  Interpreter? _interpreter;
  FaceDetector? _detector;

  int _inputSize = 112;
  int _outputSize = 192;

  /// Memuat model sekali, lalu dipakai berulang.
  ///
  /// Memuat interpreter memakan ratusan milidetik. Kalau dimuat setiap kali
  /// tombol ditekan, clock in terasa tersendat justru di saat orangnya paling
  /// tidak sabar.
  Future<void> _ensureReady() async {
    if (_interpreter != null && _detector != null) return;

    try {
      _interpreter ??= await Interpreter.fromAsset(_modelAsset);

      // Bentuk masukan dan keluaran dibaca DARI MODEL, tidak ditulis di kode.
      //
      // Dengan begitu mengganti model dengan yang dimensinya berbeda — 128
      // alih-alih 192 — tidak perlu mengubah apa pun di sini. Angka yang
      // ditulis di kode dan tidak cocok dengan modelnya menghasilkan
      // pembacaan memori yang salah, bukan pesan kesalahan.
      final inputShape = _interpreter!.getInputTensor(0).shape;
      final outputShape = _interpreter!.getOutputTensor(0).shape;

      _inputSize = inputShape[1];
      _outputSize = outputShape[1];

      debugPrint(
        'Model wajah siap: masukan $_inputSize x $_inputSize, keluaran $_outputSize',
      );
    } catch (e) {
      debugPrint('Gagal memuat model wajah: $e');
      throw const FaceFailure(
        FaceFailureReason.modelUnavailable,
        'Model pengenalan wajah tidak bisa dimuat. Perbarui aplikasi atau hubungi HR.',
      );
    }

    _detector ??= FaceDetector(
      options: FaceDetectorOptions(
        // Akurat, bukan cepat. Bedanya sekitar 100 ms, dan salah memotong
        // wajah jauh lebih mahal daripada seratus milidetik.
        performanceMode: FaceDetectorMode.accurate,

        // Landmark dan klasifikasi tidak dipakai — mematikannya menghemat
        // waktu dan memori.
        enableLandmarks: false,
        enableClassification: false,
        enableTracking: false,

        // Wajah yang lebih kecil dari 15% tinggi gambar diabaikan. Itu
        // menyaring orang di latar belakang tanpa perlu memeriksanya satu
        // per satu.
        minFaceSize: 0.15,
      ),
    );
  }

  /// Menghitung embedding dari sebuah berkas foto.
  ///
  /// Melempar [FaceFailure] kalau wajahnya tidak bisa dipakai. Tidak pernah
  /// mengembalikan embedding yang meragukan — embedding dari foto tanpa wajah
  /// tetap berupa deret angka, dan angka itu akan dibandingkan seolah-olah
  /// berarti sesuatu.
  Future<List<double>> embedFromFile(String path) async {
    await _ensureReady();

    final face = await _detectSingleFace(path);
    final bytes = await File(path).readAsBytes();

    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw const FaceFailure(
        FaceFailureReason.processingFailed,
        'Foto tidak bisa dibaca. Coba ambil ulang.',
      );
    }

    final cropped = _cropFace(decoded, face);
    final resized = img.copyResize(
      cropped,
      width: _inputSize,
      height: _inputSize,
      interpolation: img.Interpolation.linear,
    );

    return _runModel(resized);
  }

  /// Mendeteksi tepat satu wajah.
  ///
  /// Nol wajah dan dua wajah keduanya ditolak, dengan pesan yang berbeda.
  /// Dua wajah di swafoto absensi berarti ada orang lain di belakang — dan
  /// memilih yang terbesar berarti sistem menebak siapa yang seharusnya
  /// diperiksa.
  Future<Face> _detectSingleFace(String path) async {
    final faces = await _detector!.processImage(InputImage.fromFilePath(path));

    if (faces.isEmpty) {
      throw const FaceFailure(
        FaceFailureReason.noFace,
        'Wajah tidak terdeteksi. Pastikan wajah menghadap kamera dan cahayanya cukup.',
      );
    }

    if (faces.length > 1) {
      throw const FaceFailure(
        FaceFailureReason.multipleFaces,
        'Terdeteksi lebih dari satu wajah. Pastikan hanya Anda yang ada di foto.',
      );
    }

    return faces.first;
  }

  /// Memotong bagian wajah dengan sedikit margin.
  ///
  /// Pemotongan ini yang paling menentukan ketepatannya. Tanpa memotong,
  /// latar belakang ikut masuk perhitungan dan dua foto orang yang sama di
  /// tempat berbeda bisa terbaca sebagai dua orang.
  ///
  /// Margin 20% karena model wajah dilatih dengan potongan yang menyertakan
  /// sedikit dahi dan dagu. Potongan yang terlalu rapat menghilangkan bagian
  /// yang justru dipakai membedakan.
  img.Image _cropFace(img.Image source, Face face) {
    final box = face.boundingBox;

    final marginX = box.width * 0.20;
    final marginY = box.height * 0.20;

    final left = (box.left - marginX).clamp(0, source.width - 1).toInt();
    final top = (box.top - marginY).clamp(0, source.height - 1).toInt();
    final right =
        (box.right + marginX).clamp(left + 1, source.width).toInt();
    final bottom =
        (box.bottom + marginY).clamp(top + 1, source.height).toInt();

    final width = right - left;
    final height = bottom - top;

    // Wajah yang terlalu kecil ditolak. Memperbesar potongan 40 piksel jadi
    // 112 menghasilkan gambar buram, dan embedding dari gambar buram
    // berbeda jauh dari embedding wajah yang sama diambil dekat.
    if (width < 60 || height < 60) {
      throw const FaceFailure(
        FaceFailureReason.faceTooSmall,
        'Wajah terlalu jauh dari kamera. Dekatkan wajah lalu coba lagi.',
      );
    }

    return img.copyCrop(
      source,
      x: left,
      y: top,
      width: width,
      height: height,
    );
  }

  /// Menjalankan model dan menormalkan hasilnya.
  List<double> _runModel(img.Image face) {
    // Piksel dinormalkan ke rentang -1 sampai 1 dengan (x - 127.5) / 128.
    //
    // Itu normalisasi yang dipakai MobileFaceNet saat dilatih. Normalisasi
    // yang berbeda menghasilkan embedding yang tetap berupa angka tapi
    // kemiripannya tidak lagi berarti apa pun.
    final input = List.generate(
      1,
      (_) => List.generate(
        _inputSize,
        (y) => List.generate(_inputSize, (x) {
          final pixel = face.getPixel(x, y);
          return [
            (pixel.r - 127.5) / 128.0,
            (pixel.g - 127.5) / 128.0,
            (pixel.b - 127.5) / 128.0,
          ];
        }),
      ),
    );

    final output = List.generate(1, (_) => List.filled(_outputSize, 0.0));

    try {
      _interpreter!.run(input, output);
    } catch (e) {
      debugPrint('Model wajah gagal dijalankan: $e');
      throw const FaceFailure(
        FaceFailureReason.processingFailed,
        'Wajah gagal diproses. Coba ambil ulang fotonya.',
      );
    }

    return _l2Normalize(output[0]);
  }

  /// Menormalkan panjang vektor jadi 1.
  ///
  /// Kemiripan kosinus di backend sudah mengabaikan panjangnya, jadi ini
  /// bukan syarat. Tapi vektor yang panjangnya seragam membuat skornya
  /// sebanding antar perangkat — dan itu penting saat mengalibrasi ambangnya.
  List<double> _l2Normalize(List<double> vector) {
    var sum = 0.0;
    for (final v in vector) {
      sum += v * v;
    }

    final norm = math.sqrt(sum);
    if (norm == 0) {
      throw const FaceFailure(
        FaceFailureReason.processingFailed,
        'Hasil perhitungan tidak sah. Coba ambil ulang fotonya.',
      );
    }

    return vector.map((v) => v / norm).toList();
  }

  /// Dilepas saat aplikasi ditutup, bukan setelah setiap pemakaian.
  Future<void> dispose() async {
    _interpreter?.close();
    _interpreter = null;

    await _detector?.close();
    _detector = null;
  }
}

/// Menghapus berkas foto sementara.
///
/// Fotonya tidak disimpan di mana pun — tidak di server, tidak di HP. Yang
/// keluar cuma embedding-nya. Berkas sementara dari kamera perlu dihapus
/// sendiri karena sistem tidak selalu membersihkannya.
Future<void> deleteTempPhoto(String path) async {
  try {
    final file = File(path);
    if (await file.exists()) await file.delete();
  } catch (e) {
    // Gagal menghapus bukan alasan menggagalkan absensi. Dicatat saja.
    debugPrint('Foto sementara gagal dihapus: $e');
  }
}

/// Dipakai memeriksa panjang embedding sebelum dikirim.
///
/// Backend menolak yang di luar 64–1024, dan pesan penolakannya tidak
/// menjelaskan apa yang harus dilakukan pengguna. Lebih baik ditangkap di
/// sini.
bool isPlausibleEmbedding(List<double> embedding) =>
    embedding.length >= 64 &&
    embedding.length <= 1024 &&
    embedding.every((v) => v.isFinite);

/// Dipakai debugging: dua embedding dari orang yang sama harus di atas 0,65.
@visibleForTesting
double cosineSimilarity(List<double> a, List<double> b) {
  if (a.length != b.length) return 0;

  var dot = 0.0;
  var na = 0.0;
  var nb = 0.0;

  for (var i = 0; i < a.length; i += 1) {
    dot += a[i] * b[i];
    na += a[i] * a[i];
    nb += b[i] * b[i];
  }

  if (na == 0 || nb == 0) return 0;
  return dot / (math.sqrt(na) * math.sqrt(nb));
}

/// Float32List dipakai kalau nanti model butuh masukan rata.
///
/// Belum dipakai — MobileFaceNet menerima bentuk bersarang. Disimpan karena
/// beberapa model lain menuntut bentuk ini, dan mengubahnya nanti berarti
/// menulis ulang normalisasinya.
@visibleForTesting
Float32List flattenPixels(img.Image image, int size) {
  final buffer = Float32List(size * size * 3);
  var i = 0;

  for (var y = 0; y < size; y += 1) {
    for (var x = 0; x < size; x += 1) {
      final pixel = image.getPixel(x, y);
      buffer[i++] = (pixel.r - 127.5) / 128.0;
      buffer[i++] = (pixel.g - 127.5) / 128.0;
      buffer[i++] = (pixel.b - 127.5) / 128.0;
    }
  }

  return buffer;
}