class HistoryItem {
  final String originalImagePath;
  final String processedImagePath;
  final String pdfPath;

  HistoryItem({
    required this.originalImagePath,
    required this.processedImagePath,
    required this.pdfPath,
  });
}

// Хранилище истории (в памяти для простоты)
List<HistoryItem> history = [];