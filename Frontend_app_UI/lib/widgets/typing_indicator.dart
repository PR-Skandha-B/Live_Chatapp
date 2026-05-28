import 'package:flutter/material.dart';
import 'dart:math' as math;

class TypingIndicator extends StatefulWidget {
  final Set<String> typingUsers;

  const TypingIndicator({super.key, required this.typingUsers});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.typingUsers.isEmpty) return const SizedBox.shrink();

    String text;
    final users = widget.typingUsers.toList();
    if (users.length == 1) {
      text = '${users[0]} is typing';
    } else if (users.length == 2) {
      text = '${users[0]}, ${users[1]} are typing';
    } else {
      text = '${users.length} users are typing';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (index) {
                return AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    final delay = index * 0.2;
                    final value = (_controller.value - delay) % 1.0;
                    // Opacity animation for smooth blinking
                    final opacity = value < 0.5 ? 1.0 - (value * 2) : (value - 0.5) * 2;
                    return Opacity(
                      opacity: opacity.clamp(0.2, 1.0),
                      child: child,
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: CircleAvatar(
                      radius: 4, 
                      backgroundColor: Theme.of(context).primaryColor
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              text,
              style: const TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }
}
