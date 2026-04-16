class AddressModel {
  final String id;
  final String label;
  final String addressLine;
  final bool isDefault;

  const AddressModel({
    required this.id,
    required this.label,
    required this.addressLine,
    required this.isDefault,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['id']?.toString() ?? '',
      label: json['label']?.toString() ?? 'Address',
      addressLine: json['address_line']?.toString() ?? '',
      isDefault: json['is_default'] == true,
    );
  }
}
