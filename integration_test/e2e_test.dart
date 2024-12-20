import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hediaty_final/views/eventformpage.dart';
import 'package:hediaty_final/views/login.dart';
import 'package:integration_test/integration_test.dart';
import 'package:hediaty_final/views/main.dart' ;


Future<void> main() async {

  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  group('End-to-End Test', () {
    testWidgets('Navigate to Main Page', (WidgetTester tester) async {
      // Start the app
      await tester.pumpWidget(HedieatyApp());

      // Verify if the app starts with the LoadingPage
      expect(find.byType(StartupPage), findsOneWidget);


      await tester.pumpAndSettle();
      expect(find.byType(login), findsOneWidget);

      // Input test credentials and simulate login
      final emailField = find.byKey(Key('emailField'));
      final passwordField = find.byKey(Key('passwordField'));
      final loginButton = find.byKey(Key('loginButton'));
      final mobilephone = find.byKey(Key('phoneField'));

      await tester.enterText(emailField, 'beso@gmail.com');
      await tester.enterText(passwordField, '123456');
      await tester.enterText(mobilephone, '01030642000');
      await tester.tap(loginButton);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      // Wait for Homepage navigation
      expect(find.byType(Homepage), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));

      final eventbutton = find.byKey(const Key('eventButton'));
      await tester.tap(eventbutton);
      await tester.pumpAndSettle();

      expect(find.byType(EventFormPage), findsOneWidget);







    });
  });
}

