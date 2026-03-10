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
  final OrderStatus status;
  final List<OrderItemModel> items;
  final DateTime createdAt;

  OrderModel({
    required this.id,
    required this.userId,
    required this.vendorId,
    this.vendorName,
    required this.totalAmount,
    required this.status,
    required this.items,
    required this.createdAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'],
      userId: json['user_id'],
      vendorId: json['vendor_id'],
      vendorName: json['vendors']?['name'],
      totalAmount: (json['total_amount'] ?? 0.0).toDouble(),
      status: _statusFromString(json['status']),
      items: (json['order_items'] as List?)
              ?.map((i) => OrderItemModel.fromJson(i))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['created_at']),
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
