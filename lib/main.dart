import 'package:flutter/material.dart';
import 'package:lines/pages/main_page.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return  MaterialApp(
      theme: ThemeData(
        textSelectionTheme: TextSelectionThemeData(
          selectionColor: Colors.grey.shade300,
        )
      ),
      debugShowCheckedModeBanner: false,
      home: MainPage()
    );
  }
}