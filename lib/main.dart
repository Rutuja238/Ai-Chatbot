import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'login_screen.dart';
import 'splashscreen.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'chat_screen.dart';
import 'models/chat_session.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print("🚀 Flutter App Starting...");

  try {
    await dotenv.load(fileName: ".env");
      await Hive.initFlutter();
  Hive.registerAdapter(ChatSessionAdapter()); // Register Hive model
  await Hive.openBox<ChatSession>('chat_sessions'); // Open box for chat sessions

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

  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AI Chatbot',
      initialRoute: '/',
      routes: {
        '/': (context) => StreamBuilder<User?>(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Scaffold(body: Center(child: CircularProgressIndicator()));
                }
                if (snapshot.hasData) {
                  return ChatScreen(); // User is logged in
                }
                return LoginScreen(); // User is logged out
              },
            ),
        '/login': (context) => LoginScreen(),
      },
    );
  }
}

