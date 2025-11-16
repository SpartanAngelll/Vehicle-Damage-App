import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../models/user_state.dart';
import '../models/chat_models.dart';
import '../services/chat_service.dart';
import '../widgets/glow_card.dart';
import '../widgets/web_layout.dart';
import '../utils/responsive_utils.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ChatService _chatService = ChatService();

  String _formatLastMessageTime(DateTime? dateTime) {
    if (dateTime == null) return 'No messages';
    
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 7) {
      return '${dateTime.month}/${dateTime.day}/${dateTime.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  Widget _buildChatList(BuildContext context) {
    return Consumer<UserState>(
      builder: (context, userState, child) {
        if (userState.userId == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.person_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 16),
                Text(
                  'Please sign in to view your chats',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          );
        }

        return StreamBuilder<List<ChatRoom>>(
          stream: _chatService.getUserChatRoomsStream(userState.userId!),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading chats',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => setState(() {}),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            final chatRooms = snapshot.data ?? [];

            if (chatRooms.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 64,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No active chats yet',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Chat conversations will appear here once you accept an estimate and start messaging with service professionals.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: chatRooms.length,
              itemBuilder: (context, index) {
                final chatRoom = chatRooms[index];
                final otherUserName = userState.isOwner
                    ? chatRoom.professionalName
                    : chatRoom.customerName;
                final otherUserPhotoUrl = userState.isOwner
                    ? chatRoom.professionalPhotoUrl
                    : chatRoom.customerPhotoUrl;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: GlowCard(
                    glowColor: Colors.blue,
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/chat',
                        arguments: chatRoom.id,
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundImage: otherUserPhotoUrl != null
                                ? NetworkImage(otherUserPhotoUrl)
                                : null,
                            child: otherUserPhotoUrl == null
                                ? const Icon(Icons.person)
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  otherUserName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                if (chatRoom.lastMessage != null)
                                  Text(
                                    chatRoom.lastMessage!,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatLastMessageTime(chatRoom.lastMessageAt),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = kIsWeb;

    if (isWeb) {
      final screenWidth = MediaQuery.of(context).size.width;
      final maxContentWidth = (screenWidth > 1400 ? 1000.0 : 900.0);

      return WebLayout(
        currentRoute: '/chatList',
        child: Center(
          child: Container(
            constraints: BoxConstraints(maxWidth: maxContentWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Messages',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: _buildChatList(context),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Mobile layout
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: _buildChatList(context),
    );
  }
}

