import 'dart:io';
import 'package:flutter/material.dart';
import '../services/image_processor.dart';
import '../services/yandex_ocr_service.dart';
import '../models/history_item.dart';
import 'text_result_screen.dart';

class ProcessingScreen extends StatefulWidget {
  final String imagePath;

  const ProcessingScreen({required this.imagePath});

  @override
  _ProcessingScreenState createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen> {
  File? _processedImage;
  String? _recognizedText;

  @override
  void initState() {
    super.initState();
    _processAndRecognize();
  }

  Future<void> _processAndRecognize() async {
    _processedImage = await ImageProcessor.processImage(widget.imagePath);
    if (_processedImage != null) {
      _recognizedText = await YandexOcrService.recognizeText(_processedImage!);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Обработка'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Image.file(
                      File(widget.imagePath),
                      fit: BoxFit.cover,
                    ),
                  ),
                  if (_processedImage != null)
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Image.file(
                        _processedImage!,
                        fit: BoxFit.cover,
                      ),
                    )
                  else
                    Center(child: CircularProgressIndicator()),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _recognizedText != null
                  ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TextResultScreen(
                      text: _recognizedText!,
                      originalImagePath: widget.imagePath,
                      processedImagePath: _processedImage!.path,
                    ),
                  ),
                );
              }
                  : null,
              child: Text('Посмотреть текст'),
            ),
          ),
        ],
      ),
    );
  }
}