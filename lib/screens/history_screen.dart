import 'dart:io';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import '../models/history_item.dart';

class HistoryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('История'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Оригинальные фото', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              _buildImageList(context, history.map((item) => item.originalImagePath).toList()),
              SizedBox(height: 20),
              Text('Обработанные фото', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              _buildImageList(context, history.map((item) => item.processedImagePath).toList()),
              SizedBox(height: 20),
              Text('PDF файлы', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              _buildPdfList(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageList(BuildContext context, List<String> paths) {
    return SizedBox(
      height: 150,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: paths.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (_) => Dialog(
                    child: Image.file(File(paths[index])),
                  ),
                );
              },
              child: Image.file(
                File(paths[index]),
                width: 100,
                height: 100,
                fit: BoxFit.cover,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPdfList(BuildContext context) {
    return Column(
      children: history.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        return ListTile(
          leading: Icon(Icons.picture_as_pdf, color: Colors.teal),
          title: Text('PDF #${index + 1}'),
          subtitle: Text(item.pdfPath.split('/').last),
          onTap: () async {
            print('Attempting to open PDF: ${item.pdfPath}');
            final file = File(item.pdfPath);
            if (await file.exists()) {
              print('File exists, opening...');
              final result = await OpenFile.open(item.pdfPath);
              print('OpenFile result: ${result.type} - ${result.message}');
              if (result.type != ResultType.done) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Не удалось открыть PDF: ${result.message}')),
                );
              }
            } else {
              print('File does not exist');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Файл не найден: ${item.pdfPath}')),
              );
            }
          },
        );
      }).toList(),
    );
  }
}