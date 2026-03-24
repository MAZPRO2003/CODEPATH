import 'package:flutter/material.dart';
import 'package:codepath/models/forum.dart';

class ForumThreadDetailScreen extends StatelessWidget {
  final ForumPost post;

  const ForumThreadDetailScreen({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thread Details')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildHeader(),
                const Divider(height: 32),
                _buildRepliesList(),
              ],
            ),
          ),
          _buildReplyInput(context),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(post.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: [
            const CircleAvatar(radius: 12, child: Icon(Icons.person, size: 12)),
            const SizedBox(width: 8),
            Text(post.author, style: const TextStyle(color: Colors.blueAccent)),
            const SizedBox(width: 8),
            Text('\${post.timestamp.day}/\${post.timestamp.month}/\${post.timestamp.year}', style: const TextStyle(color: Colors.grey)),
          ],
        ),
        const SizedBox(height: 16),
        Text(post.content, style: const TextStyle(fontSize: 16, height: 1.5)),
      ],
    );
  }

  Widget _buildRepliesList() {
    // Mock replies
    final replies = [
      ForumReply(id: '1', postId: post.id, author: 'ExpertCoder', content: 'You can use a HashMap to store the complement and check it in O(1) time.', timestamp: DateTime.now()),
      ForumReply(id: '2', postId: post.id, author: 'Student101', content: 'Thanks! That makes sense.', timestamp: DateTime.now()),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Replies', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        ...replies.map((reply) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              color: const Color(0xFF2D2D30),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(reply.author, style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        Text('Just now', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(reply.content),
                  ],
                ),
              ),
            )),
      ],
    );
  }

  Widget _buildReplyInput(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFF252526),
      child: Row(
        children: [
          const Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Write a reply...',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: () {},
            child: const Text('Post'),
          ),
        ],
      ),
    );
  }
}
