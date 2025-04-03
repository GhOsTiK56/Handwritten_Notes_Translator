import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

class YandexOcrService {
  static Future<String> recognizeText(File image) async {
    print('Starting Yandex text recognition...');
    print('Processed image path: ${image.path}');

    const authToken = 'API'; // Ваш IAM-токен или API-ключ
    const folderId = 'Folder';
    const url = 'https://ocr.api.cloud.yandex.net/ocr/v1/recognizeText';

    final imageBytes = await image.readAsBytes();
    final base64Image = base64Encode(imageBytes);
    print('Base64 length: ${base64Image.length}');

    final requestBody = jsonEncode({
      'mimeType': 'JPEG',
      'languageCodes': ['ru', 'en'], // Явно указываем языки для handwritten
      'model': 'handwritten', // Модель для рукописного текста
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
        if (result == null) return 'Ошибка: "result" отсутствует в ответе';

        final textAnnotation = result['textAnnotation'] as Map<String, dynamic>?;
        if (textAnnotation == null) return 'Ошибка: "textAnnotation" отсутствует в ответе';

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
        final finalText = recognizedText.isEmpty ? 'Текст не распознан' : recognizedText.trim();
        print('Recognized text: $finalText');
        return finalText;
      } else {
        return 'Ошибка API: ${response.statusCode} - ${response.body}';
      }
    } catch (e) {
      print('Yandex recognition error: $e');
      return 'Ошибка распознавания: $e';
    }
  }
}