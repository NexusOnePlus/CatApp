import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:tflite/tflite.dart';

class CatDetector {
  Future<void> loadModel() async {
    await Tflite.loadModel(
      model: 'assets/model_unquant.tflite',
      labels: 'assets/labels.txt',
    );
  }

  Future<List?> detectImage(File imageFile) async {
    try {
      var predictions = await Tflite.runModelOnImage(
        path: imageFile.path,
        numResults: 4,
        threshold: 0.6,
        imageMean: 127.5,
        imageStd: 127.5,
      );
      return predictions;
    } catch (e) {
      debugPrint('Error al procesar imagen: $e');
      return null;
    }
  }

  void dispose() {
    Tflite.close();
  }
}