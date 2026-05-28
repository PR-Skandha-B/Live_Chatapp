import 'package:flutter/material.dart';

class UserAvatar extends StatelessWidget {
  final String username;
  final double size;

  const UserAvatar({
    super.key,
    required this.username,
    this.size = 36,
  });

  Color _getColor() {
    final int hash = username.hashCode;
    return Color((hash & 0xFFFFFF) + 0xFF000000).withOpacity(1.0);
  }

  @override
  Widget build(BuildContext context) {
    final String initial = username.isNotEmpty ? username[0].toUpperCase() : '?';

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _getColor(),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.5,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
