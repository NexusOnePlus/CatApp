import 'dart:io';
import 'package:cat_app/models/catdetector.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image/image.dart' as img;

class PermissionManager {
  static Future<bool> requestPermissions(BuildContext context) async {
    if (Platform.isAndroid) {
      return _requestAndroidPermissions(context);
    }
    return true; // Para otras plataformas
  }

  static Future<bool> _requestAndroidPermissions(BuildContext context) async {
    final androidInfo = await DeviceInfoPlugin().androidInfo;

    if (androidInfo.version.sdkInt >= 33) {
      final status = await Permission.photos.request();
      if (!status.isGranted) {
        if (context.mounted) {
          await showPermissionDialog(context);
        }
        return false;
      }
      return true;
    } else {
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        if (context.mounted) {
          await showPermissionDialog(context);
        }
        return false;
      }
      return true;
    }
  }

  static Future<void> showPermissionDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Permiso necesario'),
        content: const Text(
            'Esta aplicación necesita acceso a tus fotos para poder detectar gatos. '
            'Por favor, concede el permiso en la configuración.'),
        actions: <Widget>[
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text('Abrir Configuración'),
            onPressed: () {
              openAppSettings();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<File> _pickImages = [];
  final List<String> _saveImages = [];
  bool _isLoading = false;
  final CatDetector _catDetector = CatDetector();

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await _initializeDetector();
    await _loadSavedImages();
  }

  @override
  void dispose() {
    _catDetector.dispose();
    super.dispose();
  }

  Future<void> _initializeDetector() async {
    await _catDetector.loadModel();
  }

  Future<File> _convertWebpToPng(File webpFile) async {
    final bytes = await webpFile.readAsBytes();
    final image = img.decodeWebP(bytes);
    final tempDir = await getTemporaryDirectory();
    final pngPath =
        '${tempDir.path}/${webpFile.uri.pathSegments.last.replaceAll('.webp', '.png')}';
    final pngFile = File(pngPath)..writeAsBytesSync(img.encodePng(image!));
    return pngFile;
  }

  Future<bool> _isCatImage(File imageFile) async {
    try {
      if (!await imageFile.exists()) {
        debugPrint('Archivo no existe: ${imageFile.path}');
        return false;
      }

      final predictions = await _catDetector.detectImage(imageFile);
      return predictions?.any((pred) =>
              pred['label'].toString().toLowerCase().contains('cat') &&
              (pred['confidence'] as double) > 0.6) ??
          false;
    } catch (e) {
      debugPrint('Error procesando imagen ${imageFile.path}: $e');
      return false;
    }
  }

  Future<void> _loadSavedImages() async {
    try {
      setState(() => _isLoading = true);

      final prefs = await SharedPreferences.getInstance();
      final savedPaths = prefs.getStringList('saveImages') ?? [];
      final savedFolders = prefs.getStringList('savedFolderF') ?? [];

      final existingFiles = savedPaths
          .map((path) => File(path))
          .where((file) => file.existsSync())
          .toList();

      setState(() {
        _pickImages.clear();
        _pickImages.addAll(existingFiles);
        _saveImages.clear();
        _saveImages.addAll(savedFolders);
      });
    } catch (e) {
      debugPrint('Error cargando imágenes: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveImagesList() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
          'saveImages', _pickImages.map((file) => file.path).toList());
      await prefs.setStringList('savedFolderF', _saveImages);
    } catch (e) {
      debugPrint('Error guardando imágenes: $e');
    }
  }

  Future<void> _pickImagesFromDirectory() async {
    if (!await PermissionManager.requestPermissions(context)) {
      return;
    }

    try {
      final selectedDirectory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Selecciona una carpeta con imágenes',
      );

      if (selectedDirectory != null &&
          !_saveImages.contains(selectedDirectory)) {
        setState(() => _isLoading = true);

        final directory = Directory(selectedDirectory);
        final List<FileSystemEntity> entities = await directory.list().toList();

        final imageFiles = entities
            .whereType<File>()
            .where((file) =>
                file.path.toLowerCase().endsWith('.jpg') ||
                file.path.toLowerCase().endsWith('.jpeg') ||
                file.path.toLowerCase().endsWith('.png'))
            .toList();

        for (final file in imageFiles) {
          if (await _isCatImage(File(file.path))) {
            setState(() {
              _pickImages.add(File(file.path));
            });
          }
        }

        setState(() {
          _saveImages.add(selectedDirectory);
        });

        await _saveImagesList();
      }
    } catch (e) {
      debugPrint('Error en selección de imágenes: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

 void _showImageOverlay(File imageFile) {
  showDialog(
    context: context,
    barrierDismissible: true, // Cierra al tocar fuera
    builder: (_) => Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Imagen con ajuste
              AspectRatio(
                aspectRatio: 1,
                child: Image.file(
                  imageFile,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 10),
              
              // Nombre del archivo
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Nombre: ${imageFile.uri.pathSegments.last}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 10),
              
              // Botón de copiar con icono
              TextButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: imageFile.path));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Ruta copiada al portapapeles'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.copy),
                label: const Text('Copiar Ruta'),
              ),
              
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    ),
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'CatApp',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: _pickImagesFromDirectory,
              child: const Text('Seleccionar Carpeta'),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Analizando imágenes...'),
                      ],
                    ),
                  )
                : _pickImages.isNotEmpty
                    ? GridView.builder(
                        padding: const EdgeInsets.all(10),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: _pickImages.length,
                        itemBuilder: (context, index) => GestureDetector(
                          onTap: () => _showImageOverlay(_pickImages[index]),
                          child:
                              Image.file(_pickImages[index], fit: BoxFit.cover),
                        ),
                      )
                    : const Center(
                        child: Text('No hay imágenes de gatos seleccionadas')),
          ),
        ],
      ),
    );
  }
}
