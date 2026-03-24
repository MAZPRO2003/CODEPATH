import 'package:flutter/material.dart';
import 'package:codepath/models/forum.dart';
import 'package:codepath/ui/screens/forum_thread_detail_screen.dart';
import 'package:codepath/theme/app_theme.dart';

import 'package:codepath/services/forum_service.dart';

class DiscussionScreen extends StatefulWidget {
  const DiscussionScreen({super.key});

  @override
  State<DiscussionScreen> createState() => _DiscussionScreenState();
}

class _DiscussionScreenState extends State<DiscussionScreen> {
  // Using a Future to store the fetch request so we can trigger reloads
  late Future<List<ForumPost>> _postsFuture;

  @override
  void initState() {
    super.initState();
    _postsFuture = ForumService.getPosts();
  }

  void _refreshPosts() {
    setState(() {
      _postsFuture = ForumService.getPosts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 64, 24, 32),
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 600) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Discussion Forum', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => _createNewPost(context),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Ask Question'),
                      ),
                    ],
                  );
                }
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Discussion Forum', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                        Text('Join the conversation with other developers', style: TextStyle(color: AppColors.textSecondary)),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _createNewPost(context),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Ask Question'),
                    ),
                  ],
                );
              }
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                _refreshPosts();
              },
              child: FutureBuilder<List<ForumPost>>(
                future: _postsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  if (snapshot.hasError) {
                    return Center(child: Text('Error loading posts', style: TextStyle(color: Colors.red.withValues(alpha: 0.7))));
                  }
                  
                  final posts = snapshot.data ?? [];
                  
                  if (posts.isEmpty) {
                    return Center(
                      child: Text('No discussions yet. Be the first to ask!', style: TextStyle(color: Colors.white.withValues(alpha: 0.5)))
                    );
                  }
                  
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: posts.length,
                    itemBuilder: (context, index) {
                      final post = posts[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.accentBlue.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.person, color: AppColors.accentBlue),
                          ),
                          title: Text(post.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text('Posted by \${post.author} • \${post.timestamp.day}/\${post.timestamp.month}', style: const TextStyle(color: AppColors.textSecondary)),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.comment, size: 16, color: AppColors.accentBlue),
                                const SizedBox(width: 8),
                                Text('\${post.replyCount}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => ForumThreadDetailScreen(post: post)));
                          },
                        ),
                      );
                    },
                  );
                }
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _createNewPost(BuildContext context) {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ask a Question'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(hintText: 'Title')
            ),
            const SizedBox(height: 16),
            TextField(
              controller: contentCtrl,
              maxLines: 5,
              decoration: const InputDecoration(hintText: 'Problem details...'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (titleCtrl.text.isNotEmpty && contentCtrl.text.isNotEmpty) {
                Navigator.pop(context);
                await ForumService.createPost(titleCtrl.text, contentCtrl.text);
                _refreshPosts();
              }
            }, 
            child: const Text('Post')
          ),
        ],
      ),
    );
  }
}
