import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Firebase Auth import
import 'package:pill_tracker/features/Home/home_page.dart';
import 'package:pill_tracker/features/SignUp/signup_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>(); 
  String _email = '';
  String _password = '';

  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey, 
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 100), 
                _buildLogo(),
                const SizedBox(height: 50),
                _buildEmailField(),
                const SizedBox(height: 20),
                _buildPasswordField(),
                const SizedBox(height: 30),
                _buildLoginButton(),
                const SizedBox(height: 20),
                _buildSignupText(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: const [
        Icon(
          Icons.local_pharmacy,
          size: 80,
          color: Colors.blueAccent,
        ),
        SizedBox(height: 10),
        Text(
          'Pill Tracker',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  // Email Input Field
  Widget _buildEmailField() {
    return TextFormField(
      decoration: const InputDecoration(
        labelText: 'Email',
        prefixIcon: Icon(Icons.email),
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white70,
      ),
      keyboardType: TextInputType.emailAddress,
      onChanged: (value) {
        _email = value;
      },
      validator: (value) {
        if (value == null || value.isEmpty || !value.contains('@')) {
          return 'Please enter a valid email';
        }
        return null;
      },
    );
  }

  // Password Input Field
  Widget _buildPasswordField() {
    return TextFormField(
      decoration: const InputDecoration(
        labelText: 'Password',
        prefixIcon: Icon(Icons.lock),
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white70,
      ),
      obscureText: true, // Hide password text
      onChanged: (value) {
        _password = value;
      },
      validator: (value) {
        if (value == null || value.length < 6) {
          return 'Password must be at least 6 characters';
        }
        return null;
      },
    );
  }

  // Login Button
  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : () {
          if (_formKey.currentState?.validate() == true) {
            _login();
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueAccent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30.0),
          ),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              )
            : const Text(
                'Login',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
      ),
    );
  }

  Widget _buildSignupText() {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const SignupPage()),
        );
      },
      child: const Text(
        "Don't have an account? Sign up",
        style: TextStyle(
          color: Colors.blueAccent,
          fontSize: 16,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
    });

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: _email.trim(),
            password: _password.trim(),
          );

      if (userCredential.user != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = 'An error occurred, please try again';
      if (e.code == 'user-not-found') {
        message = 'No user found with this email';
      } else if (e.code == 'wrong-password') {
        message = 'Incorrect password';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
