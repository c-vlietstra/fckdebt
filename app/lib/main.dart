import 'package:flutter/material.dart';
import 'screens/signup_screen.dart';

void main() {
  runApp(const FckDebtApp());
}

class FckDebtApp extends StatelessWidget {
  const FckDebtApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'F*ckDebt',
      theme: ThemeData(
        primarySwatch: Colors.red,
        useMaterial3: true,
      ),
      home: const SignupScreen(),
    );
  }
}