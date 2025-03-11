import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'chat_screen.dart'; // Import ChatScreen

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

  // Check if user is already logged in
  void _checkLoginStatus() {
    if (FirebaseAuth.instance.currentUser != null) {
      _navigateToChatScreen();
    }
  }

  Future<void> googleLogin() async {
    print("Google Login method Called");
    GoogleSignIn _googleSignIn = GoogleSignIn();
    try {
      var result = await _googleSignIn.signIn();
      if (result == null) {
        return;
      }

      final userData = await result.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: userData.accessToken,
        idToken: userData.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      print("User Logged In: ${result.displayName}, ${result.email}");

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
    await GoogleSignIn().disconnect();
    await FirebaseAuth.instance.signOut();
    setState(() {}); // Refresh UI after logout
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login Screen'),
        actions: [
          TextButton(
            onPressed: logout,
            child: const Text(
              'Logout',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: googleLogin,
          child: const Text('Google Login'),
        ),
      ),
    );
  }
}
