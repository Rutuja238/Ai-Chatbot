import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'chat_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  void _checkLoginStatus() {
    if (FirebaseAuth.instance.currentUser != null) {
      _navigateToChatScreen();
    }
  }

  Future<void> googleLogin() async {
    GoogleSignIn googleSignIn = GoogleSignIn();

    try {
      // Force user to pick an account every time
      await googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        // User canceled sign-in
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
      _navigateToChatScreen();
    } catch (error) {
      print("Login Error: $error");
    }
  }

  void _navigateToChatScreen() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => ChatScreen()),
    );
  }

  Future<void> logout() async {
    try {
      GoogleSignIn googleSignIn = GoogleSignIn();
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.signOut(); // Clears Google account cache
        await googleSignIn.disconnect(); // Disconnects the account
      }
    } catch (e) {
      print("Google Sign-Out Error: $e");
    }

    await FirebaseAuth.instance.signOut(); // Sign out from Firebase

    if (mounted) {
      Navigator.pushReplacementNamed(
        context,
        "/login",
      ); // Go back to login screen
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color.fromARGB(255, 245, 102, 150), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Circular logo
              const CircleAvatar(
                radius: 40,
                backgroundColor: Colors.white,
                child: Icon(Icons.chat, size: 50, color: Colors.pinkAccent),
              ),
              const SizedBox(height: 30),

              // "Login to your account" text
              const Text(
                "Login to your account",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 20),

              // Google Sign-In Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: googleLogin,
                  icon: Image.asset(
                    "images/splash_logo.png",
                    height: 20,
                  ), // Make sure you add this asset
                  label: const Text("Login with Google"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    side: const BorderSide(color: Colors.grey),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
