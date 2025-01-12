import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tflite/tflite.dart';

class CatDetector{
  Future<void> loadModel() async {
    await Tflite.loadModel(
      model: 'assets/model_unquant.tflite',
      labels: 'assets/labels.txt',
    );
  }

  Future<List?> detectImage(String assetPath) async {
    final ByteData imageData = await rootBundle.load(assetPath);
    final Uint8List imageBytes = imageData.buffer.asUint8List();

    final directory = await getTemporaryDirectory();
    final tempFile = File('${directory.path}/image.jpg');
    await tempFile.writeAsBytes(imageBytes);

    var predictions = await Tflite.runModelOnImage(
      path: tempFile.path,
      numResults: 2,
      threshold: 0.6,
      imageMean: 127.5,
      imageStd: 127.5,
    );

    return predictions;
  }

  void dispose() {
    Tflite.close();
  }
}
