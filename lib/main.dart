import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'splashscreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
 await Firebase.initializeApp();
  runApp(const SplashScreenApp());
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

