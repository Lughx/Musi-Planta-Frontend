import 'package:musiplanta/main_page.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Musi Planta',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Color.fromARGB(255, 74, 202, 76), background: Colors.transparent),
        useMaterial3: true
      ),
      home: const MainPage(),
    );
  }
}
