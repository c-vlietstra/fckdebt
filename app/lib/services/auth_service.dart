import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AuthService {
  final _storage = const FlutterSecureStorage();
  String? _aesKey;

  String? get aesKey => _aesKey;

  Future<Map<String, dynamic>> signup({
    required String email,
    required String password,
    required double monthlyIncome,
    String budgetMethod = '50/20/30',
  }) async {
    // Generate AES-256 key
    final key = encrypt.Key.fromSecureRandom(32); // 256 bits
    final iv = encrypt.IV.fromLength(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.gcm));

    // Encrypt monthly income
    final encryptedIncome = encrypter.encrypt(monthlyIncome.toString(), iv: iv);

    // Store key
    await _storage.write(key: 'aes_key', value: key.base64);
    _aesKey = key.base64;

    // API call
    final response = await http.post(
      Uri.parse('http://localhost:3000/v1/auth/signup'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'monthly_income': monthlyIncome,
        'budget_method': budgetMethod,
        'encrypted_data': {'monthly_income': encryptedIncome.base16},
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw jsonDecode(response.body)['error'] ?? 'Unknown error';
    }
  }
}