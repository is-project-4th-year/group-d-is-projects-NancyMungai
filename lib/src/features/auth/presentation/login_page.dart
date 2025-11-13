import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:naihydro/src/features/auth/presentation/data/auth_service.dart';
import 'package:naihydro/src/features/auth/presentation/signup_page.dart';
import '../../common/services/notification_service.dart';
import '../../common/widgets/primary_button.dart';

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
          
          // Fetch user's farms
          final farmsSnapshot = await dbRef.get();

          if (farmsSnapshot.exists) {
            print('✅ Farms found for user');
            final farmsData = farmsSnapshot.value as Map;
            final firstFarm = farmsData.values.first as Map;

            final deviceId = firstFarm['deviceId'] ?? 'esp32-001';
            print('🌱 Found farm deviceId: $deviceId');

            // Initialize notifications with both deviceId and userId
            await NotificationService().initialize(deviceId, uid);
            print('✅ Notifications initialized for device: $deviceId');
          } else {
            print('⚠️ No farms found for user');
            
            // Initialize with default device but pass userId
            await NotificationService().initialize('esp32-001', uid);
          }
        } catch (notifError) {
          print('⚠️ Error initializing notifications: $notifError');
          // Don't block login if notifications fail
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header with background image
          Stack(
            children: [
              SizedBox(
                height: 200,
                width: double.infinity,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(24),
                  ),
                  child: Image.asset(
                    "assets/images/authpages.jpg",
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(24),
                  ),
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.4),
                      Colors.transparent,
                      Colors.black.withOpacity(0.4),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              Positioned(
                left: 16,
                top: 40,
                child: CircleAvatar(
                  backgroundColor: Colors.white24,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: widget.onBack,
                  ),
                ),
              ),
              Positioned(
                right: 16,
                top: 48,
                child: Text(
                  "naihydro",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          // Form Card
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 6,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: Column(
                      children: [
                        Text(
                          "Welcome Back",
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            foreground: Paint()
                              ..shader = const LinearGradient(
                                colors: [Colors.green, Colors.teal],
                              ).createShader(const Rect.fromLTWH(0, 0, 200, 70)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Sign in to monitor your hydroponic farm",
                          style: GoogleFonts.poppins(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: "Email",
                            prefixIcon: const Icon(Icons.email_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            final emailRegex =
                                RegExp(r'^[^@]+@[^@]+\.[^@]+');
                            if (!emailRegex.hasMatch(value)) {
                              return 'Enter a valid email address';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: passCtrl,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: "Password",
                            prefixIcon: const Icon(Icons.lock_outline),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
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
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: loading ? null : () => _onSignIn(),
                          child: loading
                              ? const CircularProgressIndicator()
                              : const Text('Sign In'),
                        ),
                        if (error.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              error,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        const SizedBox(height: 16),
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
                          child:
                              const Text("Don't have an account? Sign up"),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}