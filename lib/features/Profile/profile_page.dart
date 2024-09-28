import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  User? _getCurrentUser() {
    return FirebaseAuth.instance.currentUser;
  }

  Future<void> _deleteAccount(BuildContext context) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.delete(); 
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account deleted successfully')),
        );
        FirebaseAuth.instance.signOut();
        Navigator.of(context).pushReplacementNamed('/login'); // Update with your login route
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete account: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    User? user = _getCurrentUser();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Profile Information',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            if (user != null) ...[
              ListTile(
                leading: const Icon(Icons.email),
                title: Text('Email: ${user.email ?? 'No email available'}'),
              ),
            ] else ...[
              const Text('No user logged in.'),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
              },
              child: const Text('Edit Profile'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, 
              ),
              onPressed: () async {
                await _deleteAccount(context);
              },
              child: const Text('Delete Account'),
            ),
          ],
        ),
      ),
    );
  }
}
