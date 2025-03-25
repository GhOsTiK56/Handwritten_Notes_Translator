import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ImageProcessor {
  static Future<File?> processImage(String imagePath) async {
    print('Starting image processing...');
    final originalFile = File(imagePath);
    final originalImage = img.decodeImage(await originalFile.readAsBytes());

    if (originalImage == null) {
      print('Не удалось загрузить изображение');
      return null;
    }

    final grayscaleImage = img.grayscale(originalImage);
    final processedImage = img.adjustColor(grayscaleImage, contrast: 2.0);

    final tempDir = await getTemporaryDirectory();
    final processedPath = path.join(tempDir.path, 'processed_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await File(processedPath).writeAsBytes(img.encodeJpg(processedImage));

    print('Image processed: $processedPath');
    return File(processedPath);
  }
}