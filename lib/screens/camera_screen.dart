import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:image/image.dart' as img;
import 'package:http/http.dart' as http;

class CameraScreen extends StatefulWidget {
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
      final cameras = await availableCameras();
      if (cameras.isEmpty) throw Exception('Камеры не найдены');
      _controller = CameraController(
        cameras[0],
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
      //camera
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

class ProcessingScreen extends StatefulWidget {
  final String imagePath;

  const ProcessingScreen({required this.imagePath});

  @override
  _ProcessingScreenState createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen> {
  File? _processedImage;
  String _recognizedText = 'Распознавание текста...';

  @override
  void initState() {
    super.initState();
    _processAndRecognize();
  }

  Future<void> _processAndRecognize() async {
    await _processImage();
    await _recognizeTextWithYandex();
  }

  Future<void> _processImage() async {
    print('Starting image processing...');
    final originalFile = File(widget.imagePath);
    final originalImage = img.decodeImage(await originalFile.readAsBytes());

    if (originalImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось загрузить изображение')),
      );
      return;
    }

    final grayscaleImage = img.grayscale(originalImage);
    final processedImage = img.adjustColor(grayscaleImage, contrast: 2.0);

    final tempDir = await getTemporaryDirectory();
    final processedPath = path.join(tempDir.path, 'processed_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await File(processedPath).writeAsBytes(img.encodeJpg(processedImage));

    setState(() {
      _processedImage = File(processedPath);
      print('Image processed: $processedPath');
    });
  }

  Future<void> _recognizeTextWithYandex() async {
    if (_processedImage == null) {
      print('Waiting for processed image...');
      await Future.delayed(Duration(seconds: 1));
      if (_processedImage == null) {
        setState(() {
          _recognizedText = 'Ошибка: изображение не обработано';
        });
        return;
      }
    }

    print('Starting Yandex text recognition...');
    print('Processed image path: ${_processedImage!.path}');

    const authToken = 'AQVNx9hfG-boNQz8NkB6NrFFwJFsdyYqLCJEcZd7'; // Ваш IAM-токен или API-ключ
    const folderId = 'b1gn2tj1ssb7ub3rgt5b';
    const url = 'https://ocr.api.cloud.yandex.net/ocr/v1/recognizeText';

    final imageBytes = await _processedImage!.readAsBytes();
    final base64Image = base64Encode(imageBytes);
    print('Base64 length: ${base64Image.length}');

    final requestBody = jsonEncode({
      'mimeType': 'JPEG',
      'languageCodes': ['*'],
      'model': 'page',
      'content': base64Image,
    });
    print('Request body: $requestBody');

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Api-Key $authToken', // Или 'Api-Key $authToken' для API-ключа
          'x-folder-id': folderId,
          'x-data-logging-enabled': 'true',
        },
        body: requestBody,
      ).timeout(Duration(seconds: 10));

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        String recognizedText = '';

        final result = jsonResponse['result'] as Map<String, dynamic>?;
        if (result == null) {
          setState(() {
            _recognizedText = 'Ошибка: "result" отсутствует в ответе';
          });
          return;
        }

        final textAnnotation = result['textAnnotation'] as Map<String, dynamic>?;
        if (textAnnotation == null) {
          setState(() {
            _recognizedText = 'Ошибка: "textAnnotation" отсутствует в ответе';
          });
          return;
        }

        final blocks = textAnnotation['blocks'] as List<dynamic>?;
        if (blocks != null && blocks.isNotEmpty) {
          for (var block in blocks) {
            final lines = block['lines'] as List<dynamic>?;
            if (lines != null) {
              for (var line in lines) {
                final text = line['text'] as String?;
                if (text != null) {
                  recognizedText += '$text\n';
                }
              }
            }
          }
        }
        recognizedText = utf8.decode(recognizedText.codeUnits);
        setState(() {
          _recognizedText = recognizedText.isEmpty ? 'Текст не распознан' : recognizedText.trim();
          print('Recognized text: $_recognizedText');
        });
      } else {
        setState(() {
          _recognizedText = 'Ошибка API: ${response.statusCode} - ${response.body}';
        });
      }
    } catch (e) {
      setState(() {
        _recognizedText = 'Ошибка распознавания: $e';
      });
      print('Yandex recognition error: $e');
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Обработка')),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 20),
              Text('Оригинал: ${widget.imagePath}'),
              SizedBox(height: 20),
              SizedBox(
                height: 200,
                child: Image.file(
                  File(widget.imagePath),
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Text('Ошибка загрузки оригинала: $error');
                  },
                ),
              ),
              SizedBox(height: 20),
              Text('Обработанное изображение:'),
              SizedBox(height: 20),
              SizedBox(
                height: 200,
                child: _processedImage == null
                    ? CircularProgressIndicator()
                    : Image.file(
                  _processedImage!,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Text('Ошибка загрузки обработанного: $error');
                  },
                ),
              ),
              SizedBox(height: 20),
              Text('Распознанный текст:'),
              SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: _recognizedText == 'Распознавание текста...'
                    ? CircularProgressIndicator()
                    : Text(
                  _recognizedText,
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}