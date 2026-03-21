class PendingOrder {
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

  PendingOrder({
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
