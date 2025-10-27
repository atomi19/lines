import 'package:flutter/material.dart';

// build text button
Widget buildTextButton({
  required Color color,
  required Color hoverColor,
  required Color splashColor,
  required String buttonText,
  required Color buttonTextColor,
  required VoidCallback onTap,
}) {
  return Material(
    color: color,
    borderRadius: BorderRadius.circular(10),
    child: InkWell(
      borderRadius: BorderRadius.circular(10),
      hoverColor: hoverColor,
      splashColor: splashColor,
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Text(buttonText, style: TextStyle(color: buttonTextColor, fontSize: 15)),
      ),
    ),
  );
}

// build icon button
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