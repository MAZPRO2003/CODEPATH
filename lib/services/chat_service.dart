import 'dart:io' show Platform;
import 'package:cloud_firestore/cloud_firestore.dart' as fb_store;
import 'package:firedart/firedart.dart' as fd;
import 'package:codepath/models/chat.dart';
import 'package:codepath/models/user.dart';
import 'auth_service.dart';

class ChatService {
  static final fb_store.FirebaseFirestore _db = fb_store.FirebaseFirestore.instance;

  static String getChatRoomId(String user1, String user2) {
    return user1.compareTo(user2) < 0 ? '${user1}_$user2' : '${user2}_$user1';
  }

  /// Get or create a chat room between two users
  static Future<String> getOrCreateChatRoom(String otherUserId) async {
    final currentUser = AuthService.currentUser;
    if (currentUser == null) throw Exception("User not logged in");

    final roomId = getChatRoomId(currentUser.uid, otherUserId);

    try {
      if (Platform.isLinux) {
        final docRef = AuthService.firedartDb.collection('chatRooms').document(roomId);
        fd.Document? doc;
        try {
          doc = await docRef.get();
        } catch (_) {
          doc = null;
        }
        if (doc == null || doc.map.isEmpty) {
          await docRef.set({
            'participantIds': [currentUser.uid, otherUserId],
            'lastMessage': null,
            'lastMessageTimestamp': DateTime.now().toIso8601String(),
            'unreadCounts': {currentUser.uid: 0, otherUserId: 0},
          });
        }
      } else {
        final docRef = _db.collection('chatRooms').doc(roomId);
        final doc = await docRef.get();
        if (!doc.exists) {
          await docRef.set({
            'participantIds': [currentUser.uid, otherUserId],
            'lastMessage': null,
            'lastMessageTimestamp': fb_store.FieldValue.serverTimestamp(),
            'unreadCounts': {currentUser.uid: 0, otherUserId: 0},
          });
        }
      }
      return roomId;
    } catch (e) {
      print('ChatRoom Error: $e');
      return roomId;
    }
  }

  /// Stream messages for a specific chat room
  static Stream<List<ChatMessage>> getMessages(String chatRoomId) {
    if (Platform.isLinux) {
      return AuthService.firedartDb
          .collection('chatRooms')
          .document(chatRoomId)
          .collection('messages')
          .stream
          .map((docs) {
            final messages = docs.map((doc) => ChatMessage.fromMap(doc.map, doc.id)).toList();
            messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
            return messages;
          });
    } else {
      return _db
          .collection('chatRooms')
          .doc(chatRoomId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => ChatMessage.fromMap(doc.data(), doc.id))
              .toList());
    }
  }

  /// Send a message in a chat room
  static Future<void> sendMessage(String roomId, String text, {bool isChallenge = false}) async {
    final currentUser = AuthService.currentUser;
    if (currentUser == null) return;

    final messageData = {
      'senderId': currentUser.uid,
      'text': text,
      'timestamp': DateTime.now().toIso8601String(),
      'isChallenge': isChallenge,
    };

    try {
      if (Platform.isLinux) {
        await AuthService.firedartDb.collection('chatRooms').document(roomId).collection('messages').add(messageData);
        await AuthService.firedartDb.collection('chatRooms').document(roomId).update({
          'lastMessage': text,
          'lastMessageTimestamp': DateTime.now().toIso8601String(),
        });
      } else {
        final batch = _db.batch();
        final messageRef = _db.collection('chatRooms').doc(roomId).collection('messages').doc();
        batch.set(messageRef, {
          ...messageData,
          'timestamp': fb_store.FieldValue.serverTimestamp(),
        });
        batch.update(_db.collection('chatRooms').doc(roomId), {
          'lastMessage': text,
          'lastMessageTimestamp': fb_store.FieldValue.serverTimestamp(),
        });
        await batch.commit();
      }
    } catch (e) {
      print('Send Message Error: $e');
    }
  }

  /// Stream all chat rooms for the current user (WhatsApp-style list)
  static Stream<List<ChatRoom>> getChatRooms() {
    final currentUser = AuthService.currentUser;
    if (currentUser == null) return const Stream.empty();

    if (Platform.isLinux) {
      return AuthService.firedartDb.collection('chatRooms').stream.map((docs) {
        return docs
            .map((doc) => ChatRoom.fromMap(doc.map, doc.id))
            .where((room) => room.participantIds.contains(currentUser.uid))
            .toList()
          ..sort((a, b) => (b.lastMessageTimestamp ?? DateTime(0)).compareTo(a.lastMessageTimestamp ?? DateTime(0)));
      });
    } else {
      return _db
          .collection('chatRooms')
          .where('participantIds', arrayContains: currentUser.uid)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => ChatRoom.fromMap(doc.data(), doc.id))
              .toList()
            ..sort((a, b) => (b.lastMessageTimestamp ?? DateTime(0)).compareTo(a.lastMessageTimestamp ?? DateTime(0))));
    }
  }
}
