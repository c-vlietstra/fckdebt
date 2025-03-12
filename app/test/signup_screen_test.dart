import 'package:app/screens/signup_screen.dart';
import 'package:app/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

// Generate mocks with Mockito (manual mock for now)
class MockAuthService extends Mock implements AuthService {
  @override
  String? get aesKey => _aesKey;
  String? _aesKey;
}

// Note: If using build_runner, add `@GenerateMocks([AuthService])` and import generated file
// For simplicity, we’re mocking manually here.

void main() {
  late MockAuthService mockAuthService;

  setUp(() {
    mockAuthService = MockAuthService();
  });

  // Helper to pump the widget with mocked service
  Widget createSignupScreen() {
    return MaterialApp(
      home: SignupScreen(authService: mockAuthService), // Pass mock for testing
    );
  }

  group('SignupScreen', () {
    testWidgets('renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createSignupScreen());

      expect(find.text('F*ckDebt - Signup'), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(3));
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Monthly Income'), findsOneWidget);
      expect(find.text('Sign Up'), findsOneWidget);
    });

    testWidgets('shows AES key on successful signup', (WidgetTester tester) async {
      // Mock successful signup
      when(mockAuthService.signup(
        email: 'test@example.com',
        password: 'password123',
        monthlyIncome: 5000.0,
      )).thenAnswer((_) async => {
            'user_id': 1,
            'token': 'fake-token',
          });
      when(mockAuthService.aesKey).thenReturn('fake-aes-key');

      await tester.pumpWidget(createSignupScreen());

      // Enter data
      await tester.enterText(find.byType(TextField).at(0), 'test@example.com');
      await tester.enterText(find.byType(TextField).at(1), 'password123');
      await tester.enterText(find.byType(TextField).at(2), '5000');

      // Tap signup
      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle(); // Wait for async operations and animations

      // Verify results
      expect(find.text('Your AES Key (save this!): fake-aes-key'), findsOneWidget);
      expect(find.text('Signed up! User ID: 1'), findsOneWidget);
      expect(find.textContaining('Error'), findsNothing);
    });

    testWidgets('shows error on signup failure', (WidgetTester tester) async {
      // Mock failed signup
      when(mockAuthService.signup(
        email: 'test@example.com',
        password: 'password123',
        monthlyIncome: 5000.0,
      )).thenThrow('Email already registered');

      await tester.pumpWidget(createSignupScreen());

      // Enter data
      await tester.enterText(find.byType(TextField).at(0), 'test@example.com');
      await tester.enterText(find.byType(TextField).at(1), 'password123');
      await tester.enterText(find.byType(TextField).at(2), '5000');

      // Tap signup
      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      // Verify error
      expect(find.text('Error: Email already registered'), findsOneWidget);
      expect(find.text('Signup failed: Email already registered'), findsOneWidget);
      expect(find.textContaining('Your AES Key'), findsNothing);
    });

    testWidgets('handles invalid income input', (WidgetTester tester) async {
      await tester.pumpWidget(createSignupScreen());

      // Enter invalid income
      await tester.enterText(find.byType(TextField).at(0), 'test@example.com');
      await tester.enterText(find.byType(TextField).at(1), 'password123');
      await tester.enterText(find.byType(TextField).at(2), 'not-a-number');

      // Tap signup
      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      // Verify error (FormatException from double.parse)
      expect(find.textContaining('Error: FormatException'), findsOneWidget);
      expect(find.textContaining('Signup failed'), findsOneWidget);
    });
  });
}