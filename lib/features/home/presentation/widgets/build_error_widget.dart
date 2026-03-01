import 'package:flutter/material.dart';

Widget buildErrorWidget(String message) => Padding(
  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
  child: Text(
    'Error: $message',
    style: const TextStyle(color: Colors.redAccent, fontSize: 12),
  ),
);
