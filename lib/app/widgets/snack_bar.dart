import 'package:flutter/material.dart';

shoSnackBar(BuildContext context, String text){
  return ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(text),
    ),
  );

}