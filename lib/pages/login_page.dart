import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isLoading = false;

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      // 1. Trigger Google Sign In flow
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      // If user cancelled the login
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      // 2. Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      // 3. Create a new credential
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Sign in to Firebase with the credential
      await FirebaseAuth.instance.signInWithCredential(credential);

      // The stream in main.dart will automatically take you to the Home Page now!
    } catch (e) {
      debugPrint("Error signing in: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Login Failed. Please try again."),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine theme brightness for styling
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5);
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: bgColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo Icon
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_stories_rounded,
                  size: 64,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 32),

              // App Title
              Text(
                "Life Notebook",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 12),

              // Subtitle
              Text(
                "Your health, finance, and schedule.\nAll in one private place.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.grey.shade600,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 60),

              // Login Button
              if (_isLoading)
                const CircularProgressIndicator(color: Colors.green)
              else
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _signInWithGoogle,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? Colors.white : Colors.white,
                      foregroundColor: Colors.black87,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // We use an Icon here, but in production you usually use the Google Logo image
                        const Icon(Icons.login, color: Colors.blue),
                        const SizedBox(width: 12),
                        const Text(
                          "Continue with Google",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Roboto', // Google standard font
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              // Privacy Note
              Text(
                "Securely synced with your Google Account.",
                style: TextStyle(
                  color: isDark ? Colors.white24 : Colors.grey.shade400,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
