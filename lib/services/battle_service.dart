import 'dart:io' show Platform;
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart' as fb_store;
import 'package:codepath/services/auth_service.dart';

class BattleService {
  static final fb_store.FirebaseFirestore _db = fb_store.FirebaseFirestore.instance;

  /// Start searching for a match. Returns a Stream that emits the Battle ID when matched.
  static Stream<String?> startMatchmaking() {
    final uid = AuthService.currentUser?.uid;
    if (uid == null) return const Stream.empty();

    final StreamController<String?> controller = StreamController();

    _executeMatchmaking(uid, controller);

    return controller.stream;
  }

  static Future<void> _executeMatchmaking(String uid, StreamController<String?> controller) async {
    try {
      if (Platform.isLinux) {
        final fdDb = AuthService.firedartDb;
        
        // 1. Join queue
        await fdDb.collection('matchmaking_queue').document(uid).set({
          'timestamp': DateTime.now().toIso8601String(),
          'status': 'waiting',
          'battleId': null,
        });

        // Loop to look for an opponent, while also checking if we got matched.
        Timer.periodic(const Duration(seconds: 3), (timer) async {
          if (controller.isClosed) {
            timer.cancel();
            return;
          }

          // Check if someone matched with us
          final myDoc = await fdDb.collection('matchmaking_queue').document(uid).get();
          if (myDoc.map['status'] == 'matched' && myDoc.map['battleId'] != null) {
            timer.cancel();
            controller.add(myDoc.map['battleId']);
            await fdDb.collection('matchmaking_queue').document(uid).delete().catchError((_) {});
            return;
          }

          // Look for an opponent
          final allWaiting = await fdDb.collection('matchmaking_queue').get();
          for (var doc in allWaiting) {
            if (doc.id != uid && doc.map['status'] == 'waiting') {
              // Found someone!
              final battleId = 'battle_${DateTime.now().millisecondsSinceEpoch}'; // Generate ID
              
              // Create battle
              await fdDb.collection('battles').document(battleId).set({
                'player1_id': uid,
                'player2_id': doc.id,
                'player1_progress': 0.0,
                'player2_progress': 0.0,
                'status': 'ongoing',
                'created_at': DateTime.now().toIso8601String(),
              });

              // Update their status
              await fdDb.collection('matchmaking_queue').document(doc.id).update({
                'status': 'matched',
                'battleId': battleId,
              });

              timer.cancel();
              controller.add(battleId);
              await fdDb.collection('matchmaking_queue').document(uid).delete().catchError((_) {});
              return;
            }
          }
        });
      } else {
        // Standard Firebase implementation
        final queueRef = _db.collection('matchmaking_queue');
        
        await queueRef.doc(uid).set({
          'timestamp': fb_store.FieldValue.serverTimestamp(),
          'status': 'waiting',
          'battleId': null,
        });

        // Listen for changes to our own doc
        StreamSubscription? sub;
        sub = queueRef.doc(uid).snapshots().listen((doc) async {
          if (!doc.exists) return;
          final data = doc.data() as Map<String, dynamic>;
          if (data['status'] == 'matched' && data['battleId'] != null) {
            sub?.cancel();
            controller.add(data['battleId']);
            await queueRef.doc(uid).delete().catchError((_) {});
          }
        });

        // Periodically try to find someone
        Timer.periodic(const Duration(seconds: 3), (timer) async {
          if (controller.isClosed) {
            timer.cancel();
            sub?.cancel();
            return;
          }

          final snapshot = await queueRef
              .where('status', isEqualTo: 'waiting')
              .orderBy('timestamp')
              .get();

          for (var doc in snapshot.docs) {
            if (doc.id != uid) {
              // Found!
              final battleRef = _db.collection('battles').doc();
              
              await battleRef.set({
                'player1_id': uid,
                'player2_id': doc.id,
                'player1_progress': 0.0,
                'player2_progress': 0.0,
                'status': 'ongoing',
                'created_at': fb_store.FieldValue.serverTimestamp(),
              });

              await queueRef.doc(doc.id).update({
                'status': 'matched',
                'battleId': battleRef.id,
              });

              timer.cancel();
              sub?.cancel();
              controller.add(battleRef.id);
              await queueRef.doc(uid).delete().catchError((_) {});
              return;
            }
          }
        });
      }
    } catch (e) {
      print('Matchmaking error: $e');
      controller.addError(e);
    }
  }

  static Future<void> cancelMatchmaking() async {
    final uid = AuthService.currentUser?.uid;
    if (uid == null) return;

    try {
      if (Platform.isLinux) {
        await AuthService.firedartDb.collection('matchmaking_queue').document(uid).delete();
      } else {
        await _db.collection('matchmaking_queue').doc(uid).delete();
      }
    } catch (_) {}
  }

  /// Live Battle Sync: update local user progress
  static Future<void> updateProgress(String battleId, double progress) async {
    final uid = AuthService.currentUser?.uid;
    if (uid == null) return;

    try {
      if (Platform.isLinux) {
        final fdDb = AuthService.firedartDb;
        final doc = await fdDb.collection('battles').document(battleId).get();
        final isPlayer1 = doc.map['player1_id'] == uid;
        final field = isPlayer1 ? 'player1_progress' : 'player2_progress';
        
        await fdDb.collection('battles').document(battleId).update({
          field: progress,
        });
      } else {
        final doc = await _db.collection('battles').doc(battleId).get();
        final isPlayer1 = doc.data()?['player1_id'] == uid;
        final field = isPlayer1 ? 'player1_progress' : 'player2_progress';

        await _db.collection('battles').doc(battleId).update({
          field: progress,
        });
      }
    } catch (_) {}
  }

  /// Stream updates for a specific Battle
  static Stream<Map<String, dynamic>?> getBattleStream(String battleId) {
    if (Platform.isLinux) {
      final fdDb = AuthService.firedartDb;
      return fdDb.collection('battles').document(battleId).stream.map((doc) => doc?.map);
    } else {
      return _db.collection('battles').doc(battleId).snapshots().map((doc) => doc.data());
    }
  }

  /// Sends a message into battle sub-collection
  static Future<void> sendChatMessage(String battleId, String message) async {
    final uid = AuthService.currentUser?.uid;
    if (uid == null) return;
    
    final messageData = {
      'sender_id': uid,
      'text': message,
      'timestamp': Platform.isLinux ? DateTime.now().toIso8601String() : fb_store.FieldValue.serverTimestamp(),
    };

    if (Platform.isLinux) {
      await AuthService.firedartDb.collection('battles').document(battleId).collection('messages').add(messageData);
    } else {
      await _db.collection('battles').doc(battleId).collection('messages').add(messageData);
    }
  }

  /// Streams messages from battle sub-collection
  static Stream<List<Map<String, dynamic>>> getBattleMessages(String battleId) {
    if (Platform.isLinux) {
      return AuthService.firedartDb.collection('battles').document(battleId).collection('messages').stream.map((docs) {
        final msgs = docs.map((d) {
          final m = Map<String, dynamic>.from(d.map);
          m['id'] = d.id;
          return m;
        }).toList();
        // Simple client sort
        msgs.sort((a, b) => (a['timestamp'] ?? '').compareTo(b['timestamp'] ?? ''));
        return msgs;
      });
    } else {
      return _db.collection('battles').doc(battleId).collection('messages').orderBy('timestamp').snapshots().map((snap) {
        return snap.docs.map((d) {
          final m = d.data() as Map<String, dynamic>;
          m['id'] = d.id;
          return m;
        }).toList();
      });
    }
  }
}
