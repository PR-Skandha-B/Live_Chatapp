class MessageModel {
  final String id;
  final String roomId;
  final String sender;
  final String content;
  final Map<String, List<String>> reactions;
  final Map<String, dynamic>? replyTo;
  final bool forwarded;
  final List<String> seenBy;
  final DateTime createdAt;

  MessageModel({
    required this.id,
    required this.roomId,
    required this.sender,
    required this.content,
    required this.reactions,
    this.replyTo,
    required this.forwarded,
    this.seenBy = const [],
    required this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    Map<String, List<String>> parsedReactions = {};
    if (json['reactions'] != null) {
      json['reactions'].forEach((key, value) {
        parsedReactions[key] = List<String>.from(value);
      });
    }

    return MessageModel(
      id: json['_id'] ?? json['id'] ?? '',
      roomId: json['roomId'] ?? '',
      sender: json['sender'] ?? '',
      content: json['content'] ?? '',
      reactions: parsedReactions,
      replyTo: json['replyTo'] != null ? json['replyTo'] as Map<String, dynamic> : null,
      forwarded: json['forwarded'] ?? false,
      seenBy: json['seenBy'] != null ? List<String>.from(json['seenBy']) : [],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'roomId': roomId,
      'sender': sender,
      'content': content,
      'reactions': reactions,
      'replyTo': replyTo,
      'seenBy': seenBy,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
