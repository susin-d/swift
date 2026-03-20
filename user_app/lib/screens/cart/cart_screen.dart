import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/payment_config.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/address_provider.dart';
import '../../models/address_model.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/cart_item_widget.dart';
import '../../services/payment_service.dart';
import '../../services/promo_service.dart';
import '../../providers/campus_provider.dart';
import '../../models/campus_building.dart';
import '../../providers/class_session_provider.dart';
import '../../models/class_session.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  static const int _etaMin = 14;
  static const int _etaMax = 24;
  late final Razorpay _razorpay;
  _PendingOrder? _pendingOrder;
  bool _paymentInProgress = false;
  final TextEditingController _promoController = TextEditingController();
  bool _promoApplying = false;
  String? _promoMessage;
  double _discountAmount = 0;
  String? _appliedPromoCode;
  DateTime? _scheduledFor;
  bool _deliverToClass = false;
  String? _selectedBuildingId;
  String? _selectedZoneId;
  String? _selectedClassSessionId;
  DateTime? _classStartAt;
  DateTime? _classEndAt;
  final TextEditingController _roomController = TextEditingController();
  final TextEditingController _instructionsController = TextEditingController();
  bool _quietMode = false;

  String _etaConfidenceLabel(int itemCount) {
    if (itemCount <= 2) return 'High confidence';
    if (itemCount <= 4) return 'Medium confidence';
    return 'Medium confidence';
  }

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    _promoController.dispose();
    _roomController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);
    final addressesAsync = ref.watch(addressesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Your Basket'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: cart.isEmpty
          ? _buildEmptyCart(context)
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                    itemCount: cart.length,
                    itemBuilder: (context, index) {
                      final item = cart.values.toList()[index];
                      return CartItemWidget(
                        item: item.item,
                        quantity: item.quantity,
                        onIncrement: () => cartNotifier.addItem(item.item),
                        onDecrement: () => cartNotifier.removeItem(item.item),
                      );
                    },
                  ),
                ),
                _buildSummary(context, addressesAsync),
              ],
            ),
    );
  }

  Widget _buildEmptyCart(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_basket_outlined, size: 80, color: AppColors.textMuted.withValues(alpha: 0.5)),
          const SizedBox(height: 24),
          const Text(
            'Your basket is empty',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add some delicious items from our vendors!',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => context.pop(),
            child: const Text('BACK TO MENU'),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(BuildContext context, AsyncValue<List<AddressModel>> addressesAsync) {
    final subtotal = ref.watch(cartProvider.notifier).totalAmount;
    final finalTotal = (subtotal - _discountAmount).clamp(0, double.infinity).toDouble();
    final buildingsAsync = ref.watch(campusBuildingsProvider);
    final classSessionsAsync = ref.watch(classSessionsProvider);
    final defaultAddress = addressesAsync.maybeWhen(
      data: (addresses) => addresses.firstWhere(
        (addr) => addr.isDefault,
        orElse: () => addresses.isNotEmpty ? addresses.first : const AddressModel(id: '', label: '', addressLine: '', isDefault: false),
      ),
      orElse: () => const AddressModel(id: '', label: '', addressLine: '', isDefault: false),
    );
    final hasAddress = defaultAddress.id.isNotEmpty;
    final hasAddressError = addressesAsync.hasError;
    final canPlaceOrder = _deliverToClass ? hasAddress : (hasAddress || hasAddressError);

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
            children: [
              _buildAddressRow(context, addressesAsync, defaultAddress, hasAddress),
              const SizedBox(height: 12),
              _buildClassDeliveryRow(context, buildingsAsync, classSessionsAsync),
              const SizedBox(height: 12),
              _buildScheduleRow(context),
              const SizedBox(height: 12),
              _buildFoodOrderRow(),
              const SizedBox(height: 12),
              _buildPromoRow(context, subtotal),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Subtotal',
                  style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                ),
                Text(
                  '\u20B9${subtotal.toInt()}',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                ),
              ],
            ),
            if (_discountAmount > 0) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Promo discount',
                    style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '-\u20B9${_discountAmount.toInt()}',
                    style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Fee',
                  style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                ),
                Text(
                  'FREE',
                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Divider(color: AppColors.border),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24),
                ),
                Text(
                  '\u20B9${finalTotal.toInt()}',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 32, color: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.info.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.schedule_rounded, color: AppColors.info, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'ETA ${_etaMin}-${_etaMax} min - ${_etaConfidenceLabel(ref.watch(cartProvider).length)}',
                      style: const TextStyle(
                        color: AppColors.info,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: canPlaceOrder ? () => _checkout(context) : null,
                child: const Text('PLACE ORDER'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressRow(
    BuildContext context,
    AsyncValue<List<AddressModel>> addressesAsync,
    AddressModel defaultAddress,
    bool hasAddress,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: addressesAsync.when(
              loading: () => const Text('Loading address...', style: TextStyle(fontWeight: FontWeight.w700)),
              error: (_, _) => const Text(
                'Address book unavailable right now. You can still place the order.',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              data: (_) => hasAddress
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          defaultAddress.label,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          defaultAddress.addressLine,
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ],
                    )
                  : const Text(
                      'Add a delivery address to place your order.',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
            ),
          ),
          TextButton(
            onPressed: () => context.push('/addresses'),
            child: Text(hasAddress ? 'Change' : 'Add'),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleRow(BuildContext context) {
    final scheduledLabel = _scheduledFor == null
        ? 'ASAP'
        : DateFormat('EEE, MMM d - hh:mm a').format(_scheduledFor!);

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
            onPressed: () => _selectScheduleSlot(context),
            child: Text(_scheduledFor == null ? 'Schedule' : 'Change'),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodOrderRow() {
    final cart = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);
    final cartItems = cart.values.toList();
    final itemCount = cart.length;
    final quantityCount = cart.values.fold<int>(0, (sum, item) => sum + item.quantity);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.restaurant_menu_rounded, color: AppColors.primary, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Food order', style: TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(
                      '$itemCount item${itemCount == 1 ? '' : 's'} • $quantityCount total qty',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (cartItems.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 8),
            ...cartItems.map(
              (cartItem) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        cartItem.item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline_rounded),
                      color: AppColors.textSecondary,
                      visualDensity: VisualDensity.compact,
                      onPressed: () => cartNotifier.removeItem(cartItem.item),
                    ),
                    Text(
                      '${cartItem.quantity}',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_rounded),
                      color: AppColors.primary,
                      visualDensity: VisualDensity.compact,
                      onPressed: () => cartNotifier.addItem(cartItem.item),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildClassDeliveryRow(
    BuildContext context,
    AsyncValue<List<CampusBuilding>> buildingsAsync,
    AsyncValue<List<ClassSession>> classSessionsAsync,
  ) {
    final zonesAsync = ref.watch(campusZonesProvider(_selectedBuildingId));
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.school_rounded, color: AppColors.primary, size: 18),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('Deliver to class', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
              Switch(
                value: _deliverToClass,
                onChanged: (value) => setState(() => _deliverToClass = value),
              ),
            ],
          ),
          if (_deliverToClass) ...[
            const SizedBox(height: 10),
            classSessionsAsync.when(
              loading: () => const Text('Loading saved classes...'),
              error: (e, _) => Text('Unable to load schedule: $e'),
              data: (sessions) {
                if (sessions.isEmpty) {
                  return TextButton.icon(
                    onPressed: () => context.push('/profile/classes'),
                    icon: const Icon(Icons.calendar_month_outlined),
                    label: const Text('Add classes to your schedule'),
                  );
                }

                final selectedValue = _selectedClassSessionId ?? '__manual__';

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedValue,
                      decoration: const InputDecoration(
                        labelText: 'Use saved class (optional)',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem(value: '__manual__', child: Text('Manual entry')),
                        ...sessions.map((session) {
                          final title = session.courseLabel?.isNotEmpty == true
                              ? session.courseLabel!
                              : session.buildingName ?? 'Class';
                          final room = session.room.isEmpty ? '' : ' - ${session.room}';
                          return DropdownMenuItem(
                            value: session.id,
                            child: Text('$title$room'),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        if (value == null || value == '__manual__') {
                          setState(() {
                            _selectedClassSessionId = null;
                            _classStartAt = null;
                            _classEndAt = null;
                          });
                          return;
                        }
                        final selected = sessions.firstWhere((s) => s.id == value);
                        setState(() {
                          _selectedClassSessionId = selected.id;
                          _selectedBuildingId = selected.buildingId;
                          _roomController.text = selected.room;
                          _classStartAt = selected.startsAt;
                          _classEndAt = selected.endsAt;
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                  ],
                );
              },
            ),
            buildingsAsync.when(
              loading: () => const Text('Loading campus buildings...'),
              error: (e, _) => Text('Unable to load buildings: $e'),
              data: (buildings) {
                if (buildings.isEmpty) {
                  return const Text('No buildings available yet.');
                }

                final selected = buildings.firstWhere(
                  (b) => b.id == _selectedBuildingId,
                  orElse: () => buildings.first,
                );
                _selectedBuildingId ??= selected.id;

                return DropdownButtonFormField<String>(
                  value: _selectedBuildingId,
                  items: buildings
                      .map(
                        (b) => DropdownMenuItem<String>(
                          value: b.id,
                          child: Text(b.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() {
                    _selectedBuildingId = value;
                    _selectedZoneId = null;
                    _selectedClassSessionId = null;
                    _classStartAt = null;
                    _classEndAt = null;
                  }),
                  decoration: const InputDecoration(
                    labelText: 'Building',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            zonesAsync.when(
              loading: () => const Text('Loading delivery zones...'),
              error: (e, _) => Text('Unable to load zones: $e'),
              data: (zones) {
                if (zones.isEmpty) {
                  return const Text('No delivery zones configured for this building.');
                }

                return DropdownButtonFormField<String>(
                  value: _selectedZoneId,
                  items: zones
                      .map(
                        (zone) => DropdownMenuItem<String>(
                          value: zone.id,
                          child: Text(zone.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _selectedZoneId = value),
                  decoration: const InputDecoration(
                    labelText: 'Delivery zone (optional)',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _roomController,
              decoration: const InputDecoration(
                labelText: 'Room / Class',
                isDense: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _instructionsController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Delivery instructions',
                hintText: 'Quiet drop-off, knock once, etc.',
                isDense: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.volume_off_rounded, size: 18, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                const Expanded(child: Text('Quiet mode (no calls)')),
                Switch(
                  value: _quietMode,
                  onChanged: (value) => setState(() => _quietMode = value),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPromoRow(BuildContext context, double subtotal) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Promo code', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _promoController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    hintText: 'Enter code',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _applyPromo(context, subtotal),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: _promoApplying ? null : () => _applyPromo(context, subtotal),
                child: _promoApplying
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Apply'),
              ),
            ],
          ),
          if (_promoMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _promoMessage!,
              style: TextStyle(
                color: _discountAmount > 0 ? AppColors.primary : AppColors.error,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (_appliedPromoCode != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Chip(
                  label: Text('Applied: $_appliedPromoCode'),
                  backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: _clearPromo,
                  child: const Text('Remove'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _selectScheduleSlot(BuildContext context) async {
    try {
      final slots = await ref.read(orderServiceProvider).getOrderSlots(days: 3);
      if (!context.mounted) return;

      final selection = await showModalBottomSheet<Map<String, dynamic>>(
        context: context,
        showDragHandle: true,
        builder: (sheetContext) {
          return SafeArea(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.all(16),
              itemCount: slots.length + 1,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return ListTile(
                    leading: const Icon(Icons.flash_on_rounded),
                    title: const Text('ASAP'),
                    subtitle: const Text('Prepare as soon as possible'),
                    onTap: () => Navigator.of(sheetContext).pop({'starts_at': null}),
                  );
                }

                final slot = slots[index - 1];
                final label = '${slot['day_label']} - ${slot['label']}';
                return ListTile(
                  leading: const Icon(Icons.schedule_rounded),
                  title: Text(label),
                  onTap: () => Navigator.of(sheetContext).pop(slot),
                );
              },
            ),
          );
        },
      );

      if (!mounted || selection == null) return;
      final startsAt = selection['starts_at']?.toString();
      setState(() {
        _scheduledFor = startsAt == null ? null : DateTime.parse(startsAt);
      });
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load time slots: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _applyPromo(BuildContext context, double subtotal) async {
    final code = _promoController.text.trim();
    if (code.isEmpty) {
      setState(() => _promoMessage = 'Enter a promo code first.');
      return;
    }

    setState(() {
      _promoApplying = true;
      _promoMessage = null;
    });

    try {
      final result = await PromoService().validatePromo(code, subtotal);
      if (!mounted) return;
      setState(() {
        _discountAmount = result.discountAmount;
        _appliedPromoCode = result.code;
        _promoMessage = result.description ?? 'Promo applied successfully.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _discountAmount = 0;
        _appliedPromoCode = null;
        _promoMessage = 'Promo could not be applied: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _promoApplying = false);
      }
    }
  }

  void _clearPromo() {
    setState(() {
      _discountAmount = 0;
      _appliedPromoCode = null;
      _promoMessage = null;
      _promoController.clear();
    });
  }

  Future<void> _checkout(BuildContext context) async {
    final cart = ref.read(cartProvider);
    if (cart.isEmpty) return;

    final firstItem = cart.values.first;
    final vendorId = firstItem.item.vendorId;
    if (vendorId == null || vendorId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to place order right now. Missing vendor context.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final vendorIds = cart.values.map((i) => i.item.vendorId).toSet();
    if (vendorIds.length > 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please checkout items from one vendor at a time.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_deliverToClass) {
      if (_selectedBuildingId == null || _selectedBuildingId!.isEmpty || _roomController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Select a building and room for class delivery.'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    }
    
    final result = await showModalBottomSheet<_PaymentMethod>(
      context: context,
      builder: (context) => const _PaymentSheet(),
    );

    if (result == null) return;

    if (result == _PaymentMethod.payOnPickup) {
      await _placeOrder(context);
      return;
    }

    if (PaymentConfig.razorpayKeyId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment gateway is not configured yet.')),
      );
      return;
    }

    await _startRazorpayPayment(context);
  }

  Future<void> _placeOrder(BuildContext context) async {
    final cart = ref.read(cartProvider);
    if (cart.isEmpty) return;

    final firstItem = cart.values.first;
    final vendorId = firstItem.item.vendorId;
    if (vendorId == null || vendorId.isEmpty) return;

    try {
      final subtotal = ref.read(cartProvider.notifier).totalAmount;
      final deliveryMode = _deliverToClass ? 'class' : 'standard';
      final order = await ref.read(orderServiceProvider).placeOrder(
        vendorId: vendorId,
        items: cart.values.map((i) => {
          'id': i.item.id,
          'quantity': i.quantity,
          'price': i.item.price,
        }).toList(),
        totalAmount: subtotal,
        promoCode: _appliedPromoCode,
        scheduledFor: _scheduledFor,
        deliveryMode: deliveryMode,
        deliveryBuildingId: _deliverToClass ? _selectedBuildingId : null,
        deliveryRoom: _deliverToClass ? _roomController.text.trim() : null,
        deliveryZoneId: _deliverToClass ? _selectedZoneId : null,
        quietMode: _deliverToClass ? _quietMode : null,
        deliveryInstructions: _deliverToClass ? _instructionsController.text.trim() : null,
        deliveryLocationLabel: _deliverToClass ? 'Classroom' : null,
        classStartAt: _deliverToClass ? _classStartAt : null,
        classEndAt: _deliverToClass ? _classEndAt : null,
      );

      if (!context.mounted) return;

      ref.read(cartProvider.notifier).clearCart();
      context.push('/order-status/${order.id}');
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Checkout failed: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _startRazorpayPayment(BuildContext context) async {
    if (_paymentInProgress) return;

    final cart = ref.read(cartProvider);
    if (cart.isEmpty) return;

    final firstItem = cart.values.first;
    final vendorId = firstItem.item.vendorId;
    if (vendorId == null || vendorId.isEmpty) return;

    final subtotal = ref.read(cartProvider.notifier).totalAmount;
    final finalAmount = (subtotal - _discountAmount).clamp(0, double.infinity).toDouble();

    setState(() => _paymentInProgress = true);
    try {
      final paymentService = PaymentService();
      final order = await paymentService.createRazorpayOrder(amount: finalAmount);
      final user = ref.read(userProvider);

      _pendingOrder = _PendingOrder(
        vendorId: vendorId,
        items: cart.values.map((i) => {
          'id': i.item.id,
          'quantity': i.quantity,
          'price': i.item.price,
        }).toList(),
        subtotalAmount: subtotal,
        finalAmount: finalAmount,
        promoCode: _appliedPromoCode,
        scheduledFor: _scheduledFor,
        deliveryMode: _deliverToClass ? 'class' : 'standard',
        deliveryBuildingId: _deliverToClass ? _selectedBuildingId : null,
        deliveryRoom: _deliverToClass ? _roomController.text.trim() : null,
        deliveryZoneId: _deliverToClass ? _selectedZoneId : null,
        quietMode: _deliverToClass ? _quietMode : null,
        deliveryInstructions: _deliverToClass ? _instructionsController.text.trim() : null,
        classStartAt: _deliverToClass ? _classStartAt : null,
        classEndAt: _deliverToClass ? _classEndAt : null,
        razorpayOrderId: order['id']?.toString() ?? '',
      );

      final options = {
        'key': PaymentConfig.razorpayKeyId,
        'amount': (finalAmount * 100).toInt(),
        'name': PaymentConfig.merchantName,
        'description': PaymentConfig.merchantDescription,
        'order_id': _pendingOrder!.razorpayOrderId,
        'prefill': {
          'email': user?.email ?? '',
        },
      };

      _razorpay.open(options);
    } catch (e) {
      setState(() => _paymentInProgress = false);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment setup failed: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    final pending = _pendingOrder;
    if (pending == null) return;

    try {
      final paymentService = PaymentService();
      await paymentService.verifyPayment(
        orderId: response.orderId ?? '',
        paymentId: response.paymentId ?? '',
        signature: response.signature ?? '',
      );

      final order = await ref.read(orderServiceProvider).placeOrder(
        vendorId: pending.vendorId,
        items: pending.items,
        totalAmount: pending.subtotalAmount,
        promoCode: pending.promoCode,
        scheduledFor: pending.scheduledFor,
        deliveryMode: pending.deliveryMode,
        deliveryBuildingId: pending.deliveryBuildingId,
        deliveryRoom: pending.deliveryRoom,
        deliveryZoneId: pending.deliveryZoneId,
        quietMode: pending.quietMode,
        deliveryInstructions: pending.deliveryInstructions,
        deliveryLocationLabel: pending.deliveryMode == 'class' ? 'Classroom' : null,
        classStartAt: pending.classStartAt,
        classEndAt: pending.classEndAt,
      );

      if (!mounted) return;
      ref.read(cartProvider.notifier).clearCart();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment successful. Order placed.')),
      );
      context.go('/order-status/${order.id}');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment verification failed: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) {
        setState(() => _paymentInProgress = false);
      }
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    setState(() => _paymentInProgress = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment failed: ${response.message ?? 'Unknown error'}'), backgroundColor: AppColors.error),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('External wallet selected: ${response.walletName ?? ''}')),
    );
  }
}

enum _PaymentMethod { payNow, payOnPickup }

class _PaymentSheet extends StatelessWidget {
  const _PaymentSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Choose payment method', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.credit_card_rounded),
              title: const Text('Pay now (Razorpay)'),
              subtitle: const Text('Cards, UPI, or wallets'),
              onTap: () => Navigator.pop(context, _PaymentMethod.payNow),
            ),
            ListTile(
              leading: const Icon(Icons.payments_rounded),
              title: const Text('Pay on pickup'),
              subtitle: const Text('Settle when you receive your order'),
              onTap: () => Navigator.pop(context, _PaymentMethod.payOnPickup),
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingOrder {
  final String vendorId;
  final List<Map<String, dynamic>> items;
  final double subtotalAmount;
  final double finalAmount;
  final String? promoCode;
  final DateTime? scheduledFor;
  final String? deliveryMode;
  final String? deliveryBuildingId;
  final String? deliveryRoom;
  final String? deliveryZoneId;
  final bool? quietMode;
  final String? deliveryInstructions;
  final DateTime? classStartAt;
  final DateTime? classEndAt;
  final String razorpayOrderId;

  _PendingOrder({
    required this.vendorId,
    required this.items,
    required this.subtotalAmount,
    required this.finalAmount,
    this.promoCode,
    this.scheduledFor,
    this.deliveryMode,
    this.deliveryBuildingId,
    this.deliveryRoom,
    this.deliveryZoneId,
    this.quietMode,
    this.deliveryInstructions,
    this.classStartAt,
    this.classEndAt,
    required this.razorpayOrderId,
  });
}
