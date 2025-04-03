import 'dart:convert';
import 'package:http/http.dart' as http;

class YandexTranslateService {
  // Замените на ваши данные
  static const String apiKey = 'API'; // Ваш API-ключ (если используете)
  //static const String iamToken = 'YOUR_IAM_TOKEN'; // Ваш IAM-токен (если используете)
  static const String folderId = 'Folder'; // Ваш folderId
  static const String url = 'https://translate.api.cloud.yandex.net/translate/v2/translate';

  static Future<String> translateText(String text, {String targetLanguage = 'en'}) async {
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Api-Key $apiKey',
      },
      body: jsonEncode({
        'sourceLanguageCode': 'ru',
        'targetLanguageCode': targetLanguage,
        'texts': [text],
      }),
    );

    print('Translate response status: ${response.statusCode}');
    print('Translate response body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['translations'][0]['text'];
    } else {
      throw Exception('Failed to translate text: ${response.statusCode}');
    }
  }
}