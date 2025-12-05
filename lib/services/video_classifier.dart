import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class VideoJackfruitClassifier {
  Interpreter? _interpreter;
  List<String> _labels = [];
  bool _loaded = false;

  bool get isLoaded => _loaded;

  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset(
        "assets/models/model_unquant.tflite",
      );

      final raw = await rootBundle.loadString("assets/models/labels.txt");

      _labels = raw
          .split("\n")
          .where((e) => e.trim().isNotEmpty)
          .map((e) => e.split(" ").last.trim())
          .toList();

      _loaded = true;
    } catch (e) {
      print("🔥 Lỗi load model video: $e");
    }
  }

  /// Dành cho Video/Webcam → input là 1 frame (img.Image)
  Future<Map<String, double>> predictFrame(img.Image frame) async {
    if (!_loaded) return {};

    const int inputSize = 224;

    final resized = img.copyResize(frame, width: inputSize, height: inputSize);

    var input = List.generate(
      1,
      (_) => List.generate(
        inputSize,
        (y) => List.generate(inputSize, (x) {
          final p = resized.getPixel(x, y);
          return [p.r / 255.0, p.g / 255.0, p.b / 255.0];
        }),
      ),
    );

    final output = [List<double>.filled(_labels.length, 0.0)];

    _interpreter!.run(input, output);

    Map<String, double> result = {};
    for (int i = 0; i < _labels.length; i++) {
      result[_labels[i]] = output[0][i];
    }

    return result;
  }
}
