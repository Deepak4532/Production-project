import 'dart:io';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class PillRecognitionService {
  static final PillRecognitionService _instance =
      PillRecognitionService._internal();

  late Interpreter _interpreter;
  bool _isInitialized = false;

  // Class labels (5 medications - optimized for high accuracy)
  static const List<String> classLabels = [
    'Hydrochlorothiazide 25 MG',
    'Hydrochlorothiazide 50 MG',
    'Sertraline 50 MG',
    'Pantoprazole 40 MG',
    'Lisinopril 5 MG',
  ];

  PillRecognitionService._internal();

  factory PillRecognitionService() => _instance;

  /// Initialize the TFLite interpreter
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _interpreter = await Interpreter.fromAsset(
        'assets/models/pill_recognition_model.tflite',
      );
      _isInitialized = true;
      print('✓ Pill Recognition Model initialized successfully');
    } catch (e) {
      print('✗ Error initializing model: $e');
      rethrow;
    }
  }

  /// Preprocess image to 224x224 and normalize
  List<List<List<List<double>>>> _preprocessImage(img.Image image) {
    // Resize to 224x224
    final resized = img.copyResize(image, width: 224, height: 224);

    // Create 4D tensor [1, 224, 224, 3]
    final List<List<List<List<double>>>> tensor = List.generate(
      1,
      (_) => List.generate(
        224,
        (y) => List.generate(
          224,
          (x) {
            final pixel = resized.getPixelSafe(x, y);
            return [
              pixel.r.toInt() / 255.0,
              pixel.g.toInt() / 255.0,
              pixel.b.toInt() / 255.0,
            ];
          },
          growable: false,
        ),
        growable: false,
      ),
      growable: false,
    );

    return tensor;
  }

  /// Recognize pill from image file
  Future<PillRecognitionResult> recognizePill(File imageFile) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // Read and decode image
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Preprocess
      final tensor = _preprocessImage(image);

      // Run inference - output shape: [1, 5]
      final output = List<List<double>>.filled(
        1,
        List<double>.filled(5, 0.0),
      );

      _interpreter.run(tensor, output);

      // Extract predictions
      final predictions = output[0];

      // Create prediction objects
      final results = <PillPrediction>[];
      for (int i = 0; i < predictions.length && i < classLabels.length; i++) {
        results.add(
          PillPrediction(
            medicationName: classLabels[i],
            confidence: predictions[i],
            index: i,
          ),
        );
      }

      // Sort by confidence (descending)
      results.sort((a, b) => b.confidence.compareTo(a.confidence));

      return PillRecognitionResult(
        topPrediction: results[0],
        allPredictions: results,
      );
    } catch (e) {
      print('✗ Error recognizing pill: $e');
      rethrow;
    }
  }

  /// Close interpreter and free resources
  void close() {
    if (_isInitialized) {
      _interpreter.close();
      _isInitialized = false;
    }
  }

  bool get isInitialized => _isInitialized;
}

/// Single pill prediction
class PillPrediction {
  final String medicationName;
  final double confidence;
  final int index;

  PillPrediction({
    required this.medicationName,
    required this.confidence,
    required this.index,
  });

  String get percentage => '${(confidence * 100).toStringAsFixed(2)}%';

  @override
  String toString() => '$medicationName: $percentage';
}

/// Complete recognition result
class PillRecognitionResult {
  final PillPrediction topPrediction;
  final List<PillPrediction> allPredictions;

  PillRecognitionResult({
    required this.topPrediction,
    required this.allPredictions,
  });

  /// Get top 3 predictions
  List<PillPrediction> get topThree => allPredictions.take(3).toList();

  @override
  String toString() => '''
🔍 Pill Recognition Result:
   Top Match: ${topPrediction.medicationName} (${topPrediction.percentage})
   Confidence: ${(topPrediction.confidence * 100).toStringAsFixed(1)}%
   Top 3: ${topThree.map((p) => p.medicationName).join(', ')}
   ''';
}
