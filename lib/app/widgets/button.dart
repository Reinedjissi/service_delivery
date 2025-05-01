import 'package:flutter/material.dart';

class MyButton extends StatelessWidget {
  final VoidCallback onTab;
  final String text;

  const MyButton({
    Key? key,
    required this.onTab, // Marquer comme required
    required this.text,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTab,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: ShapeDecoration(
            color: Colors.purple,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}