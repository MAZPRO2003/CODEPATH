class ForumPost {
  final String id;
  final String title;
  final String author;
  final String content;
  final DateTime timestamp;
  final int replyCount;

  ForumPost({
    required this.id,
    required this.title,
    required this.author,
    required this.content,
    required this.timestamp,
    required this.replyCount,
  });
}

class ForumReply {
  final String id;
  final String postId;
  final String author;
  final String content;
  final DateTime timestamp;

  ForumReply({
    required this.id,
    required this.postId,
    required this.author,
    required this.content,
    required this.timestamp,
  });
}
