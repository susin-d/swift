class AuditLogItem {
  const AuditLogItem({
    required this.id,
    required this.adminId,
    required this.action,
    required this.targetId,
    required this.createdAt,
  });

  final String id;
  final String? adminId;
  final String action;
  final String? targetId;
  final DateTime? createdAt;

  factory AuditLogItem.fromJson(Map<String, dynamic> json) {
    return AuditLogItem(
      id: (json['id'] as String?) ?? '',
      adminId: json['admin_id'] as String?,
      action: (json['action_performed'] as String?) ?? 'unknown',
      targetId: json['target_id'] as String?,
      createdAt: DateTime.tryParse((json['created_at'] as String?) ?? ''),
    );
  }
}
