import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:naihydro/src/features/auth/presentation/data/auth_service.dart';
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
        widget.onSuccess();
      } else {
        setState(() => error = "Sign in failed");
      }
    } catch (e) {
      setState(() => error = e.toString());
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
                      TextField(
                        controller: emailCtrl,
                        decoration: InputDecoration(
                          labelText: "Email",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: passCtrl,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: "Password",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
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
                          child: Text(error,
                              style: const TextStyle(color: Colors.red)),
                        ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () {
                          // navigate to signup
                        },
                        child: const Text("Don't have an account? Sign up"),
                      ),
                    ],
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
