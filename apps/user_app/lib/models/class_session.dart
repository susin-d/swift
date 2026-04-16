class ClassSession {
  final String id;
  final String buildingId;
  final String? buildingName;
  final String room;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final String? courseLabel;
  final String? notes;

  const ClassSession({
    required this.id,
    required this.buildingId,
    required this.room,
    this.buildingName,
    this.startsAt,
    this.endsAt,
    this.courseLabel,
    this.notes,
  });

  factory ClassSession.fromJson(Map<String, dynamic> json) {
    return ClassSession(
      id: json['id']?.toString() ?? '',
      buildingId: json['building_id']?.toString() ?? '',
      buildingName: json['campus_buildings']?['name']?.toString(),
      room: json['room']?.toString() ?? '',
      startsAt: json['starts_at'] != null ? DateTime.parse(json['starts_at']) : null,
      endsAt: json['ends_at'] != null ? DateTime.parse(json['ends_at']) : null,
      courseLabel: json['course_label']?.toString(),
      notes: json['notes']?.toString(),
    );
  }
}
