class AppUser {
  final String id;
  final String name;
  final String email;
  final String? profileImageUrl;
  final int rating;
  final bool isOnline;
  final List<String> friendIds;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.profileImageUrl,
    this.rating = 1500,
    this.isOnline = false,
    this.friendIds = const [],
  });

  factory AppUser.fromMap(Map<String, dynamic> data, String id) {
    return AppUser(
      id: id,
      name: data['name'] ?? 'User',
      email: data['email'] ?? '',
      profileImageUrl: data['profileImageUrl'],
      rating: data['rating'] ?? 1500,
      isOnline: data['isOnline'] ?? false,
      friendIds: List<String>.from(data['friendIds'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'profileImageUrl': profileImageUrl,
      'rating': rating,
      'isOnline': isOnline,
      'friendIds': friendIds,
    };
  }
}

class ChatMessage {
  final String id;
  final String senderId;
  final String text;
  final DateTime timestamp;
  final bool isChallenge; // If true, this message is a battle challenge

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.timestamp,
    this.isChallenge = false,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> data, String id) {
    return ChatMessage(
      id: id,
      senderId: data['senderId'] ?? '',
      text: data['text'] ?? '',
      timestamp: (data['timestamp'] as dynamic)?.toDate() ?? DateTime.now(),
      isChallenge: data['isChallenge'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'text': text,
      'timestamp': timestamp,
      'isChallenge': isChallenge,
    };
  }
}
