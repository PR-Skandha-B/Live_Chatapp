class RoomModel {
  final String id;
  final String name;
  final String description;
  final String inviteCode;
  final String createdBy;
  final List<String> members;
  final bool isDirect;
  final String icon;
  final DateTime createdAt;

  RoomModel({
    required this.id,
    required this.name,
    required this.description,
    required this.inviteCode,
    required this.createdBy,
    required this.members,
    required this.isDirect,
    required this.icon,
    required this.createdAt,
  });

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    return RoomModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      inviteCode: json['inviteCode'] ?? '',
      createdBy: json['createdBy'] ?? '',
      members: List<String>.from(json['members'] ?? []),
      isDirect: json['isDirect'] ?? false,
      icon: json['icon'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'description': description,
      'inviteCode': inviteCode,
      'createdBy': createdBy,
      'members': members,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
