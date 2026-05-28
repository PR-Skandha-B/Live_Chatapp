import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/message_model.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/room_provider.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final VoidCallback? onSwipeToReply;

  const MessageBubble({super.key, required this.message, this.onSwipeToReply});

  @override
  Widget build(BuildContext context) {
    final currentUsername = context.read<AuthProvider>().currentUser?.username;
    final isMe = message.sender == currentUsername;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dismissible(
      key: ValueKey(message.id),
      direction: DismissDirection.startToEnd,
      confirmDismiss: (direction) async {
        if (onSwipeToReply != null) onSwipeToReply!();
        return false;
      },
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        color: Colors.transparent,
        child: const Icon(Icons.reply, color: Colors.grey),
      ),
      child: GestureDetector(
        onLongPress: () {
          _showMessageOptions(context);
        },
        onSecondaryTapDown: (_) {
          _showMessageOptions(context);
        },
        onDoubleTap: () {
          _showReactionPicker(context, message.id);
        },
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (message.forwarded)
              Padding(
                padding: const EdgeInsets.only(bottom: 2, left: 4, right: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.shortcut, size: 12, color: Colors.grey),
                    const SizedBox(width: 4),
                    const Text('Forwarded', style: TextStyle(fontSize: 10, color: Colors.grey, fontStyle: FontStyle.italic)),
                  ],
                ),
              ),
            if (!isMe)
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 2),
                child: Text(
                  message.sender,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            if (message.replyTo != null)
              Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.all(8),
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.6),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border(left: BorderSide(color: theme.primaryColor, width: 4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Replying to ${message.replyTo!['sender']}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: theme.primaryColor)),
                    const SizedBox(height: 2),
                    Text(message.replyTo!['content'], maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              decoration: BoxDecoration(
                color: isMe 
                    ? theme.primaryColor 
                    : (isDark ? Colors.grey[800] : Colors.grey[200]),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(12),
                  topRight: const Radius.circular(12),
                  bottomLeft: isMe ? const Radius.circular(12) : Radius.zero,
                  bottomRight: isMe ? Radius.zero : const Radius.circular(12),
                ),
              ),
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.end,
                alignment: WrapAlignment.end,
                children: [
                  Text(
                    message.content,
                    style: TextStyle(
                      color: isMe 
                          ? Colors.white 
                          : (isDark ? Colors.white : Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (message.reactions.isNotEmpty) _buildReactions(context),
                if (message.reactions.isNotEmpty) const SizedBox(width: 4),
                Text(
                  DateFormat('HH:mm').format(message.createdAt.toLocal()),
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
                if (isMe && message.seenBy.length > 1)
                  const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Icon(Icons.done_all, size: 14, color: Colors.blue),
                  ),
              ],
            ),
            if (isMe && message.seenBy.length > 1)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  'Seen by ${message.seenBy.where((u) => u != currentUsername).join(", ")}',
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildReactions(BuildContext context) {
    List<Widget> chips = [];
    message.reactions.forEach((emoji, users) {
      if (users.isNotEmpty) {
        chips.add(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 2),
                Text('${users.length}', style: const TextStyle(fontSize: 10)),
              ],
            ),
          )
        );
      }
    });

    return Row(mainAxisSize: MainAxisSize.min, children: chips);
  }

  void _showMessageOptions(BuildContext context) {
    final currentUsername = context.read<AuthProvider>().currentUser?.username;
    final isMe = message.sender == currentUsername;
    final emojis = ['👍', '❤️', '😂', '😮', '😢', '🔥'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(ctx).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ...emojis.map((emoji) {
                      return GestureDetector(
                        onTap: () {
                          context.read<ChatProvider>().addReaction(message.roomId, message.id, emoji);
                          Navigator.pop(ctx);
                        },
                        child: Text(emoji, style: const TextStyle(fontSize: 28)),
                      );
                    }),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(ctx);
                        _showMoreEmojis(context, message.id);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(ctx).primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.add, color: Theme.of(ctx).primaryColor),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.reply),
                title: const Text('Reply'),
                onTap: () {
                  Navigator.pop(ctx);
                  if (onSwipeToReply != null) onSwipeToReply!();
                },
              ),
              ListTile(
                leading: const Icon(Icons.copy),
                title: const Text('Copy'),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: message.content));
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
                },
              ),
              ListTile(
                leading: const Icon(Icons.shortcut),
                title: const Text('Forward'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showForwardPicker(context, message.content);
                },
              ),
              if (isMe)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Delete', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    context.read<ChatProvider>().deleteMessage(message.roomId, message.id);
                    Navigator.pop(ctx);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _showReactionPicker(BuildContext context, String messageId) {
    final emojis = ['👍', '❤️', '😂', '😮', '😢', '🔥'];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Theme.of(ctx).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ...emojis.map((emoji) {
                return GestureDetector(
                  onTap: () {
                    context.read<ChatProvider>().addReaction(message.roomId, message.id, emoji);
                    Navigator.pop(ctx);
                  },
                  child: Text(emoji, style: const TextStyle(fontSize: 28)),
                );
              }),
              GestureDetector(
                onTap: () {
                  Navigator.pop(ctx);
                  _showMoreEmojis(context, messageId);
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(ctx).primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.add, color: Theme.of(ctx).primaryColor),
                ),
              ),
              if (onSwipeToReply != null)
                GestureDetector(
                  onTap: () {
                    Navigator.pop(ctx);
                    onSwipeToReply!();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(ctx).primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.reply, color: Theme.of(ctx).primaryColor),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showMoreEmojis(BuildContext context, String messageId) {
    final moreEmojis = [
      '😀', '😃', '😄', '😁', '😆', '😅', '😂', '🤣', '😊', '😇',
      '🙂', '🙃', '😉', '😌', '😍', '🥰', '😘', '😗', '😙', '😚',
      '😋', '😛', '😝', '😜', '🤪', '🤨', '🧐', '🤓', '😎', '🤩',
      '🥳', '😏', '😒', '😞', '😔', '😟', '😕', '🙁', '☹️', '😣',
      '😖', '😫', '😩', '🥺', '😢', '😭', '😤', '😠', '😡', '🤬',
      '🤯', '😳', '🥵', '🥶', '😱', '😨', '😰', '😥', '😓', '🤗',
      '🤔', '🤭', '🤫', '🤥', '😶', '😐', '😑', '😬', '🙄', '😯',
      '😦', '😧', '😮', '😲', '🥱', '😴', '🤤', '😪', '😵', '🤐',
      '🥴', '🤢', '🤮', '🤧', '😷', '🤒', '🤕', '🤑', '🤠', '😈',
      '👿', '👹', '👺', '🤡', '💩', '👻', '💀', '👽', '👾', '🤖',
      '💯', '💢', '💥', '💫', '💦', '💨', '🕳️', '💣', '💬', '👁️‍🗨️',
      '👍', '👎', '👏', '🙌', '👐', '🤲', '🤝', '🙏', '✍️', '💅',
    ];
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          maxChildSize: 0.8,
          expand: false,
          builder: (_, controller) {
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(ctx).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: GridView.builder(
                controller: controller,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                ),
                itemCount: moreEmojis.length,
                itemBuilder: (context, index) {
                  final emoji = moreEmojis[index];
                  return GestureDetector(
                    onTap: () {
                      context.read<ChatProvider>().addReaction(message.roomId, message.id, emoji);
                      Navigator.pop(ctx);
                    },
                    child: Center(
                      child: Text(emoji, style: const TextStyle(fontSize: 28)),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  void _showForwardPicker(BuildContext context, String content) {
    final roomProvider = context.read<RoomProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.5,
          maxChildSize: 0.9,
          builder: (_, controller) {
            return Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('Forward to...', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: controller,
                    itemCount: roomProvider.rooms.length,
                    itemBuilder: (context, index) {
                      final r = roomProvider.rooms[index];
                      // Use a simplified name display for direct rooms here if needed
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(ctx).primaryColor.withOpacity(0.1),
                          child: Icon(r.isDirect ? Icons.person : Icons.group, color: Theme.of(ctx).primaryColor),
                        ),
                        title: Text(r.name),
                        onTap: () {
                          context.read<ChatProvider>().forwardMessage(r.id, content);
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Forwarded to ${r.name}')));
                        },
                      );
                    },
                  ),
                )
              ],
            );
          },
        );
      },
    );
  }
}
