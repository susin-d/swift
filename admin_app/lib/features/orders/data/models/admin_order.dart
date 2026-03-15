class AdminOrder {
  const AdminOrder({
    required this.id,
    required this.status,
    required this.totalAmount,
    required this.createdAt,
    required this.updatedAt,
    required this.vendorName,
    required this.userName,
    required this.userEmail,
    required this.itemCount,
  });

  final String id;
  final String status;
  final double totalAmount;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String vendorName;
  final String userName;
  final String userEmail;
  final int itemCount;

  bool get isDelayed {
    if (createdAt == null) return false;
    if (status == 'completed' || status == 'cancelled') return false;
    final age = DateTime.now().difference(createdAt!);
    return age.inMinutes > 45;
  }

  factory AdminOrder.fromJson(Map<String, dynamic> json) {
    final user = (json['users'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
    final vendor = (json['vendors'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
    final orderItems = (json['order_items'] as List?) ?? const [];

    return AdminOrder(
      id: (json['id'] as String?) ?? '',
      status: (json['status'] as String?) ?? 'pending',
      totalAmount: _toDouble(json['total_amount']),
      createdAt: DateTime.tryParse((json['created_at'] as String?) ?? ''),
      updatedAt: DateTime.tryParse((json['updated_at'] as String?) ?? ''),
      vendorName: (vendor['name'] as String?) ?? 'Unknown vendor',
      userName: (user['name'] as String?) ?? 'Unknown user',
      userEmail: (user['email'] as String?) ?? 'N/A',
      itemCount: orderItems.length,
    );
  }
}

double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}
