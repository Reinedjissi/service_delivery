import 'package:flutter/material.dart';
import 'onbeading_screen.dart';

// Method to create an image container
Widget buildImageContainer(
    Color color,
    String title,
    String subtitle,
    String imagePath,
    ) {
  return Container(
    color: color,
    child: Column(
      children: [
        Image.asset(
          imagePath,
          fit: BoxFit.cover,
          width: double.infinity,
        ),
        const SizedBox(height: 59),
        Text(
          title,
          style: const TextStyle(
            color: Colors.deepPurple,
            fontSize: 30,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 50),
          child: Text(
            subtitle,
            style: const TextStyle(color: Colors.black, fontSize: 17),
          ),
        ),
      ],
    ),
  );
}