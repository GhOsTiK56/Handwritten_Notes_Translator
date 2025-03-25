import 'package:flutter/material.dart';
import 'screens/camera_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Handwritten Notes Translator',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Handwritten Notes Translator'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => CameraScreen()),
                );
              },
              child: Text('Сделать фото'),
            ),
            SizedBox(height: 20),
            Text('Добро пожаловать! Нажмите кнопку, чтобы начать.'),
          ],
        ),
      ),
    );
  }
}