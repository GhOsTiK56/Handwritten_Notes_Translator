import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfService {
  static Future<File> saveTextToPdf(String originalText, {String? translatedText}) async {
    final pdf = pw.Document();

    // Загружаем шрифт Roboto с поддержкой кириллицы
    late pw.Font font;
    try {
      final fontData = await rootBundle.load('assets/fonts/Roboto-VariableFont_wdth,wght.ttf');
      font = pw.Font.ttf(fontData);
      print('Roboto font loaded successfully');
    } catch (e) {
      print('Failed to load Roboto font: $e');
      throw Exception('Не удалось загрузить шрифт для PDF');
    }

    print('Original text to save in PDF: "$originalText"');
    if (translatedText != null) {
      print('Translated text to save in PDF: "$translatedText"');
    }

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Оригинальный текст:',
              style: pw.TextStyle(fontSize: 20, font: font, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              originalText,
              style: pw.TextStyle(fontSize: 16, font: font),
            ),
            if (translatedText != null) ...[
              pw.SizedBox(height: 20),
              pw.Text(
                'Переведённый текст:',
                style: pw.TextStyle(fontSize: 20, font: font, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                translatedText,
                style: pw.TextStyle(fontSize: 16, font: font),
              ),
            ],
          ],
        ),
      ),
    );

    final dir = Directory('/storage/emulated/0/Download');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
      print('Download directory created');
    }
    final file = File('${dir.path}/recognized_text_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());
    print('PDF saved to: ${file.path}');
    return file;
  }
}