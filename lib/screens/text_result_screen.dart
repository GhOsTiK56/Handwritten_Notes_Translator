import 'dart:io';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_pdfview/flutter_pdfview.dart';
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

class _TextResultScreenState extends State<TextResultScreen> with SingleTickerProviderStateMixin {
  String? _translatedText;
  String _targetLanguage = 'en';
  bool _handwrittenStyle = false;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late TextEditingController _originalController;
  late TextEditingController _translatedController;
  late TextEditingController _notesController;
  bool _originalEdited = false;
  bool _translatedEdited = false;
  String? _category;
  String? _pdfPath;
  bool _showPreview = false;
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 500), vsync: this);
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(_controller);
    _originalController = TextEditingController(text: widget.text);
    _translatedController = TextEditingController();
    _notesController = TextEditingController();
    _categorizeText(widget.text);
  }

  @override
  void dispose() {
    _controller.dispose();
    _originalController.dispose();
    _translatedController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _translateText(String languageCode) async {
    final translated = await YandexTranslateService.translateText(_originalController.text, targetLanguage: languageCode);
    setState(() {
      _translatedText = translated;
      _translatedController.text = translated;
      _targetLanguage = languageCode;
      _controller.forward(from: 0);
      print('Translated text set: "$_translatedText" to language: "$_targetLanguage"');
    });
  }

  void _categorizeText(String text) {
    text = text.toLowerCase();
    if (text.contains('купить') || text.contains('список')) {
      _category = 'Список дел';
    } else if (text.contains('дорог') || text.length > 200) {
      _category = 'Письмо';
    } else if (text.contains('рецепт') || text.contains('ингредиент')) {
      _category = 'Рецепт';
    } else {
      _category = 'Заметка';
    }
    print('Categorized text as: $_category');
  }

  Future<void> _startListening(TextEditingController controller) async {
    if (await _speech.initialize()) {
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (result) {
          setState(() {
            controller.text = result.recognizedWords;
            if (controller == _originalController) _originalEdited = true;
            if (controller == _translatedController) _translatedEdited = true;
          });
        },
      );
    }
  }

  void _stopListening() {
    setState(() => _isListening = false);
    _speech.stop();
  }

  Future<void> _previewPdf() async {
    final pdfFile = await PdfService.saveTextToPdf(
      _originalController.text,
      translatedText: _translatedText != null ? _translatedController.text : null,
      handwrittenStyle: _handwrittenStyle,
      notes: _notesController.text,
      category: _category,
      originalTextForDiff: widget.text,
    );
    setState(() {
      _pdfPath = pdfFile.path;
      _showPreview = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Text Result', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.teal,
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.preview, color: Colors.white),
            onPressed: _previewPdf,
            tooltip: 'Preview PDF',
          ),
          IconButton(
            icon: const Icon(Icons.save, color: Colors.white),
            onPressed: () async {
              try {
                final pdfFile = await PdfService.saveTextToPdf(
                  _originalController.text,
                  translatedText: _translatedText != null ? _translatedController.text : null,
                  handwrittenStyle: _handwrittenStyle,
                  notes: _notesController.text,
                  category: _category,
                  originalTextForDiff: widget.text,
                );
                history.add(HistoryItem(
                  originalImagePath: widget.originalImagePath,
                  processedImagePath: widget.processedImagePath,
                  pdfPath: pdfFile.path,
                ));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved to PDF')));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving PDF: $e')));
              }
            },
            tooltip: 'Save as PDF',
          ),
        ],
      ),
      body: _showPreview && _pdfPath != null
          ? Column(
        children: [
          Expanded(
            child: PDFView(filePath: _pdfPath!),
          ),
          ElevatedButton(
            onPressed: () => setState(() => _showPreview = false),
            child: const Text('Back to Editing'),
          ),
        ],
      )
          : Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal.shade50, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.text_fields, color: Colors.teal),
                    const SizedBox(width: 8),
                    Text(
                      'Original Text',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.teal),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _originalController,
                            maxLines: null,
                            style: const TextStyle(fontSize: 18),
                            decoration: InputDecoration(
                              hintText: 'No text detected',
                              border: InputBorder.none,
                              filled: _originalEdited,
                              fillColor: _originalEdited ? Colors.yellow.withOpacity(0.3) : null,
                            ),
                            onChanged: (value) {
                              setState(() {
                                _originalEdited = value != widget.text;
                                _categorizeText(value);
                              });
                            },
                          ),
                        ),
                        IconButton(
                          icon: Icon(_isListening ? Icons.mic : Icons.mic_none, color: Colors.teal),
                          onPressed: _isListening ? _stopListening : () => _startListening(_originalController),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text('Category: $_category', style: const TextStyle(fontSize: 16, color: Colors.grey)),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Icon(Icons.translate, color: Colors.teal),
                    const SizedBox(width: 8),
                    Text(
                      'Translate to:',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.teal),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                DropdownButton<String>(
                  value: _targetLanguage,
                  items: const [
                    DropdownMenuItem(value: 'en', child: Text('English')),
                    DropdownMenuItem(value: 'es', child: Text('Spanish')),
                    DropdownMenuItem(value: 'fr', child: Text('French')),
                    DropdownMenuItem(value: 'de', child: Text('German')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _targetLanguage = value);
                      _translateText(value);
                    }
                  },
                  style: const TextStyle(fontSize: 16, color: Colors.black),
                  dropdownColor: Colors.white,
                  underline: Container(height: 2, color: Colors.teal),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Icon(Icons.brush, color: Colors.teal),
                    const SizedBox(width: 8),
                    const Text('Handwritten Style', style: TextStyle(fontSize: 16, color: Colors.teal)),
                    const SizedBox(width: 10),
                    Switch(
                      value: _handwrittenStyle,
                      onChanged: (value) => setState(() => _handwrittenStyle = value),
                      activeColor: Colors.teal,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (_translatedText != null) ...[
                  Row(
                    children: [
                      const Icon(Icons.language, color: Colors.teal),
                      const SizedBox(width: 8),
                      Text(
                        'Translated Text',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.teal),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _translatedController,
                                maxLines: null,
                                style: const TextStyle(fontSize: 18),
                                decoration: InputDecoration(
                                  hintText: 'Translation will appear here',
                                  border: InputBorder.none,
                                  filled: _translatedEdited,
                                  fillColor: _translatedEdited ? Colors.yellow.withOpacity(0.3) : null,
                                ),
                                onChanged: (value) {
                                  setState(() => _translatedEdited = value != _translatedText);
                                },
                              ),
                            ),
                            IconButton(
                              icon: Icon(_isListening ? Icons.mic : Icons.mic_none, color: Colors.teal),
                              onPressed: _isListening ? _stopListening : () => _startListening(_translatedController),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Icon(Icons.note, color: Colors.teal),
                    const SizedBox(width: 8),
                    Text(
                      'Notes',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.teal),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: TextField(
                      controller: _notesController,
                      maxLines: null,
                      style: const TextStyle(fontSize: 18),
                      decoration: const InputDecoration(
                        hintText: 'Add your notes here...',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}