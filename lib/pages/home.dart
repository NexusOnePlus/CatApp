import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tflite/tflite.dart';
class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState(); // Removido el asterisco
}

class _HomeState extends State<Home> { // Removido el asterisco
  bool loading = true; // Removido el asterisco
  List output = []; // Removido late y asterisco

  @override
  void initState() {
    super.initState();
    loadModel().then((_) {
      detectImageFromAssets();
    });
  }

  loadModel() async {
    await Tflite.loadModel(
      model: 'assets/model_unquant.tflite',
      labels: 'assets/labels.txt'
    );
  }

  detectImageFromAssets() async {
    final ByteData imageData = await rootBundle.load('assets/perro1.jpg');
    final Uint8List imageBytes = imageData.buffer.asUint8List();

    final directory = await getTemporaryDirectory();
    final tempFile = File('${directory.path}/perro1.jpg');
    print("la ruta de la imagen es ${tempFile.path}");
    await tempFile.writeAsBytes(imageBytes);

    var predictions = await Tflite.runModelOnImage(
      path: tempFile.path,
      numResults: 2,
      threshold: 0.6,
      imageMean: 127.5,
      imageStd: 127.5,
    );

    setState(() {
      output = predictions ?? [];
      loading = false;
    });

    if (output.isNotEmpty) {
      String label = output[0]["label"];
      print("Resultado: $label");
      if (label.toLowerCase().contains("cat")) {
        print("✅ Es un gato! 🐱");
      } else {
        print("❌ No es un gato.");
      }
    }
  }

  @override
  void dispose() {
    Tflite.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'CatApp',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
      ),
    );
  }
}