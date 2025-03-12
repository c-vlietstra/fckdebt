import 'package:flutter/material.dart';
import '../widgets/text_field.dart';
import '../services/auth_service.dart';

class SignupScreen extends StatefulWidget {
  final AuthService? authService; // Optional for testing

  const SignupScreen({super.key, this.authService});

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _incomeController = TextEditingController();
  String? _aesKey;
  String? _error;

  Future<void> _signup() async {
    final authService = widget.authService ?? AuthService(); // Use injected or default
    try {
      final income = double.parse(_incomeController.text);
      final result = await authService.signup(
        email: _emailController.text,
        password: _passwordController.text,
        monthlyIncome: income,
      );
      setState(() {
        _aesKey = authService.aesKey;
        _error = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Signed up! User ID: ${result['user_id']}')),
        );
      }
      // TODO: Navigate to home screen
    } catch (e) {
      setState(() => _error = e.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Signup failed: $_error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('F*ckDebt - Signup')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            CustomTextField(controller: _emailController, label: 'Email'),
            CustomTextField(controller: _passwordController, label: 'Password', obscureText: true),
            CustomTextField(controller: _incomeController, label: 'Monthly Income', keyboardType: TextInputType.number),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _signup, child: const Text('Sign Up')),
            if (_aesKey != null) ...[
              const SizedBox(height: 20),
              Text('Your AES Key (save this!): $_aesKey', style: const TextStyle(fontSize: 12)),
            ],
            if (_error != null) ...[
              const SizedBox(height: 20),
              Text('Error: $_error', style: const TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
    );
  }
}