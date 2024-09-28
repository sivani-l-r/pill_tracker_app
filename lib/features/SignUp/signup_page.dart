import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
import 'package:pill_tracker/features/Home/home_page.dart';
import 'package:pill_tracker/features/Login/login_page.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  String _confirmPassword = '';
  

  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Sign Up'),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 50),
                _buildLogo(),
                const SizedBox(height: 40),
                _buildEmailField(),
                const SizedBox(height: 20),
                _buildPasswordField(),
                const SizedBox(height: 20),
                _buildConfirmPasswordField(),
                const SizedBox(height: 30),
                _buildSignupButton(),
                const SizedBox(height: 20),
                _buildLoginText(),
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

  Widget _buildPasswordField() {
    return TextFormField(
      decoration: const InputDecoration(
        labelText: 'Password',
        prefixIcon: Icon(Icons.lock),
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white70,
      ),
      obscureText: true,
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

  Widget _buildConfirmPasswordField() {
    return TextFormField(
      decoration: const InputDecoration(
        labelText: 'Confirm Password',
        prefixIcon: Icon(Icons.lock),
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white70,
      ),
      obscureText: true,
      onChanged: (value) {
        _confirmPassword = value;
      },
      validator: (value) {
        if (value != _password) {
          return 'Passwords do not match';
        }
        return null;
      },
    );
  }

  Widget _buildSignupButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : () {
          if (_formKey.currentState?.validate() == true) {
            _signup();
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
                'Sign Up',
                style: TextStyle(fontSize: 18,color: Colors.white),
              ),
      ),
    );
  }

  Widget _buildLoginText() {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      },
      child: const Text(
        "Already have an account? Login",
        style: TextStyle(
          color: Colors.blueAccent,
          fontSize: 16,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }

  Future<void> _signup() async {
    if (_password != _confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
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
      if (e.code == 'email-already-in-use') {
        message = 'Email is already in use';
      } else if (e.code == 'weak-password') {
        message = 'The password provided is too weak';
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
