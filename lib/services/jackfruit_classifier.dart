import 'dart:io';
// import 'dart:math';

import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class JackfruitClassifier {
  Interpreter? _interpreter;
  List<String> _labels = [];
  bool _loaded = false;

  bool get isLoaded => _loaded;

  /// Load model + labels
  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset(
        "assets/models/model_unquant.tflite",
      );

      final rawLabels = await rootBundle.loadString("assets/models/labels.txt");

      _labels = rawLabels
          .split("\n")
          .where((l) => l.trim().isNotEmpty)
          .map((l) => l.split(" ").last.trim())
          .toList();

      _loaded = true;
    } catch (e) {
      print("🔥 Lỗi load model: $e");
    }
  }

  /// Chạy phân loại trái mít
  Future<Map<String, dynamic>> classify(File imageFile) async {
    if (!_loaded) {
      return {"label": "Model chưa load", "confidence": 0.0};
    }

    // Decode ảnh
    final bytes = await imageFile.readAsBytes();
    img.Image? oriImage = img.decodeImage(bytes);

    if (oriImage == null) {
      return {"label": "Không đọc được ảnh", "confidence": 0.0};
    }

    // Resize về 224x224
    const int inputSize = 224;
    final resized = img.copyResize(
      oriImage,
      width: inputSize,
      height: inputSize,
    );

    // Chuẩn bị input tensor [1, 224, 224, 3]
    var input = List.generate(
      1,
      (_) => List.generate(
        inputSize,
        (y) => List.generate(inputSize, (x) {
          // PixelRGBA theo image v4
          final pixel = resized.getPixel(x, y);

          final r = pixel.r.toDouble() / 255.0;
          final g = pixel.g.toDouble() / 255.0;
          final b = pixel.b.toDouble() / 255.0;

          return [r, g, b];
        }),
      ),
    );

    // Output buffer [1, num_classes]
    final output = [List<double>.filled(_labels.length, 0.0)];

    // Run model
    _interpreter!.run(input, output);

    final scores = output[0];
    double maxScore = -999;
    int maxIdx = 0;

    for (int i = 0; i < scores.length; i++) {
      if (scores[i] > maxScore) {
        maxScore = scores[i];
        maxIdx = i;
      }
    }

    return {"label": _labels[maxIdx], "confidence": maxScore};
  }
}
