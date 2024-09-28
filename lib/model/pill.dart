import 'package:flutter/material.dart';
class Pill {
  final String id;
  final String name;
  final TimeOfDay time;
  final String specification;
  final bool? taken; 

  Pill({
    required this.id,
    required this.name,
    required this.time,
    required this.specification,
    this.taken,
  });
}
