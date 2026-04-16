import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../services/growth_service.dart';

class GrowthHubScreen extends StatefulWidget {
  const GrowthHubScreen({super.key, this.service});

  final GrowthService? service;

  @override
  State<GrowthHubScreen> createState() => _GrowthHubScreenState();
}

class _GrowthHubScreenState extends State<GrowthHubScreen> {
  late final GrowthService _service;
  bool _loading = true;
  String? _error;
  Map<String, dynamic> _spending = const {};
  Map<String, dynamic> _loyalty = const {};
  String? _referralCode;
  List<dynamic> _subscriptions = const [];
  List<dynamic> _refunds = const [];
  Map<String, dynamic> _entitlements = const {};
  Map<String, dynamic>? _deletion;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? GrowthService();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _service.getSpendingSummary(),
        _service.getLoyaltyTier(),
        _service.generateReferralCode(),
        _service.getSubscriptions(),
        _service.getEntitlements(),
        _service.getRefunds(),
        _service.getDeletionStatus(),
      ]);

      if (!mounted) return;
      setState(() {
        _spending = results[0] as Map<String, dynamic>;
        _loyalty = (results[1] as Map<String, dynamic>)['loyalty']
                as Map<String, dynamic>? ??
            {};
        _referralCode = ((results[2] as Map<String, dynamic>)['referral']
                as Map<String, dynamic>?)?['code']
            ?.toString();
        _subscriptions = results[3] as List<dynamic>;
        _entitlements = (results[4] as Map<String, dynamic>)['entitlements']
                as Map<String, dynamic>? ??
            {};
        _refunds = results[5] as List<dynamic>;
        _deletion = (results[6] as Map<String, dynamic>)['deletion']
            as Map<String, dynamic>?;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _redeemReferral() async {
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Redeem Referral'),
        content: TextField(
          controller: controller,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(labelText: 'Referral code'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Redeem'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _service.redeemReferralCode(controller.text.trim().toUpperCase());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Referral redeemed')),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Redeem failed: $e')),
      );
    }
  }

  Future<void> _scheduleDeletion() async {
    try {
      await _service.requestAccountDeletion();
      if (!mounted) return;
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account deletion scheduled')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to schedule deletion: $e')),
      );
    }
  }

  Future<void> _cancelDeletion() async {
    try {
      await _service.cancelDeletion();
      if (!mounted) return;
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Deletion cancelled')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to cancel deletion: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Growth Hub')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _card(
                        title: 'Spending Summary',
                        content:
                            'Total spent: Rs ${((_spending['summary'] as Map<String, dynamic>?)?['total_spent'] ?? 0)}\n'
                            'Total saved: Rs ${((_spending['summary'] as Map<String, dynamic>?)?['total_saved'] ?? 0)}\n'
                            'Orders: ${((_spending['summary'] as Map<String, dynamic>?)?['total_orders'] ?? 0)}',
                      ),
                      _card(
                        title: 'Referral',
                        content:
                            'Your code: ${_referralCode ?? 'Not available'}',
                        actions: [
                          OutlinedButton(
                            onPressed: _redeemReferral,
                            child: const Text('Redeem Code'),
                          ),
                        ],
                      ),
                      _card(
                        title: 'Loyalty',
                        content:
                            'Tier: ${_loyalty['tier'] ?? 'bronze'}\nPoints: ${_loyalty['points'] ?? 0}',
                      ),
                      _card(
                        title: 'Subscriptions',
                        content: _subscriptions.isEmpty
                            ? 'No active subscriptions'
                            : 'Active subscriptions: ${_subscriptions.length}',
                      ),
                      _card(
                        title: 'Entitlements',
                        content:
                            'Fee waiver: ${_entitlements['delivery_fee_waiver'] == true ? 'Yes' : 'No'}\n'
                            'Priority support: ${_entitlements['priority_support'] == true ? 'Yes' : 'No'}\n'
                            'Exclusive promos: ${_entitlements['exclusive_promos'] == true ? 'Yes' : 'No'}',
                      ),
                      _card(
                        title: 'Refund Requests',
                        content:
                            _refunds.isEmpty ? 'No refunds yet' : 'Refunds: ${_refunds.length}',
                      ),
                      _card(
                        title: 'Account Deletion',
                        content: _deletion == null
                            ? 'No deletion scheduled'
                            : 'Status: ${_deletion!['status']}\nDelete after: ${_deletion!['delete_after']}',
                        actions: [
                          OutlinedButton(
                            onPressed: _deletion == null
                                ? _scheduleDeletion
                                : _cancelDeletion,
                            child: Text(
                              _deletion == null
                                  ? 'Schedule Deletion'
                                  : 'Cancel Deletion',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _card({
    required String title,
    required String content,
    List<Widget> actions = const [],
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(content),
            if (actions.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(spacing: 8, children: actions),
            ],
          ],
        ),
      ),
    );
  }
}
