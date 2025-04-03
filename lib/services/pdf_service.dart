import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfService {
  static Future<File> saveTextToPdf(
      String originalText, {
        String? translatedText,
        bool handwrittenStyle = false,
        String? notes,
        String? category,
        String? originalTextForDiff,
      }) async {
    final pdf = pw.Document();

    late pw.Font regularFont;
    late pw.Font handwrittenFont;
    try {
      final regularFontData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
      regularFont = pw.Font.ttf(regularFontData);
      final handwrittenFontData = await rootBundle.load('assets/fonts/Caveat-Regular.ttf');
      handwrittenFont = pw.Font.ttf(handwrittenFontData);
      print('Fonts loaded successfully');
    } catch (e) {
      print('Failed to load fonts: $e');
      regularFont = pw.Font.helvetica();
      handwrittenFont = pw.Font.helvetica();
    }

    final font = handwrittenStyle ? handwrittenFont : regularFont;
    final cleanOriginalText = originalText.replaceAll('\n', ' ').trim();
    final cleanTranslatedText = translatedText?.replaceAll('\n', ' ').trim();

    print('Original text received: "$cleanOriginalText"');
    print('Translated text received: "${cleanTranslatedText ?? 'null'}"');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            if (category != null) ...[
              pw.Text(
                'Категория: $category',
                style: pw.TextStyle(fontSize: 14, font: regularFont, color: PdfColors.grey),
              ),
              pw.SizedBox(height: 10),
            ],
            pw.Text(
              'Оригинальный текст (Русский)',
              style: pw.TextStyle(fontSize: 20, font: regularFont, fontWeight: pw.FontWeight.bold, color: PdfColors.blue),
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              cleanOriginalText.isEmpty ? 'Текст отсутствует' : cleanOriginalText,
              style: pw.TextStyle(fontSize: 16, font: font),
            ),
            if (originalTextForDiff != null && originalTextForDiff != cleanOriginalText) ...[
              pw.SizedBox(height: 10),
              pw.Text(
                'Изменения:',
                style: pw.TextStyle(fontSize: 16, font: regularFont, color: PdfColors.red),
              ),
              pw.Text(
                _computeDiff(originalTextForDiff, cleanOriginalText),
                style: pw.TextStyle(fontSize: 14, font: regularFont, color: PdfColors.red),
              ),
            ],
            pw.SizedBox(height: 20),
            if (cleanTranslatedText != null) ...[
              pw.Text(
                'Переведённый текст (Английский)',
                style: pw.TextStyle(fontSize: 20, font: regularFont, fontWeight: pw.FontWeight.bold, color: PdfColors.green),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                cleanTranslatedText,
                style: pw.TextStyle(fontSize: 16, font: font),
              ),
            ],
            if (notes != null && notes.isNotEmpty) ...[
              pw.SizedBox(height: 20),
              pw.Text(
                'Заметки',
                style: pw.TextStyle(fontSize: 20, font: regularFont, fontWeight: pw.FontWeight.bold, color: PdfColors.orange),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                notes,
                style: pw.TextStyle(fontSize: 16, font: font),
              ),
            ],
          ],
        ),
      ),
    );

    final dir = Directory('/storage/emulated/0/Download');
    if (!await dir.exists()) await dir.create(recursive: true);
    final file = File('${dir.path}/translated_text_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());
    print('PDF saved to: ${file.path}');
    return file;
  }

  static String _computeDiff(String original, String edited) {
    original = original.replaceAll('\n', ' ').trim();
    edited = edited.replaceAll('\n', ' ').trim();
    List<String> origWords = original.split(' ');
    List<String> editWords = edited.split(' ');
    String diff = '';
    for (int i = 0; i < editWords.length; i++) {
      if (i >= origWords.length || origWords[i] != editWords[i]) {
        diff += '[+${editWords[i]}] ';
      } else {
        diff += '${editWords[i]} ';
      }
    }
    return diff.trim();
  }
}