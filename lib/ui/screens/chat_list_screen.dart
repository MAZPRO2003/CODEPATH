import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../models/chat.dart';
import '../../models/user.dart';
import '../../services/chat_service.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Chats', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.search)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert)),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search friends...',
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2)),
                  border: InputBorder.none,
                  icon: Icon(Icons.search, color: Colors.white.withValues(alpha: 0.2), size: 20),
                ),
              ),
            ),
          ),
          
          Expanded(
            child: StreamBuilder<List<ChatRoom>>(
              stream: ChatService.getChatRooms(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
                }
                
                final rooms = snapshot.data ?? [];
                
                if (rooms.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 80, color: Colors.white.withValues(alpha: 0.1)),
                        const SizedBox(height: 16),
                        Text('No conversations yet', style: TextStyle(color: Colors.white.withValues(alpha: 0.3))),
                      ],
                    ),
                  );
                }
                
                return ListView.builder(
                  itemCount: rooms.length,
                  itemBuilder: (context, index) => _ChatRoomTile(room: rooms[index]),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Could open friend picker here
        },
        backgroundColor: AppColors.accentBlue,
        child: const Icon(Icons.message, color: Colors.white),
      ),
    );
  }
}

class _ChatRoomTile extends StatelessWidget {
  final ChatRoom room;

  const _ChatRoomTile({required this.room});

  @override
  Widget build(BuildContext context) {
    final currentUserId = AuthService.currentUser?.uid ?? '';
    final otherUserId = room.getOtherParticipantId(currentUserId);

    return FutureBuilder<AppUser?>(
      future: FirestoreService.getUserById(otherUserId),
      builder: (context, snapshot) {
        final user = snapshot.data;
        final name = user?.name ?? 'Loading...';
        final isOnline = user?.isOnline ?? false;
        
        return InkWell(
          onTap: () {
            if (user != null) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ChatScreen(friend: user, roomId: room.id)),
              );
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.accentBlue.withValues(alpha: 0.1),
                      child: Text(name[0], style: const TextStyle(color: AppColors.accentBlue, fontWeight: FontWeight.bold, fontSize: 20)),
                    ),
                    if (isOnline)
                      Positioned(
                        right: 2,
                        bottom: 2,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.background, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          if (room.lastMessageTimestamp != null)
                            Text(
                              _formatTimestamp(room.lastMessageTimestamp!),
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        room.lastMessage ?? 'Start a conversation',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    if (now.day == timestamp.day && now.month == timestamp.month && now.year == timestamp.year) {
      return DateFormat('HH:mm').format(timestamp);
    }
    return DateFormat('dd/MM').format(timestamp);
  }
}
