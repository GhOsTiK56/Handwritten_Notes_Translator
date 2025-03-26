import 'dart:convert';
import 'package:http/http.dart' as http;

class YandexTranslateService {
  // Замените на ваши данные
  static const String apiKey = 'API'; // Ваш API-ключ (если используете)
  //static const String iamToken = 'YOUR_IAM_TOKEN'; // Ваш IAM-токен (если используете)
  static const String folderId = 'FOLDER'; // Ваш folderId
  static const String url = 'https://translate.api.cloud.yandex.net/translate/v2/translate';

  static Future<String> translateText(String text, {String fromLang = 'ru', String toLang = 'en'}) async {
    try {
      final headers = {
        'Content-Type': 'application/json',
        // Используйте один из вариантов:
         'Authorization': 'Api-Key $apiKey', // Для API-ключа
        //'Authorization': 'Bearer $iamToken', // Для IAM-токена
      };

      final body = jsonEncode({
        'sourceLanguageCode': fromLang,
        'targetLanguageCode': toLang,
        'texts': [text],
        'folderId': folderId, // Добавляем folderId
      });

      print('Translate request body: $body');
      print('Translate request headers: $headers');

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: body,
      );

      print('Translate response status: ${response.statusCode}');
      print('Translate response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final translatedText = jsonResponse['translations'][0]['text'] as String;
        return translatedText;
      } else {
        throw Exception('Ошибка перевода: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Translation error: $e');
      return 'Ошибка перевода: $e';
    }
  }
}