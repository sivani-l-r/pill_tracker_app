import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddPillForm extends StatefulWidget {
  @override
  _AddPillFormState createState() => _AddPillFormState();
}

class _AddPillFormState extends State<AddPillForm> {
  final _formKey = GlobalKey<FormState>();

  String? _pillName;
  TimeOfDay? _selectedTime;
  String? _specification;
  bool _isSaving = false;

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _savePillToFirestore() async {
    setState(() {
      _isSaving = true;
    });

    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No user logged in. Please log in first.')),
      );
      setState(() {
        _isSaving = false;
      });
      return;
    }

    final Map<String, dynamic> pillData = {
      'name': _pillName,
      'time': '${_selectedTime?.hour}:${_selectedTime?.minute}',
      'specification': _specification,
      'created_at': Timestamp.now(),
    };

    try {
      await FirebaseFirestore.instance
          .collection('users') 
          .doc(user.uid)        
          .collection('pills')  
          .add(pillData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pill saved successfully!')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving pill: $e')),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            TextFormField(
              decoration: InputDecoration(
                labelText: 'Pill Name',
                labelStyle: TextStyle(color: Colors.grey[600], fontSize: 16),
                filled: true,
                fillColor: Colors.grey[300],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a pill name';
                }
                return null;
              },
              onSaved: (value) {
                _pillName = value;
              },
            ),
            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedTime != null
                      ? 'Time: ${_selectedTime!.format(context)}'
                      : 'Select Time',
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                ),
                ElevatedButton(
                  onPressed: () => _selectTime(context),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 34),
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Pick Time', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
            const SizedBox(height: 24),

            TextFormField(
              decoration: InputDecoration(
                labelText: 'Specification (e.g., after lunch)',
                labelStyle: TextStyle(color: Colors.grey[600], fontSize: 16),
                filled: true,
                fillColor: Colors.grey[300],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
              ),
              onSaved: (value) {
                _specification = value;
              },
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving
                    ? null
                    : () {
                        if (_formKey.currentState!.validate()) {
                          _formKey.currentState!.save(); 
                          _savePillToFirestore(); 
                        }
                      },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  shadowColor: Colors.blueAccent.withOpacity(0.4),
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Save Pill',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
