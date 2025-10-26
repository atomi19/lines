import 'package:flutter/material.dart';

Widget buildIconButton({
  required VoidCallback onTap,
  required IconData icon,
}) {
  return Container(
    decoration: BoxDecoration(
      color: Colors.grey.shade200,
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(
          color: const Color.fromARGB(26, 0, 0, 0),
          blurRadius: 4,
          offset: Offset(0, 2),
        )
      ]
    ),
    child: Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(8),
          child: Icon(icon),
        ),
      ),
    ),
  );
}