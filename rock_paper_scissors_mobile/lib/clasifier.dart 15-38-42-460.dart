import 'dart:typed_data';
import 'package:rock_paper_scissors_mobile/classes.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class Classifier {
  /// Instance of Interpreter
  late Interpreter _interpreter;

  static const String modelFile = "model_val_acc_0.71.tflite";

  /// Loads interpreter from asset
  Future<void> loadModel({Interpreter? interpreter}) async {
    try {
      _interpreter = interpreter ??
          await Interpreter.fromAsset(
            modelFile,
            options: InterpreterOptions()..threads = 4,
          );

      _interpreter.allocateTensors();
    } catch (e) {
      print("Error while creating interpreter: $e");
    }
  }

  /// Gets the interpreter instance
  Interpreter get interpreter => _interpreter;

  Future<DetectionClasses> predict(
      Uint8List imageBytes, int width, int height) async {
    // Assuming image is already resized to 150x150
    // Convert the resized image to a 1D Float32List.
    Float32List inputBytes = Float32List(1 * 150 * 150 * 3);
    int pixelIndex = 0;
    print(imageBytes.length);
    for (int i = 0; i < imageBytes.length - 2; i += 4) {
      //)
      inputBytes[pixelIndex++] = (imageBytes[i] / 127.5) - 1.0;
      inputBytes[pixelIndex++] = (imageBytes[i + 1] / 127.5) - 1.0;
      inputBytes[pixelIndex++] = (imageBytes[i + 2] / 127.5) - 1.0;
    }

    final output = Float32List(1 * 4).reshape([1, 4]);

    // Reshape to input format specific for model. 1 item in list with pixels 150x150 and 3 layers for RGB
    final input = inputBytes.reshape([1, 150, 150, 3]);

    interpreter.run(input, output);

    final predictionResult = output[0] as List<double>;
    double maxElement = predictionResult.reduce(
      (double maxElement, double element) =>
          element > maxElement ? element : maxElement,
    );
    print('-------' * 50);

    print(predictionResult.indexOf(maxElement));
    print('-------' * 50);
    print(predictionResult);
    print('-------' * 50);

    return DetectionClasses.values[predictionResult.indexOf(maxElement)];
  }
}
