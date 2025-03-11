import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'login_screen.dart';
import 'splashscreen.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await dotenv.load(fileName: ".env");
//   await Firebase.initializeApp();
//   runApp(const SplashScreenApp());
// }
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print("🚀 Flutter App Starting...");

  try {
    await dotenv.load(fileName: ".env");

    // Log the API key to confirm the file is loading correctly
    String? apiKey = dotenv.env['OPENAI_API_KEY'];
    print("✅ .env file loaded successfully: OPENAI_API_KEY=${apiKey != null ? "FOUND" : "MISSING"}");

    await Firebase.initializeApp();
    print("✅ Firebase initialized successfully");

    runApp(const SplashScreenApp());
  } catch (e) {
    print("❌ Error during initialization: $e");
  }
}


class SplashScreenApp extends StatelessWidget {
  const SplashScreenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: SplashScreen(),
     );
  }
}

