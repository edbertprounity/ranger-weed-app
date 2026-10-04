import 'package:flutter/material.dart';

import '../core/theme.dart';

enum BadgeTone { overdue, pending, clear }

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.label, required this.tone});

  final String label;
  final BadgeTone tone;

  @override
  Widget build(BuildContext context) {
    final (fill, foreground) = switch (tone) {
      BadgeTone.overdue => (overdueFill, overdueInk),
      BadgeTone.pending => (pendingFill, pendingInk),
      BadgeTone.clear => (clearFill, clearInk),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: fill, borderRadius: BorderRadius.circular(999)),
      child: Text(
        label,
        style: TextStyle(color: foreground, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
