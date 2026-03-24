import 'dart:io' show Platform;
import 'package:cloud_firestore/cloud_firestore.dart' as fb_store;
import '../models/forum.dart';
import 'auth_service.dart';

class ForumService {
  static final fb_store.FirebaseFirestore _db = fb_store.FirebaseFirestore.instance;

  /// Fetches all forum posts
  static Future<List<ForumPost>> getPosts() async {
    try {
      if (Platform.isLinux) {
        final docs = await AuthService.firedartDb.collection('posts').get();
        return docs.map((doc) {
          final data = doc.map;
          return ForumPost(
            id: doc.id,
            title: data['title'] ?? 'Untitled',
            author: data['author'] ?? 'Unknown',
            content: data['content'] ?? '',
            timestamp: data['timestamp'] != null 
                ? DateTime.parse(data['timestamp']) 
                : DateTime.now(),
            replyCount: data['replyCount'] ?? 0,
          );
        }).toList();
      } else {
        final snapshot = await _db.collection('posts').orderBy('timestamp', descending: true).get();
        return snapshot.docs.map((doc) {
          final data = doc.data();
          return ForumPost(
            id: doc.id,
            title: data['title'] ?? 'Untitled',
            author: data['author'] ?? 'Unknown',
            content: data['content'] ?? '',
            timestamp: data['timestamp'] != null 
                ? (data['timestamp'] as fb_store.Timestamp).toDate() 
                : DateTime.now(),
            replyCount: data['replyCount'] ?? 0,
          );
        }).toList();
      }
    } catch (e) {
      print('Error fetching posts: $e');
      return [];
    }
  }

  /// Creates a new forum post
  static Future<void> createPost(String title, String content) async {
    final user = AuthService.currentUser;
    if (user == null) return;
    
    // We need the author name, get it if possible, otherwise use fallback
    String authorName = 'Developer';
    try {
      if (Platform.isLinux) {
        final doc = await AuthService.firedartDb.collection('users').document(user.uid).get();
        authorName = doc.map['name'] ?? 'Developer';
      } else {
        final doc = await _db.collection('users').doc(user.uid).get();
        authorName = doc.data()?['name'] ?? 'Developer';
      }
    } catch (_) {}

    try {
      if (Platform.isLinux) {
        await AuthService.firedartDb.collection('posts').document(DateTime.now().millisecondsSinceEpoch.toString()).set({
          'title': title,
          'content': content,
          'author': authorName,
          'timestamp': DateTime.now().toIso8601String(),
          'replyCount': 0,
          'uid': user.uid,
        });
      } else {
        await _db.collection('posts').add({
          'title': title,
          'content': content,
          'author': authorName,
          'timestamp': fb_store.FieldValue.serverTimestamp(),
          'replyCount': 0,
          'uid': user.uid,
        });
      }
    } catch (e) {
      print('Error creating post: $e');
    }
  }
}
