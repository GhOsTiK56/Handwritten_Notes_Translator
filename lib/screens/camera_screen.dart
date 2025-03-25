import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'processing_screen.dart';

class CameraScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const CameraScreen({required this.cameras});

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  bool _isCameraReady = false;
  static const platform = MethodChannel('com.example.handwritten_notes_translator/gallery');

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      if (widget.cameras.isEmpty) throw Exception('Камеры не найдены');
      _controller = CameraController(
        widget.cameras[0],
        ResolutionPreset.max,
        enableAudio: false,
      );
      await _controller!.initialize();
      await _controller!.setFlashMode(FlashMode.off);
      if (!mounted) return;
      setState(() => _isCameraReady = true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка камеры: $e')),
      );
    }
  }

  @override
  void dispose() {
    _controller?.setFlashMode(FlashMode.off);
    _controller?.dispose();
    super.dispose();
  }

  Future<String> _takePicture() async {
    if (!_controller!.value.isInitialized || _controller!.value.isTakingPicture) {
      throw Exception('Камера не готова');
    }
    await _controller!.setFlashMode(FlashMode.off);
    final XFile photo = await _controller!.takePicture();

    final tempDir = await getTemporaryDirectory();
    final tempPath = path.join(tempDir.path, 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await photo.saveTo(tempPath);

    final fileName = 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
    try {
      final String? galleryPath = await platform.invokeMethod('saveToGallery', {
        'path': tempPath,
        'fileName': fileName,
      });
      if (galleryPath == null) throw Exception('Не удалось сохранить в галерею');

      await File(tempPath).delete();
      return galleryPath;
    } catch (e) {
      throw Exception('Ошибка сохранения: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraReady || _controller == null) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: Text('Сфотографируйте заметку')),
      body: CameraPreview(_controller!),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          try {
            final imagePath = await _takePicture();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Фото сохранено в галерее: $imagePath')),
            );
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProcessingScreen(imagePath: imagePath),
              ),
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Ошибка съемки: $e')),
            );
          }
        },
        child: Icon(Icons.camera),
      ),
    );
  }
}