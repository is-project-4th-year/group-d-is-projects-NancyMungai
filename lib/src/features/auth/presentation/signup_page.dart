import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:naihydro/src/features/auth/presentation/data/auth_service.dart';
import 'package:naihydro/src/features/auth/presentation/login_page.dart';
import '../../common/widgets/primary_button.dart';

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
  final farmCtrl = TextEditingController();
  final auth = AuthService();
  String error = "";
  bool loading = false;

  @override
  void dispose() {
    emailCtrl.dispose();
    passCtrl.dispose();
    confirmCtrl.dispose();
    farmCtrl.dispose();
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
      await auth.signUp(emailCtrl.text.trim(), passCtrl.text.trim());
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
}finally {
      if (mounted) setState(() => loading = false);
    }
  }

  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header
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

          // Form
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
                        "Create Account",
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
                        "Join the smart farming revolution",
                        style: GoogleFonts.poppins(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 20),
                  TextFormField(
  controller: farmCtrl,
  decoration: InputDecoration(
    labelText: "Username",
    prefixIcon: const Icon(Icons.agriculture_outlined),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
  ),
      validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your farm name';
                            }
                            if (value.length < 2) {
                              return 'Farm name must be at least 2 characters';
                            }
                            return null;
                          },
),

                      const SizedBox(height: 16),
                    TextFormField(
  controller: emailCtrl,
  keyboardType: TextInputType.emailAddress,
  decoration: InputDecoration(
    labelText: "Email",
    prefixIcon: const Icon(Icons.email_outlined),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
  ),
  validator: (value) {
    if (value == null || value.isEmpty) return 'Please enter your email';
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(value)) return 'Enter a valid email address';
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
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
  ),
  validator: (value) {
    if (value == null || value.isEmpty) return 'Please enter a password';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  },
),

                      const SizedBox(height: 16),
                    TextFormField(
  controller: confirmCtrl,
  obscureText: true,
  decoration: InputDecoration(
    labelText: "Confirm Password",
    prefixIcon: const Icon(Icons.lock_outline),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
  ),
  validator: (value) {
    if (value == null || value.isEmpty) return 'Please confirm your password';
    if (value != passCtrl.text) return 'Passwords do not match';
    return null;
  },
),

                      const SizedBox(height: 20),
                      PrimaryButton(
                        label: "Create Account",
                        onPressed: _onSignUp,
                      ),
                      if (error.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(error,
                              style: const TextStyle(color: Colors.red)),
                        ),
                      const SizedBox(height: 16),
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
  child: const Text("Already have an account? Sign in"),
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
