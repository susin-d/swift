import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../orders/handoff_service.dart';

class OrderListItem extends ConsumerWidget {
  final int index;
  final dynamic order;
  final bool rushModeEnabled;
  final int selectedPrepMins;
  final String Function(String) nextStatusFor;
  final bool trackingActive;
  final bool trackingBusy;
  final String? trackingLabel;
  final VoidCallback onToggleTracking;
  final VoidCallback onOpenDetails;
  final Future<void> Function(String orderId, String nextStatus, String successLabel) onApplyStatus;
  final Future<void> Function({
    required String orderId,
    required String currentStatus,
    required String compactId,
    required int elapsedMinutes,
    required int recommendedPrepMinutes,
  }) onHoldAction;

  const OrderListItem({
    super.key,
    required this.index,
    required this.order,
    required this.rushModeEnabled,
    required this.selectedPrepMins,
    required this.nextStatusFor,
    required this.trackingActive,
    required this.trackingBusy,
    required this.trackingLabel,
    required this.onToggleTracking,
    required this.onOpenDetails,
    required this.onApplyStatus,
    required this.onHoldAction,
  });

  static const statusFlow = <String>[
    'accepted',
    'preparing',
    'ready',
    'completed',
    'cancelled',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderId = order['id'] as String? ?? '';
    final currentStatus = (order['status'] as String? ?? '').toLowerCase();
    final nextStatus = nextStatusFor(currentStatus);
    final compactId = orderId.substring(0, orderId.length > 8 ? 8 : orderId.length).toUpperCase();
    final canTrack = currentStatus != 'completed' && currentStatus != 'cancelled';
    final pacing = (order['pacing'] as Map?)?.cast<dynamic, dynamic>() ?? const {};
    final slaRisk = (pacing['sla_risk'] ?? 'low').toString();
    final recommendedPrepMinutes = pacing['recommended_prep_minutes'] ?? selectedPrepMins;
    final elapsedMinutes = pacing['elapsed_minutes'] ?? 0;
    final scheduledRaw = order['scheduled_for']?.toString();
    final scheduledFor = scheduledRaw == null ? null : DateTime.tryParse(scheduledRaw);
    final scheduledLabel = scheduledFor == null
        ? null
        : DateFormat('EEE, MMM d - hh:mm a').format(scheduledFor.toLocal());
    final deliveryMode = order['delivery_mode']?.toString() ?? 'standard';
    final buildingName = order['campus_buildings']?['name']?.toString();
    final roomLabel = order['delivery_room']?.toString();
    final riskColor = switch (slaRisk) {
      'high' => Colors.red.shade400,
      'medium' => Colors.orange.shade400,
      _ => const Color(0xFF0D9488),
    };
    final riskLabel = switch (slaRisk) {
      'high' => 'URGENT',
      'medium' => 'WATCH',
      _ => 'ON TRACK',
    };

    return Dismissible(
      key: ValueKey('order-$orderId-$index'),
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF0D9488),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerLeft,
        child: Text(
          'Mark ${nextStatus.toUpperCase()}',
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      secondaryBackground: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        child: Text(
          '86 HOLD',
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      confirmDismiss: (direction) async {
        if (orderId.isEmpty) return false;
        if (currentStatus == 'completed' || currentStatus == 'cancelled') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Order #$compactId is locked from swipe actions')),
          );
          return false;
        }

        if (direction == DismissDirection.startToEnd) {
          await onApplyStatus(orderId, nextStatus, 'Order #$compactId -> ${nextStatus.toUpperCase()}');
        } else {
          await onHoldAction(
            orderId: orderId,
            currentStatus: currentStatus,
            compactId: compactId,
            elapsedMinutes: elapsedMinutes,
            recommendedPrepMinutes: (recommendedPrepMinutes as num).toInt(),
          );
        }
        return false;
      },
      child: InkWell(
        onTap: onOpenDetails,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 5)],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #$compactId',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${order['status'].toString().toUpperCase()} - Rs ${order['total_amount']}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w600),
                    ),
                    if (scheduledLabel != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Scheduled: $scheduledLabel',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w600),
                      ),
                    ],
                    if (deliveryMode == 'class') ...[
                      const SizedBox(height: 4),
                      Text(
                        'Class delivery ${buildingName ?? ''}${roomLabel == null ? '' : ' - $roomLabel'}',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w600),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      rushModeEnabled
                          ? 'Rush prep target: $selectedPrepMins min'
                          : 'Suggested prep target: $selectedPrepMins min',
                      style: TextStyle(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: riskColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            riskLabel,
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: riskColor),
                          ),
                        ),
                        Text(
                          'Elapsed ${elapsedMinutes}m',
                          style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w600),
                        ),
                        Text(
                          'Suggested ${recommendedPrepMinutes}m',
                          style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: canTrack ? onToggleTracking : null,
                          icon: Icon(
                            trackingActive ? Icons.location_off_rounded : Icons.location_on_rounded,
                            size: 16,
                          ),
                          label: Text(trackingActive ? 'Stop live' : 'Start live'),
                        ),
                        const SizedBox(width: 10),
                        if (trackingActive)
                          Expanded(
                            child: Text(
                              trackingBusy ? 'Updating location...' : (trackingLabel ?? 'Live tracking'),
                              style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (nextStatus) async {
                  if (orderId.isEmpty || nextStatus == currentStatus) return;
                  await onApplyStatus(orderId, nextStatus, 'Order updated to ${nextStatus.toUpperCase()}');
                },
                itemBuilder: (context) {
                  return statusFlow.map((status) {
                    final selected = status == currentStatus;
                    return PopupMenuItem<String>(
                      value: status,
                      enabled: !selected,
                      child: Row(
                        children: [
                          if (selected)
                            const Icon(Icons.check_rounded, size: 16)
                          else
                            const SizedBox(width: 16),
                          const SizedBox(width: 8),
                          Text(status.toUpperCase()),
                        ],
                      ),
                    );
                  }).toList();
                },
                child: ElevatedButton(
                  onPressed: null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D9488),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFF0D9488),
                    disabledForegroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: const Size(0, 0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Update'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget buildHandoffChip(
  BuildContext context,
  String orderId,
  String status,
  bool active, {
  bool requiresProof = false,
  String? existingProofUrl,
}) {
  final label = status.replaceAll('_', ' ').toUpperCase();
  return ChoiceChip(
    selected: active,
    label: Text(label, style: const TextStyle(fontSize: 11)),
    onSelected: (value) async {
      if (orderId.isEmpty) return;
      try {
        String? proofUrl = existingProofUrl;
        if (requiresProof) {
          proofUrl = await requestProofUrl(context, existingProofUrl);
          if (proofUrl == null || proofUrl.trim().isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Proof URL is required for this handoff status.')),
            );
            return;
          }
        }

        await HandoffService().updateHandoff(
          orderId,
          status,
          proofUrl: proofUrl?.trim().isEmpty == true ? null : proofUrl?.trim(),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Handoff updated: $label')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update handoff: $e')),
        );
      }
    },
  );
}

Future<String?> requestProofUrl(BuildContext context, String? existing) async {
  final controller = TextEditingController(text: existing ?? '');

  return showDialog<String?>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Add proof URL'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Proof URL',
            hintText: 'https://...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(null),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      );
    },
  );
}
