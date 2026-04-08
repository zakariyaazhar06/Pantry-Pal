import 'package:flutter/material.dart';
import 'services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _auth = AuthService();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool _isLogin = true;
  String _error = '';

  Future<void> _submit() async {
    try {
      if (_isLogin) {
        await _auth.signIn(_email.text.trim(), _password.text.trim());
      } else {
        await _auth.signUp(_email.text.trim(), _password.text.trim());
      }
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2C3344),
      body: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Pantry Pal",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold)),
            const Text("Your smart food companion",
                style: TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 50),
            TextField(
              controller: _email,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration("Email"),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _password,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration("Password"),
            ),
            const SizedBox(height: 10),
            if (_error.isNotEmpty)
              Text(_error, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFADC178),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                ),
                child: Text(_isLogin ? "Sign In" : "Sign Up",
                    style: const TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 15),
            Center(
              child: TextButton(
                onPressed: () => setState(() => _isLogin = !_isLogin),
                child: Text(
                    _isLogin
                        ? "Don't have an account? Sign Up"
                        : "Already have an account? Sign In",
                    style: const TextStyle(color: Colors.white70)),
              ),
            )
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white38),
      filled: true,
      fillColor: Colors.white12,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none),
    );
  }
}