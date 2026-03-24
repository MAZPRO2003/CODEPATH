import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/user.dart';
import '../../services/firestore_service.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  AppUser? _selectedFriend;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isSmall = constraints.maxWidth < 800;
          return Row(
            children: [
              // Friends List Sidebar (Responsive)
              Container(
                width: isSmall ? 80 : 320,
                decoration: BoxDecoration(
                  color: AppColors.cardBackground.withValues(alpha: 0.5),
                  border: Border(right: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isSmall)
                      const Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Text(
                          'Inner Circle',
                          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                    Expanded(
                      child: StreamBuilder<List<AppUser>>(
                        stream: FirestoreService.getFriendsStream(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          
                          if (snapshot.hasError) {
                            return Center(child: Text('Error loading friends', style: TextStyle(color: Colors.red.withValues(alpha: 0.7))));
                          }
                          
                          final friendsList = snapshot.data ?? [];
                          
                          if (friendsList.isEmpty) {
                            return Center(
                              child: Text('No developers found.\n(Realtime sync might be disabled on Linux)', 
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.5)))
                            );
                          }
                          
                          return ListView.builder(
                            itemCount: friendsList.length,
                            itemBuilder: (context, index) => _buildFriendTile(friendsList[index], isSmall),
                          );
                        }
                      ),
                    ),
                  ],
                ),
              ),
              
              // Chat / Profile Area
              Expanded(
                child: _selectedFriend == null
                    ? _buildEmptyState()
                    : _buildChatArea(_selectedFriend!, isSmall),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFriendTile(AppUser friend, bool isSmall) {
    bool isSelected = _selectedFriend?.id == friend.id;
    return InkWell(
      onTap: () => setState(() => _selectedFriend = friend),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: isSmall ? 16 : 24, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentBlue.withValues(alpha: 0.1) : Colors.transparent,
        ),
        child: Row(
          mainAxisAlignment: isSmall ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.accentRose.withValues(alpha: 0.2),
                  child: Text(friend.name[0], style: const TextStyle(color: AppColors.accentRose, fontWeight: FontWeight.bold)),
                ),
                if (friend.isOnline)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 12, height: 12,
                      decoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle, border: Border.all(color: Colors.black, width: 2)),
                    ),
                  ),
              ],
            ),
            if (!isSmall) ...[
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(friend.name, style: TextStyle(color: Colors.white, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                    Text('Rating: ${friend.rating}', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.forum_outlined, size: 80, color: Colors.white.withValues(alpha: 0.1)),
          const SizedBox(height: 16),
          Text('Select a friend to start a session', style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildChatArea(AppUser friend, bool isSmall) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1)))),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(friend.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(friend.isOnline ? 'Online' : 'Offline', style: TextStyle(color: friend.isOnline ? Colors.green : Colors.white.withValues(alpha: 0.3), fontSize: 12)),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.flash_on, size: 18),
                label: isSmall ? const Text('Battle') : const Text('Challenge 1v1'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentRose, foregroundColor: Colors.white),
              ),
            ],
          ),
        ),
        
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _buildMessage('Ready for a round?', false),
              _buildMessage('Let\'s go!', true),
              _buildChallengeMessage(),
            ],
          ),
        ),
        
        // Input
        Container(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withValues(alpha: 0.1))),
                  child: TextField(
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(hintText: 'Message...', hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2)), border: InputBorder.none),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              IconButton(onPressed: () {}, icon: const Icon(Icons.send, color: AppColors.accentBlue)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessage(String text, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(color: isMe ? AppColors.accentBlue : Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)),
        child: Text(text, style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildChallengeMessage() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: AppColors.accentRose.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.accentRose.withValues(alpha: 0.3))),
      child: Column(
        children: [
          const Icon(Icons.bolt, size: 40, color: AppColors.accentRose),
          const SizedBox(height: 12),
          const Text('BATTLE CHALLENGE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(onPressed: () {}, child: Text('DECLINE', style: TextStyle(color: Colors.red.withValues(alpha: 0.7)))),
              const SizedBox(width: 24),
              ElevatedButton(onPressed: () {}, style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentRose), child: const Text('ACCEPT')),
            ],
          ),
        ],
      ),
    );
  }
}
