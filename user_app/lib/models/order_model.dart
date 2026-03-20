import 'menu_model.dart';

enum OrderStatus {
  pending,
  accepted,
  preparing,
  ready,
  completed,
  cancelled
}

class OrderModel {
  final String id;
  final String userId;
  final String vendorId;
  final String? vendorName;
  final double totalAmount;
  final double discountAmount;
  final String? promoCode;
  final DateTime? scheduledFor;
  final String? deliveryMode;
  final String? deliveryBuildingId;
  final String? deliveryBuildingName;
  final String? deliveryRoom;
  final String? deliveryZoneId;
  final bool quietMode;
  final String? handoffCode;
  final String? handoffStatus;
  final String? deliveryInstructions;
  final String? deliveryLocationLabel;
  final DateTime? classStartAt;
  final DateTime? classEndAt;
  final OrderStatus status;
  final List<OrderItemModel> items;
  final DateTime createdAt;
  final OrderEta? eta;

  OrderModel({
    required this.id,
    required this.userId,
    required this.vendorId,
    this.vendorName,
    required this.totalAmount,
    this.discountAmount = 0,
    this.promoCode,
    this.scheduledFor,
    this.deliveryMode,
    this.deliveryBuildingId,
    this.deliveryBuildingName,
    this.deliveryRoom,
    this.deliveryZoneId,
    this.quietMode = false,
    this.handoffCode,
    this.handoffStatus,
    this.deliveryInstructions,
    this.deliveryLocationLabel,
    this.classStartAt,
    this.classEndAt,
    required this.status,
    required this.items,
    required this.createdAt,
    this.eta,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'],
      userId: json['user_id'],
      vendorId: json['vendor_id'],
      vendorName: json['vendors']?['name'],
      totalAmount: (json['total_amount'] ?? 0.0).toDouble(),
      discountAmount: (json['discount_amount'] ?? 0.0).toDouble(),
      promoCode: json['promo_code']?.toString(),
      scheduledFor: json['scheduled_for'] != null ? DateTime.parse(json['scheduled_for']) : null,
      deliveryMode: json['delivery_mode']?.toString(),
      deliveryBuildingId: json['delivery_building_id']?.toString(),
      deliveryBuildingName: json['campus_buildings']?['name']?.toString(),
      deliveryRoom: json['delivery_room']?.toString(),
      deliveryZoneId: json['delivery_zone_id']?.toString(),
      quietMode: json['quiet_mode'] == true,
      handoffCode: json['handoff_code']?.toString(),
      handoffStatus: json['handoff_status']?.toString(),
      deliveryInstructions: json['delivery_instructions']?.toString(),
      deliveryLocationLabel: json['delivery_location_label']?.toString(),
      classStartAt: json['class_start_at'] != null ? DateTime.parse(json['class_start_at']) : null,
      classEndAt: json['class_end_at'] != null ? DateTime.parse(json['class_end_at']) : null,
      status: _statusFromString(json['status']),
      items: (json['order_items'] as List?)
              ?.map((i) => OrderItemModel.fromJson(i))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['created_at']),
      eta: json['eta'] != null ? OrderEta.fromJson(json['eta']) : OrderEta.derivedFromStatus(
        status: _statusFromString(json['status']),
        createdAt: DateTime.parse(json['created_at']),
      ),
    );
  }

  static OrderStatus _statusFromString(String? status) {
    switch (status?.toLowerCase()) {
      case 'accepted': return OrderStatus.accepted;
      case 'preparing': return OrderStatus.preparing;
      case 'ready': return OrderStatus.ready;
      case 'completed': return OrderStatus.completed;
      case 'cancelled': return OrderStatus.cancelled;
      default: return OrderStatus.pending;
    }
  }

  String get statusText => status.name.toUpperCase();
}

class OrderEta {
  final int minMinutes;
  final int maxMinutes;
  final String confidence;
  final String? note;

  const OrderEta({
    required this.minMinutes,
    required this.maxMinutes,
    required this.confidence,
    this.note,
  });

  factory OrderEta.fromJson(Map<String, dynamic> json) {
    return OrderEta(
      minMinutes: (json['min_minutes'] ?? 0) as int,
      maxMinutes: (json['max_minutes'] ?? 0) as int,
      confidence: (json['confidence'] ?? 'medium').toString(),
      note: json['note']?.toString(),
    );
  }

  factory OrderEta.derivedFromStatus({
    required OrderStatus status,
    required DateTime createdAt,
  }) {
    final ageMinutes = DateTime.now().difference(createdAt).inMinutes.clamp(0, 120);

    int baseMin;
    int baseMax;
    String confidence;

    switch (status) {
      case OrderStatus.accepted:
        baseMin = 10;
        baseMax = 18;
        confidence = 'high';
        break;
      case OrderStatus.preparing:
        baseMin = 6;
        baseMax = 14;
        confidence = 'medium';
        break;
      case OrderStatus.ready:
        baseMin = 2;
        baseMax = 6;
        confidence = 'high';
        break;
      case OrderStatus.completed:
        baseMin = 0;
        baseMax = 0;
        confidence = 'high';
        break;
      case OrderStatus.cancelled:
        baseMin = 0;
        baseMax = 0;
        confidence = 'low';
        break;
      case OrderStatus.pending:
        baseMin = 14;
        baseMax = 24;
        confidence = 'high';
    }

    final minMinutes = (baseMin - (ageMinutes ~/ 2)).clamp(0, baseMin).toInt();
    final maxMinutes = (baseMax - ageMinutes).clamp(minMinutes, baseMax).toInt();

    return OrderEta(
      minMinutes: minMinutes,
      maxMinutes: maxMinutes,
      confidence: confidence,
      note: 'ETA range is a rolling estimate based on queue progress.',
    );
  }
}

class OrderItemModel {
  final String id;
  final String menuItemId;
  final int quantity;
  final double unitPrice;
  final MenuItemModel? menuItem;

  OrderItemModel({
    required this.id,
    required this.menuItemId,
    required this.quantity,
    required this.unitPrice,
    this.menuItem,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id'],
      menuItemId: json['menu_item_id'],
      quantity: json['quantity'] ?? 1,
      unitPrice: (json['unit_price'] ?? 0.0).toDouble(),
      menuItem: json['menu_items'] != null 
          ? MenuItemModel.fromJson(json['menu_items']) 
          : null,
    );
  }
}
