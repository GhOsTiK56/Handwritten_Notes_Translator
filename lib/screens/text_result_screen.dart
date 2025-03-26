import 'package:flutter/material.dart';
import '../services/pdf_service.dart';
import '../services/yandex_translate_service.dart';
import '../models/history_item.dart';

class TextResultScreen extends StatefulWidget {
  final String text;
  final String originalImagePath;
  final String processedImagePath;

  const TextResultScreen({
    required this.text,
    required this.originalImagePath,
    required this.processedImagePath,
  });

  @override
  _TextResultScreenState createState() => _TextResultScreenState();
}

class _TextResultScreenState extends State<TextResultScreen> {
  String? _translatedText;

  Future<void> _translateText() async {
    final translated = await YandexTranslateService.translateText(widget.text);
    setState(() {
      _translatedText = translated;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Распознанный текст'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: () async {
              try {
                final pdfFile = await PdfService.saveTextToPdf(widget.text, translatedText: _translatedText);
                history.add(HistoryItem(
                  originalImagePath: widget.originalImagePath,
                  processedImagePath: widget.processedImagePath,
                  pdfPath: pdfFile.path,
                ));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Сохранено в PDF')),
                );
              } catch (e) {
                print('Error saving PDF: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Ошибка при сохранении PDF: $e')),
                );
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Оригинальный текст:',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                widget.text,
                style: TextStyle(fontSize: 18),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _translateText,
                child: Text('Перевести на английский'),
              ),
              if (_translatedText != null) ...[
                SizedBox(height: 20),
                Text(
                  'Переведённый текст:',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Text(
                  _translatedText!,
                  style: TextStyle(fontSize: 18),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}