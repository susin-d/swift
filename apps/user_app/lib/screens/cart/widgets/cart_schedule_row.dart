import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';

class CartScheduleRow extends StatelessWidget {
  const CartScheduleRow({
    super.key,
    required this.scheduledFor,
    required this.onSelectSchedule,
  });

  final DateTime? scheduledFor;
  final VoidCallback onSelectSchedule;

  @override
  Widget build(BuildContext context) {
    final scheduledLabel = scheduledFor == null
        ? 'ASAP'
        : DateFormat('EEE, MMM d - hh:mm a').format(scheduledFor!);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.schedule_rounded, color: AppColors.info, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Delivery time', style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(
                  scheduledLabel,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onSelectSchedule,
            child: Text(scheduledFor == null ? 'Schedule' : 'Change'),
          ),
        ],
      ),
    );
  }
}
