import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:naihydro/src/features/auth/presentation/data/auth_service.dart';
import 'package:naihydro/src/features/auth/presentation/login_page.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:ui';

// Match farm details page theme
const Color kPrimaryGreen = Color(0xFF558B2F);
const Color kAccentGreen = Color(0xFF8BC34A);
const Color kBackgroundColor = Color(0xFFC7CEC8);
const Color kCardColor = Colors.white10;
const Color kLightText = Colors.white;

class SignupPage extends StatefulWidget {
  final VoidCallback onSuccess;
  final VoidCallback onBack;

  const SignupPage({
    super.key,
    required this.onSuccess,
    required this.onBack,
  });

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final confirmCtrl = TextEditingController();
  final nameCtrl = TextEditingController(); // Changed from farmCtrl
  final auth = AuthService();
  final _database = FirebaseDatabase.instance;
  String error = "";
  bool loading = false;

  @override
  void dispose() {
    emailCtrl.dispose();
    passCtrl.dispose();
    confirmCtrl.dispose();
    nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _onSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      error = "";
      loading = true;
    });

    if (passCtrl.text != confirmCtrl.text) {
      setState(() {
        error = "Passwords do not match";
        loading = false;
      });
      return;
    }

    try {
      final user = await auth.signUp(emailCtrl.text.trim(), passCtrl.text.trim());
      
      // Save user name to Firebase Realtime Database
      if (user != null) {
        await _database.ref('users/${user.uid}/profile').set({
          'name': nameCtrl.text.trim(),
          'email': emailCtrl.text.trim(),
          'createdAt': DateTime.now().toIso8601String(),
        });
      }
      
      widget.onSuccess();
    } catch (e) {
      String message = 'Signup failed. Please try again.';
      if (e.toString().contains('email-already-in-use')) {
        message = 'This email is already registered.';
      } else if (e.toString().contains('invalid-email')) {
        message = 'Invalid email format.';
      } else if (e.toString().contains('weak-password')) {
        message = 'Password is too weak.';
      }
      setState(() => error = message);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Widget _buildGlassCard({required Widget child, EdgeInsetsGeometry? padding}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: padding ?? const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: kCardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          color: kBackgroundColor,
          image: const DecorationImage(
            image: AssetImage('assets/images/detailspg.jpeg'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: kLightText),
                      onPressed: widget.onBack,
                    ),
                    Spacer(),
                    Text(
                      "naihydro",
                      style: GoogleFonts.poppins(
                        color: kLightText,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Form
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: _buildGlassCard(
                    child: Form(
                      key: _formKey,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      child: Column(
                        children: [
                          Text(
                            "Create Account",
                            style: GoogleFonts.poppins(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: kLightText,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Join the smart farming revolution",
                            style: GoogleFonts.poppins(
                              color: kLightText.withOpacity(0.8),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Name Field (changed icon from truck to person)
                          TextFormField(
                            controller: nameCtrl,
                            style: GoogleFonts.poppins(color: kLightText),
                            decoration: InputDecoration(
                              labelText: "Full Name",
                              labelStyle: GoogleFonts.poppins(color: kLightText.withOpacity(0.7)),
                              prefixIcon: Icon(Icons.person_outline, color: kAccentGreen),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.1),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: kAccentGreen, width: 2),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your name';
                              }
                              if (value.length < 2) {
                                return 'Name must be at least 2 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Email Field
                          TextFormField(
                            controller: emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            style: GoogleFonts.poppins(color: kLightText),
                            decoration: InputDecoration(
                              labelText: "Email",
                              labelStyle: GoogleFonts.poppins(color: kLightText.withOpacity(0.7)),
                              prefixIcon: Icon(Icons.email_outlined, color: kAccentGreen),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.1),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: kAccentGreen, width: 2),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Please enter your email';
                              final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                              if (!emailRegex.hasMatch(value)) return 'Enter a valid email address';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Password Field
                          TextFormField(
                            controller: passCtrl,
                            obscureText: true,
                            style: GoogleFonts.poppins(color: kLightText),
                            decoration: InputDecoration(
                              labelText: "Password",
                              labelStyle: GoogleFonts.poppins(color: kLightText.withOpacity(0.7)),
                              prefixIcon: Icon(Icons.lock_outline, color: kAccentGreen),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.1),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: kAccentGreen, width: 2),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Please enter a password';
                              if (value.length < 6) return 'Password must be at least 6 characters';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Confirm Password Field
                          TextFormField(
                            controller: confirmCtrl,
                            obscureText: true,
                            style: GoogleFonts.poppins(color: kLightText),
                            decoration: InputDecoration(
                              labelText: "Confirm Password",
                              labelStyle: GoogleFonts.poppins(color: kLightText.withOpacity(0.7)),
                              prefixIcon: Icon(Icons.lock_outline, color: kAccentGreen),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.1),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: kAccentGreen, width: 2),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Please confirm your password';
                              if (value != passCtrl.text) return 'Passwords do not match';
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          // Sign Up Button
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: loading ? null : _onSignUp,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kPrimaryGreen,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 4,
                              ),
                              child: loading
                                  ? CircularProgressIndicator(color: kLightText)
                                  : Text(
                                      "Create Account",
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: kLightText,
                                      ),
                                    ),
                            ),
                          ),

                          if (error.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 12.0),
                              child: Text(
                                error,
                                style: GoogleFonts.poppins(
                                  color: Colors.red[300],
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          const SizedBox(height: 16),

                          // Sign In Link
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => LoginPage(
                                    authService: AuthService(),
                                    onSuccess: widget.onSuccess,
                                    onBack: () => Navigator.pop(context),
                                  ),
                                ),
                              );
                            },
                            child: Text(
                              "Already have an account? Sign in",
                              style: GoogleFonts.poppins(
                                color: kAccentGreen,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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