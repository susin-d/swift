import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'order_list_item.dart';

Future<void> openOrderDetailsSheet(BuildContext context, dynamic order) async {
  final items = (order['order_items'] as List?) ?? const [];
  final scheduledRaw = order['scheduled_for']?.toString();
  final scheduledFor = scheduledRaw == null ? null : DateTime.tryParse(scheduledRaw);
  final scheduledLabel = scheduledFor == null
      ? null
      : DateFormat('EEE, MMM d - hh:mm a').format(scheduledFor.toLocal());
  final deliveryMode = order['delivery_mode']?.toString() ?? 'standard';
  final buildingName = order['campus_buildings']?['name']?.toString();
  final roomLabel = order['delivery_room']?.toString();
  final handoffCode = order['handoff_code']?.toString();
  final quietMode = order['quiet_mode'] == true;
  final handoffStatus = order['handoff_status']?.toString() ?? 'pending';
  final proofUrl = order['handoff_proof_url']?.toString();
  final orderId = order['id']?.toString() ?? '';

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Order Details', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              if (scheduledLabel != null) ...[
                Text('Scheduled for: $scheduledLabel', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
              ],
              if (deliveryMode == 'class') ...[
                Text(
                  'Class delivery ${buildingName ?? ''}${roomLabel == null ? '' : ' - $roomLabel'}',
                  style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                if (handoffCode != null) ...[
                  const SizedBox(height: 6),
                  Text('Handoff code: $handoffCode', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
                ],
                if (quietMode) ...[
                  const SizedBox(height: 6),
                  Text('Quiet mode enabled', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
                ],
                if (proofUrl != null && proofUrl.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text('Proof URL: $proofUrl', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
                ],
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    buildHandoffChip(context, orderId, 'arrived_building', handoffStatus == 'arrived_building'),
                    buildHandoffChip(context, orderId, 'arrived_class', handoffStatus == 'arrived_class'),
                    buildHandoffChip(
                      context,
                      orderId,
                      'delivered',
                      handoffStatus == 'delivered',
                      requiresProof: true,
                      existingProofUrl: proofUrl,
                    ),
                    buildHandoffChip(
                      context,
                      orderId,
                      'failed',
                      handoffStatus == 'failed',
                      requiresProof: true,
                      existingProofUrl: proofUrl,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              if (items.isEmpty)
                const Text('No items found for this order.')
              else
                ...items.map((item) {
                  final name = item['menu_items']?['name'] ?? 'Item';
                  final qty = item['quantity'] ?? 1;
                  final price = item['unit_price'] ?? 0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text('$name x$qty')),
                        Text('Rs ${price.toString()}'),
                      ],
                    ),
                  );
                }),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total', style: TextStyle(fontWeight: FontWeight.w700)),
                  Text('Rs ${order['total_amount'] ?? 0}', style: const TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
