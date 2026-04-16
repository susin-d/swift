class VendorProfile {
  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final bool isOpen;
  final bool autoAcceptOrders;
  final int preparationTimeAvg;
  final bool busyModeEnabled;
  final String? busyModeMessage;
  final DateTime? holidayUntil;

  VendorProfile({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    required this.isOpen,
    this.autoAcceptOrders = false,
    this.preparationTimeAvg = 15,
    this.busyModeEnabled = false,
    this.busyModeMessage,
    this.holidayUntil,
  });

  factory VendorProfile.fromJson(Map<String, dynamic> json) {
    final controls = (json['controls'] as Map?)?.cast<String, dynamic>();
    final holidayRaw = controls?['holiday_until']?.toString();
    return VendorProfile(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Vendor',
      description: json['description']?.toString(),
      imageUrl: json['image_url']?.toString(),
      isOpen: controls?['is_open'] == true || json['is_open'] == true,
      autoAcceptOrders: controls?['auto_accept_orders'] == true,
      preparationTimeAvg: (controls?['preparation_time_avg'] as num?)?.toInt() ?? 15,
      busyModeEnabled: controls?['busy_mode_enabled'] == true,
      busyModeMessage: controls?['busy_mode_message']?.toString(),
      holidayUntil: holidayRaw == null || holidayRaw.isEmpty ? null : DateTime.tryParse(holidayRaw),
    );
  }
}
