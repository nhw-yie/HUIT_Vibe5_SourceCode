import 'package:flutter/material.dart';
import 'config/theme/app_theme.dart';
import 'features/home/presentation/pages/home_page.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Air Quality App',
      theme: AppTheme.light,
      darkTheme: AppTheme.light,
      home: const HomePage(),   // 👈 Chạy thẳng HomePage
    );
  }
}
