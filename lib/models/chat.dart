import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRoom {
  final String id;
  final List<String> participantIds;
  final String? lastMessage;
  final DateTime? lastMessageTimestamp;
  final Map<String, int> unreadCounts;

  ChatRoom({
    required this.id,
    required this.participantIds,
    this.lastMessage,
    this.lastMessageTimestamp,
    this.unreadCounts = const {},
  });

  factory ChatRoom.fromMap(Map<String, dynamic> data, String id) {
    return ChatRoom(
      id: id,
      participantIds: List<String>.from(data['participantIds'] ?? []),
      lastMessage: data['lastMessage'],
      lastMessageTimestamp: (data['lastMessageTimestamp'] as Timestamp?)?.toDate(),
      unreadCounts: Map<String, int>.from(data['unreadCounts'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'participantIds': participantIds,
      'lastMessage': lastMessage,
      'lastMessageTimestamp': lastMessageTimestamp != null ? Timestamp.fromDate(lastMessageTimestamp!) : null,
      'unreadCounts': unreadCounts,
    };
  }

  String getOtherParticipantId(String currentUserId) {
    return participantIds.firstWhere((id) => id != currentUserId, orElse: () => '');
  }
}
