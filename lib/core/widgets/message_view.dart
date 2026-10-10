import 'package:flutter/material.dart';

/// หน้า/กล่องข้อความกลางจอ (ไอคอน + ข้อความ + ปุ่มเสริม) ใช้ตอน error / ว่าง / ไม่มีสิทธิ์
class MessageView extends StatelessWidget {
  const MessageView({
    super.key,
    required this.icon,
    required this.message,
    this.title,
    this.actions = const [],
  });

  final IconData icon;
  final String? title;
  final String message;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            if (title != null) ...[
              Text(
                title!,
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
            ],
            Text(message, textAlign: TextAlign.center),
            for (final a in actions) ...[const SizedBox(height: 16), a],
          ],
        ),
      ),
    );
  }
}
