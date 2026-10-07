import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';


const String kFaceModelVersion = 'mobilefacenet-v1';

const String _modelAsset = 'assets/models/mobilefacenet.tflite';

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


class FaceEmbeddingService {
  FaceEmbeddingService._();
  static final FaceEmbeddingService instance = FaceEmbeddingService._();

  Interpreter? _interpreter;
  FaceDetector? _detector;

  int _inputSize = 112;
  int _outputSize = 192;

  Future<void> _ensureReady() async {
    if (_interpreter != null && _detector != null) return;

    try {
      _interpreter ??= await Interpreter.fromAsset(_modelAsset);

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
 
        performanceMode: FaceDetectorMode.accurate,


        enableLandmarks: false,
        enableClassification: false,
        enableTracking: false,


        minFaceSize: 0.15,
      ),
    );
  }

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

  List<double> _runModel(img.Image face) {

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

  Future<void> dispose() async {
    _interpreter?.close();
    _interpreter = null;

    await _detector?.close();
    _detector = null;
  }
}


Future<void> deleteTempPhoto(String path) async {
  try {
    final file = File(path);
    if (await file.exists()) await file.delete();
  } catch (e) {
    debugPrint('Foto sementara gagal dihapus: $e');
  }
}

bool isPlausibleEmbedding(List<double> embedding) =>
    embedding.length >= 64 &&
    embedding.length <= 1024 &&
    embedding.every((v) => v.isFinite);

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