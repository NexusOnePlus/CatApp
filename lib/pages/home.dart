import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<File> pickImages = [];
  List<String> saveImages = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    imageLoad();
  }

  Future<void> requestPermission() async {
    // Solicitar múltiples permisos
    Map<Permission, PermissionStatus> statuses = await [
      Permission.storage,
      Permission.manageExternalStorage, // Necesario para Android 11+
    ].request();

    if (statuses[Permission.storage]!.isGranted || 
        statuses[Permission.manageExternalStorage]!.isGranted) {
      await imagePicker();
    } else {
      // Mostrar un diálogo explicativo
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Permisos necesarios'),
            content: const Text('Esta app necesita permisos de almacenamiento para acceder a tus imágenes.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> imageLoad() async {
    try {
      setState(() => isLoading = true);
      final prefs = await SharedPreferences.getInstance();
      final savedPaths = prefs.getStringList('saveImages') ?? [];
      final savedFolders = prefs.getStringList('savedFolderF') ?? [];

      // Verificar que los archivos aún existen
      final existingFiles = savedPaths
          .map((path) => File(path))
          .where((file) => file.existsSync())
          .toList();

      setState(() {
        pickImages = existingFiles;
        saveImages = savedFolders;
      });
    } catch (e) {
      debugPrint('Error cargando imágenes: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> imageSave() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
          'saveImages', pickImages.map((file) => file.path).toList());
      await prefs.setStringList('savedFolderF', saveImages);
    } catch (e) {
      debugPrint('Error guardando imágenes: $e');
    }
  }

  Future<void> imagePicker() async {
    try {
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
      if (selectedDirectory != null && !saveImages.contains(selectedDirectory)) {
        setState(() => isLoading = true);
        
        final directory = Directory(selectedDirectory);
        final imageExtensions = ['.jpg', '.jpeg', '.png', '.webp'];
        
        final images = directory
            .listSync(recursive: true)
            .where((file) =>
                file is File &&
                imageExtensions.any((ext) => file.path.toLowerCase().endsWith(ext)))
            .map((file) => File(file.path))
            .toList();

        setState(() {
          pickImages.addAll(images);
          saveImages.add(selectedDirectory);
        });
        
        await imageSave();
      }
    } catch (e) {
      debugPrint('Error seleccionando imágenes: $e');
    } finally {
      setState(() => isLoading = false);
    }
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
          ElevatedButton(
            onPressed: requestPermission,
            child: const Text('Seleccionar Carpeta'),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : pickImages.isNotEmpty
                    ? GridView.builder(
                        padding: const EdgeInsets.all(10),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: pickImages.length,
                        itemBuilder: (context, index) {
                          return Image.file(
                            pickImages[index],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Icon(Icons.error),
                              );
                            },
                          );
                        },
                      )
                    : const Center(child: Text('No hay imágenes seleccionadas')),
          ),
        ],
      ),
    );
  }
}