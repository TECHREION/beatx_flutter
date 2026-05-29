import 'package:flutter/material.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              // Logo
              Center(
                child: RichText(
                  text: const TextSpan(
                    children: [
                      TextSpan(
                        text: "BEAT",
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      // TextSpan(
                      //   text: "X",
                      //   style: TextStyle(
                      //     fontSize: 32,
                      //     fontWeight: FontWeight.bold,
                      //     foreground: Paint()
                      //       ..shader = const LinearGradient(
                      //         colors: [Color(0xFF00D4FF), Color(0xFF9B4DFF)],
                      //       ).createShader(const Rect.fromLTWH(0, 0, 200, 70)),
                      //   ),
                      // ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  "Welcome to BEATX",
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ),
              const SizedBox(height: 40),

              const Text(
                "Create Your Account",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 30),

              _buildTextField("Full Name", Icons.person_outline),
              const SizedBox(height: 16),
              _buildTextField("EMAIL ADDRESS", Icons.email_outlined),
              const SizedBox(height: 16),
              _buildTextField("PASSWORD", Icons.lock_outline, obscureText: true),

              const SizedBox(height: 30),

              // Sign Up Button
              Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00FF85), Color(0xFF00B8FF)],
                  ),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Center(
                  child: Text(
                    "Sign Up",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                ),
              ),

              const SizedBox(height: 20),
              const Center(child: Text("OR CONNECT WITH", style: TextStyle(color: Colors.white54))),
              const SizedBox(height: 20),

              // Social Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _socialButton("assets/apple.png"),
                  const SizedBox(width: 20),
                  _socialButton("assets/google.png"),
                  const SizedBox(width: 20),
                  _socialButton("assets/facebook.png"),
                ],
              ),

              const Spacer(),
              Center(
                child: TextButton(
                  onPressed: () {},
                  child: const Text(
                    "Already Have an Account? Log in",
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, IconData icon, {bool obscureText = false}) {
    return TextField(
      obscureText: obscureText,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: label == "Full Name" ? "Name" : label.toLowerCase(),
        hintStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: Colors.white54),
        filled: true,
        fillColor: const Color(0xFF1C1C1C),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _socialButton(String asset) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1C),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Image.asset(asset, height: 28),
    );
  }
}