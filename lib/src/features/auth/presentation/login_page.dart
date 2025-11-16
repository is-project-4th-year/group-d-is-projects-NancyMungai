import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:naihydro/src/features/auth/presentation/data/auth_service.dart';
import 'package:naihydro/src/features/auth/presentation/signup_page.dart';
import '../../common/services/notification_service.dart';
import 'dart:ui';

// Match farm details page theme
const Color kPrimaryGreen = Color(0xFF558B2F);
const Color kAccentGreen = Color(0xFF8BC34A);
const Color kBackgroundColor = Color(0xFFC7CEC8);
const Color kCardColor = Colors.white10;
const Color kLightText = Colors.white;

class LoginPage extends StatefulWidget {
  final VoidCallback onSuccess;
  final VoidCallback onBack;
  final AuthService authService;

  const LoginPage({
    super.key,
    required this.onSuccess,
    required this.onBack,
    required this.authService,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  String error = "";
  bool loading = false;

  @override
  void dispose() {
    emailCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }

  Future<void> _onSignIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      error = "";
      loading = true;
    });
    
    try {
      final user = await widget.authService.signIn(
        emailCtrl.text.trim(),
        passCtrl.text.trim(),
      );

      if (user != null) {
        print('✅ User logged in: ${user.uid}');
        try {
          final uid = user.uid;
          final dbRef = FirebaseDatabase.instance.ref('users/$uid/farms');

          print('📥 Fetching farms for user: $uid');
          
          final farmsSnapshot = await dbRef.get();

          if (farmsSnapshot.exists) {
            print('✅ Farms found for user');
            final farmsData = farmsSnapshot.value as Map;
            final firstFarm = farmsData.values.first as Map;

            final deviceId = firstFarm['deviceId'] ?? 'esp32-001';
            print('🌱 Found farm deviceId: $deviceId');

            await NotificationService().initialize(deviceId, uid);
            print('✅ Notifications initialized for device: $deviceId');
          } else {
            print('⚠️ No farms found for user');
            await NotificationService().initialize('esp32-001', uid);
          }
        } catch (notifError) {
          print('⚠️ Error initializing notifications: $notifError');
        }

        widget.onSuccess();
      } else {
        setState(() => error = "Sign in failed");
      }
    } catch (e) {
      String message = 'Login failed. Please try again.';
      if (e.toString().contains('wrong-password')) {
        message = 'Incorrect password.';
      } else if (e.toString().contains('user-not-found')) {
        message = 'No user found for this email.';
      } else if (e.toString().contains('invalid-email')) {
        message = 'Invalid email address.';
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

              // Form Card
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
                            "Welcome Back",
                            style: GoogleFonts.poppins(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: kLightText,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Sign in to monitor your hydroponic farm",
                            style: GoogleFonts.poppins(
                              color: kLightText.withOpacity(0.8),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 32),

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
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                              if (!emailRegex.hasMatch(value)) {
                                return 'Enter a valid email address';
                              }
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
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          // Sign In Button
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: loading ? null : () => _onSignIn(),
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
                                      'Sign In',
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

                          // Sign Up Link
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => SignupPage(
                                    onSuccess: widget.onSuccess,
                                    onBack: () => Navigator.pop(context),
                                  ),
                                ),
                              );
                            },
                            child: Text(
                              "Don't have an account? Sign up",
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