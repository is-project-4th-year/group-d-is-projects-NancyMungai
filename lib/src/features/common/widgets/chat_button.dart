// lib/src/features/chat/presentation/chat_button.dart
import 'package:flutter/material.dart';

class ChatButton extends StatefulWidget {
  final bool isOpen;
  final VoidCallback onToggle;

  const ChatButton({super.key, required this.isOpen, required this.onToggle});

  @override
  State<ChatButton> createState() => _ChatButtonState();
}

class _ChatButtonState extends State<ChatButton> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 20,
      left: 20,
      child: MouseRegion(
        onEnter: (_) => setState(() => isHovered = true),
        onExit: (_) => setState(() => isHovered = false),
        child: GestureDetector(
          onTap: widget.onToggle,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (!widget.isOpen)
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: 1,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.4),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: isHovered ? 64 : 56,
                height: isHovered ? 64 : 56,
                decoration: BoxDecoration(
                  gradient: widget.isOpen
                      ? null
                      : const LinearGradient(
                          colors: [Colors.green, Colors.teal],
                        ),
                  color: widget.isOpen ? Colors.red : null,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Icon(
                  widget.isOpen ? Icons.close : Icons.chat_bubble_outline,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              if (isHovered && !widget.isOpen)
                Positioned(
                  left: 70,
                  child: AnimatedOpacity(
                    opacity: 1,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        "Ask NaiBot for help",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
