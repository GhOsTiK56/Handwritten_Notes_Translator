import 'dart:io';
import 'package:flutter/material.dart';
import '../services/image_processor.dart';
import '../services/yandex_ocr_service.dart';

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
    _processedImage = await ImageProcessor.processImage(widget.imagePath);
    if (_processedImage == null) {
      setState(() {
        _recognizedText = 'Ошибка обработки изображения';
      });
      return;
    }
    setState(() {}); // Обновляем UI с обработанным изображением

    final text = await YandexOcrService.recognizeText(_processedImage!);
    setState(() {
      _recognizedText = text;
    });
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