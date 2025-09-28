import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../common/widgets/primary_button.dart';

class LandingPage extends StatelessWidget {
  final VoidCallback onSignUp;
  final VoidCallback onLogin;

  const LandingPage({super.key, required this.onSignUp, required this.onLogin});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
               image: AssetImage('assets/images/landing.jpg'), 
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Overlay
          Container(color: Colors.black.withOpacity(0.4)),
          // Content
          Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo + Title
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white24,
                    child: const Icon(Icons.eco, color: Colors.white, size: 40),
                  ),
                  const SizedBox(height: 16),
                  Text("naihydro.",
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text(
                    "Your smart hydroponic farm monitoring companion. "
                    "Keep track of your crops with real-time data and intelligent alerts.",
                    style: GoogleFonts.poppins(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  PrimaryButton(label: "Get Started", onPressed: onSignUp),
                  const SizedBox(height: 12),
                  PrimaryButton(
                      label: "Sign In", onPressed: onLogin, outlined: true),
                  const SizedBox(height: 30),
                  Text("Revolutionizing agriculture with smart technology",
                      style: GoogleFonts.poppins(
                          color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
