import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:vendor_app/features/auth/auth_provider.dart';
import 'package:vendor_app/features/orders/orders_provider.dart';
import 'package:vendor_app/core/utils/app_animations.dart';
import 'package:vendor_app/widgets/shimmer_widgets.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _rushModeEnabled = false;
  int _selectedPrepMins = 12;
  String _selectedQueueFilter = 'all';
  _QueueSort _queueSort = _QueueSort.readyFirst;

  List<int> get _prepSuggestions => _rushModeEnabled ? const [6, 8, 10] : const [10, 12, 15];

  String _normalizedStatus(dynamic order) {
    final status = (order['status'] as String? ?? '').toLowerCase();
    if (status == 'cancelled') return 'hold';
    return status.isEmpty ? 'accepted' : status;
  }

  List<dynamic> _applyQueueView(List<dynamic> orders) {
    final filtered = orders.where((order) {
      if (_selectedQueueFilter == 'all') return true;
      return _normalizedStatus(order) == _selectedQueueFilter;
    }).toList();

    filtered.sort((left, right) {
      switch (_queueSort) {
        case _QueueSort.newest:
          final leftCreated = DateTime.tryParse((left['created_at'] ?? '').toString()) ?? DateTime.fromMillisecondsSinceEpoch(0);
          final rightCreated = DateTime.tryParse((right['created_at'] ?? '').toString()) ?? DateTime.fromMillisecondsSinceEpoch(0);
          return rightCreated.compareTo(leftCreated);
        case _QueueSort.highestValue:
          final leftAmount = (left['total_amount'] as num?) ?? 0;
          final rightAmount = (right['total_amount'] as num?) ?? 0;
          return rightAmount.compareTo(leftAmount);
        case _QueueSort.readyFirst:
          const weight = {
            'ready': 0,
            'preparing': 1,
            'accepted': 2,
            'completed': 3,
            'hold': 4,
          };
          final leftWeight = weight[_normalizedStatus(left)] ?? 99;
          final rightWeight = weight[_normalizedStatus(right)] ?? 99;
          return leftWeight.compareTo(rightWeight);
      }
    });

    return filtered;
  }

  List<_QueueRailItem> _buildQueueRails(List<dynamic> orders) {
    final all = orders.length;
    int countFor(String status) => orders.where((order) => _normalizedStatus(order) == status).length;

    return [
      _QueueRailItem(id: 'all', label: 'All', count: all, color: Colors.black87),
      _QueueRailItem(id: 'accepted', label: 'Accepted', count: countFor('accepted'), color: Colors.blue),
      _QueueRailItem(id: 'preparing', label: 'Preparing', count: countFor('preparing'), color: Colors.orange),
      _QueueRailItem(id: 'ready', label: 'Ready', count: countFor('ready'), color: const Color(0xFF0D9488)),
      _QueueRailItem(id: 'hold', label: '86 Hold', count: countFor('hold'), color: Colors.red),
    ];
  }

  int _countPacingRisk(List<dynamic> orders, String risk) {
    return orders.where((order) => ((order['pacing'] as Map?)?['sla_risk'] ?? 'low') == risk).length;
  }

  String _nextStatus(String currentStatus) {
    switch (currentStatus.toLowerCase()) {
      case 'accepted':
        return 'preparing';
      case 'preparing':
        return 'ready';
      case 'ready':
        return 'completed';
      default:
        return 'accepted';
    }
  }

  Future<void> _applyOrderStatus(
    BuildContext context,
    String orderId,
    String nextStatus,
    String successLabel,
  ) async {
    if (orderId.isEmpty) return;
    final didUpdate = await ref.read(ordersProvider.notifier).updateStatus(orderId, nextStatus);
    if (!context.mounted) return;
    if (!didUpdate) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update order status')),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(successLabel)),
    );
  }

  Future<void> _confirmHoldAction(
    BuildContext context, {
    required String orderId,
    required String currentStatus,
    required String compactId,
    required int elapsedMinutes,
    required int recommendedPrepMinutes,
  }) async {
    if (orderId.isEmpty || currentStatus == 'cancelled' || currentStatus == 'completed') {
      return;
    }

    final shouldHold = await showModalBottomSheet<bool>(
      context: context,
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
                Text(
                  'Confirm 86 Hold',
                  style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  'Order #$compactId will be moved to hold. Use this for stock-outs or queue exceptions, not routine pacing.',
                  style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[700]),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.red),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Elapsed ${elapsedMinutes}m • Suggested prep ${recommendedPrepMinutes}m',
                          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(sheetContext).pop(false),
                        child: const Text('Keep Order'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(sheetContext).pop(true),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade400),
                        child: const Text('Confirm 86'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (shouldHold != true || !context.mounted) return;

    final didUpdate = await ref.read(ordersProvider.notifier).updateStatus(orderId, 'cancelled');
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    if (!didUpdate) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Failed to move order to 86 HOLD')),
      );
      return;
    }
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text('Order #$compactId moved to 86 HOLD'),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () {
            ref.read(ordersProvider.notifier).updateStatus(orderId, currentStatus);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text('Swift Vendor', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => context.push('/menu'),
            icon: const Icon(Icons.restaurant_menu),
          ),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF0D9488)),
              child: Center(
                child: Text(
                  'Swift Vendor',
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.gavel_rounded),
              title: const Text('Terms of Service'),
              onTap: () => context.push('/legal'),
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip_rounded),
              title: const Text('Privacy Policy'),
              onTap: () => context.push('/privacy'),
            ),
            const Spacer(),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () => ref.read(authProvider.notifier).logout(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.read(ordersProvider.notifier).fetchOrders(),
        color: const Color(0xFF0D9488),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Business Overview',
                style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ref.watch(ordersProvider).when(
                data: (orders) {
                  final count = orders.length;
                  final revenue = orders.fold<num>(0, (sum, o) => sum + ((o['total_amount'] ?? 0) as num));
                  return Row(
                    children: [
                      Expanded(
                        child: AppAnimations.staggeredList(
                          0,
                          _StatCard(title: 'Orders Today', value: '$count', color: Colors.blue),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: AppAnimations.staggeredList(
                          1,
                          _StatCard(title: 'Revenue Today', value: '₹${revenue.toInt()}', color: Colors.green),
                        ),
                      ),
                    ],
                  );
                },
                loading: () => Row(
                  children: const [
                    Expanded(child: DashboardStatShimmer()),
                    SizedBox(width: 16),
                    Expanded(child: DashboardStatShimmer()),
                  ],
                ),
                error: (_, __) => Row(
                  children: const [
                    Expanded(child: _StatCard(title: 'Orders Today', value: '-', color: Colors.blue)),
                    SizedBox(width: 16),
                    Expanded(child: _StatCard(title: 'Revenue Today', value: '-', color: Colors.green)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildRushModeStrip(),
              const SizedBox(height: 16),
              _buildPrepSuggestionStrip(),
              const SizedBox(height: 24),
              Text(
                'Active Orders',
                style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ref.watch(ordersProvider).when(
                data: (orders) {
                  final queueRails = _buildQueueRails(orders);
                  final visibleOrders = _applyQueueView(orders);

                  if (orders.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text('No active orders', style: GoogleFonts.poppins(color: Colors.grey[400], fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPacingSummary(orders),
                      const SizedBox(height: 14),
                      _buildGuardrailHint(),
                      const SizedBox(height: 14),
                      _buildQueueTriageRails(queueRails),
                      const SizedBox(height: 14),
                      _buildQueueToolbar(visibleOrders.length),
                      const SizedBox(height: 14),
                      if (visibleOrders.isEmpty)
                        _buildNoQueueMatches()
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: visibleOrders.length,
                          itemBuilder: (context, index) => AppAnimations.staggeredList(
                            index + 2,
                            _OrderListItem(
                              index: index,
                              order: visibleOrders[index],
                              rushModeEnabled: _rushModeEnabled,
                              selectedPrepMins: _selectedPrepMins,
                              nextStatusFor: _nextStatus,
                              onApplyStatus: (orderId, nextStatus, successLabel) =>
                                  _applyOrderStatus(context, orderId, nextStatus, successLabel),
                              onHoldAction: ({
                                required orderId,
                                required currentStatus,
                                required compactId,
                                required elapsedMinutes,
                                required recommendedPrepMinutes,
                              }) => _confirmHoldAction(
                                context,
                                orderId: orderId,
                                currentStatus: currentStatus,
                                compactId: compactId,
                                elapsedMinutes: elapsedMinutes,
                                recommendedPrepMinutes: recommendedPrepMinutes,
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
                loading: () => ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 3,
                  itemBuilder: (_, __) => const OrderCardShimmer(),
                ),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRushModeStrip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _rushModeEnabled ? const Color(0xFF0D9488) : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _rushModeEnabled ? Icons.bolt_rounded : Icons.bolt_outlined,
            color: const Color(0xFF0D9488),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rush Mode',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                ),
                Text(
                  _rushModeEnabled
                      ? 'Fast prep defaults active. Swipe right to progress queue quickly.'
                      : 'Enable to prioritize speed presets during peak demand.',
                  style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Switch(
            value: _rushModeEnabled,
            activeThumbColor: const Color(0xFF0D9488),
            onChanged: (value) => setState(() => _rushModeEnabled = value),
          ),
        ],
      ),
    );
  }

  Widget _buildPrepSuggestionStrip() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Prep-Time Suggestions',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _prepSuggestions.map((mins) {
              final selected = mins == _selectedPrepMins;
              return ChoiceChip(
                label: Text('$mins min'),
                selected: selected,
                onSelected: (_) => setState(() => _selectedPrepMins = mins),
                selectedColor: const Color(0xFF0D9488),
                labelStyle: GoogleFonts.poppins(
                  color: selected ? Colors.white : Colors.black,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildQueueTriageRails(List<_QueueRailItem> rails) {
    return SizedBox(
      height: 82,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: rails.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final rail = rails[index];
          final selected = rail.id == _selectedQueueFilter;
          return GestureDetector(
            onTap: () => setState(() => _selectedQueueFilter = rail.id),
            child: Container(
              width: 122,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: selected ? rail.color : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: selected ? rail.color : Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    rail.label,
                    style: GoogleFonts.poppins(
                      color: selected ? Colors.white : Colors.black87,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${rail.count}',
                    style: GoogleFonts.poppins(
                      color: selected ? Colors.white : rail.color,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPacingSummary(List<dynamic> orders) {
    final highRisk = _countPacingRisk(orders, 'high');
    final mediumRisk = _countPacingRisk(orders, 'medium');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: _MiniPacingStat(
              label: 'Urgent',
              value: '$highRisk',
              color: Colors.red.shade400,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _MiniPacingStat(
              label: 'Watch',
              value: '$mediumRisk',
              color: Colors.orange.shade400,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _MiniPacingStat(
              label: 'Prep Target',
              value: '$_selectedPrepMins m',
              color: const Color(0xFF0D9488),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuardrailHint() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.shield_outlined, color: Colors.grey[700]),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Protected 86 swipe: left swipe now requires confirmation and supports undo recovery.',
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[700], fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQueueToolbar(int visibleCount) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$visibleCount in view',
            style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
        ChoiceChip(
          label: const Text('Ready First'),
          selected: _queueSort == _QueueSort.readyFirst,
          onSelected: (_) => setState(() => _queueSort = _QueueSort.readyFirst),
        ),
        ChoiceChip(
          label: const Text('Newest'),
          selected: _queueSort == _QueueSort.newest,
          onSelected: (_) => setState(() => _queueSort = _QueueSort.newest),
        ),
        ChoiceChip(
          label: const Text('High Value'),
          selected: _queueSort == _QueueSort.highestValue,
          onSelected: (_) => setState(() => _queueSort = _QueueSort.highestValue),
        ),
      ],
    );
  }

  Widget _buildNoQueueMatches() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.filter_alt_off_rounded, color: Colors.grey[500]),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'No orders match this queue filter yet. Try another rail or sort mode.',
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

enum _QueueSort { readyFirst, newest, highestValue }

class _QueueRailItem {
  final String id;
  final String label;
  final int count;
  final Color color;

  const _QueueRailItem({
    required this.id,
    required this.label,
    required this.count,
    required this.color,
  });
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _StatCard({required this.title, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 8),
          Text(value, style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

class _OrderListItem extends ConsumerWidget {
  final int index;
  final dynamic order;
  final bool rushModeEnabled;
  final int selectedPrepMins;
  final String Function(String) nextStatusFor;
  final Future<void> Function(String orderId, String nextStatus, String successLabel) onApplyStatus;
  final Future<void> Function({
    required String orderId,
    required String currentStatus,
    required String compactId,
    required int elapsedMinutes,
    required int recommendedPrepMinutes,
  }) onHoldAction;

  const _OrderListItem({
    required this.index,
    required this.order,
    required this.rushModeEnabled,
    required this.selectedPrepMins,
    required this.nextStatusFor,
    required this.onApplyStatus,
    required this.onHoldAction,
  });

  static const _statusFlow = <String>[
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
    final pacing = (order['pacing'] as Map?)?.cast<dynamic, dynamic>() ?? const {};
    final slaRisk = (pacing['sla_risk'] ?? 'low').toString();
    final recommendedPrepMinutes = pacing['recommended_prep_minutes'] ?? selectedPrepMins;
    final elapsedMinutes = pacing['elapsed_minutes'] ?? 0;
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
                    '${order['status'].toString().toUpperCase()} • ₹${order['total_amount']}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w600),
                  ),
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
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (nextStatus) async {
                if (orderId.isEmpty || nextStatus == currentStatus) return;
                await onApplyStatus(orderId, nextStatus, 'Order updated to ${nextStatus.toUpperCase()}');
              },
              itemBuilder: (context) {
                return _statusFlow.map((status) {
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
    );
  }
}

class _MiniPacingStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniPacingStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.poppins(fontSize: 11, color: Colors.black54, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}
