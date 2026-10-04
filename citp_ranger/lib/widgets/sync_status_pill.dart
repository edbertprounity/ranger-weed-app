import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../state/app_controller.dart';

class SyncStatusPill extends StatefulWidget {
  const SyncStatusPill({super.key});

  @override
  State<SyncStatusPill> createState() => _SyncStatusPillState();
}

class _SyncStatusPillState extends State<SyncStatusPill> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();
    final online = controller.online;
    final syncing = controller.syncing;
    final label = syncing ? 'Syncing' : online ? 'Online' : 'Offline';
    final fill = online ? clearFill : const Color(0xFF3A2E1A);
    final foreground = online ? clearInk : pendingInk;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Material(
        color: fill,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: syncing ? null : () => controller.syncNow(manual: true),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (syncing)
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2, color: foreground),
                  )
                else if (online)
                  FadeTransition(
                    opacity: Tween<double>(begin: 0.35, end: 1).animate(_pulse),
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(color: foreground, shape: BoxShape.circle),
                    ),
                  )
                else
                  Icon(Icons.cloud_off, size: 14, color: foreground),
                const SizedBox(width: 6),
                Text(label, style: TextStyle(color: foreground, fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
