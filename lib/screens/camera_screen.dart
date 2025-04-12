import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
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
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (!_controller!.value.isInitialized || _controller!.value.isTakingPicture) return;
    final XFile photo = await _controller!.takePicture();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProcessingScreen(imagePath: photo.path)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraReady || _controller == null) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      body: Stack(
        children: [
          CameraPreview(_controller!),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.all(20),
              child: FloatingActionButton(
                onPressed: _takePicture,
                child: Icon(Icons.camera),
              ),
            ),
          ),
        ],
      ),
    );
  }
}