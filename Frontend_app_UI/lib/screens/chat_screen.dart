import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../providers/room_provider.dart';
import '../widgets/typing_indicator.dart';
import '../models/message_model.dart';
import '../providers/auth_provider.dart';
import '../widgets/message_bubble.dart';

class ChatScreen extends StatefulWidget {
  final String roomId;
  final String roomName;
  final String inviteCode;
  final int membersCount;
  final bool isDirect;

  const ChatScreen({
    super.key,
    required this.roomId,
    required this.roomName,
    required this.inviteCode,
    required this.membersCount,
    this.isDirect = false,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _scrollController = ScrollController();
  final _messageController = TextEditingController();
  MessageModel? replyingTo;

  late RoomProvider _roomProvider;

  bool _isLoadingOlder = false;

  @override
  void initState() {
    super.initState();
    _roomProvider = context.read<RoomProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _roomProvider.setActiveRoom(widget.roomId);
      context.read<ChatProvider>().initRoom(widget.roomId);
    });

    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels <= 100 &&
        !_isLoadingOlder) {
      _loadOlderMessages();
    }
  }

  Future<void> _loadOlderMessages() async {
    if (_isLoadingOlder) return;

    final chatProvider = context.read<ChatProvider>();

    if (chatProvider.messages.isEmpty) return;

    setState(() => _isLoadingOlder = true);

    final previousScrollHeight =
        _scrollController.position.maxScrollExtent;

    final oldestDate =
    chatProvider.messages.first.createdAt.toIso8601String();

    await chatProvider.loadMoreMessages(
      widget.roomId,
      oldestDate,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final newScrollHeight =
          _scrollController.position.maxScrollExtent;

      _scrollController.jumpTo(
        newScrollHeight - previousScrollHeight,
      );
    });

    if (mounted) {
      setState(() => _isLoadingOlder = false);
    }
  }

  @override
  void dispose() {
    _roomProvider.setActiveRoom(null);
    _scrollController.dispose();
    _messageController.dispose();
    _roomProvider.removeListener(() {}); // Just a safe space
    Provider.of<ChatProvider>(context, listen: false).leaveRoom();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendMessage() {
    final content = _messageController.text.trim();

    if (content.isNotEmpty) {
      context.read<ChatProvider>()
          .sendMessage(widget.roomId, content, replyingTo?.id);

      _messageController.clear();

      context.read<ChatProvider>()
          .emitTyping(widget.roomId, false);

      setState(() => replyingTo = null);

      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollToBottom();
      });
    }
  }

  void _showRoomInfo() {
    final roomProvider = context.read<RoomProvider>();
    final room = roomProvider.rooms.firstWhere((r) => r.id == widget.roomId);
    final currentUser = context.read<AuthProvider>().currentUser?.username;
    final isAdmin = room.createdBy == currentUser;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(widget.roomName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!widget.isDirect) ...[
              Text('Members: ${widget.membersCount}'),
              const SizedBox(height: 16),
              const Text('Invite Code:'),
              const SizedBox(height: 8),
              SelectableText(
                widget.inviteCode,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text('Participants:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SizedBox(
                height: 200,
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: room.members.length,
                  itemBuilder: (context, index) {
                    final m = room.members[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                        child: Icon(Icons.person, color: Theme.of(context).primaryColor),
                      ),
                      title: Text(m),
                      trailing: m != currentUser ? IconButton(
                        icon: const Icon(Icons.message),
                        onPressed: () async {
                          Navigator.pop(ctx); // close dialog
                          final newRoom = await roomProvider.createDirectRoom(m);
                          if (newRoom != null && mounted) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (_) => ChatScreen(
                                roomId: newRoom.id,
                                roomName: m,
                                inviteCode: newRoom.inviteCode,
                                membersCount: 2,
                                isDirect: true,
                              )),
                            );
                          }
                        },
                      ) : const Text('You'),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
            Consumer<RoomProvider>(
              builder: (ctx2, rp, _) {
                final isMuted = rp.mutedRooms.contains(widget.roomId);
                return SwitchListTile(
                  title: const Text('Mute Notifications'),
                  value: isMuted,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (val) {
                    rp.toggleMute(widget.roomId);
                  },
                );
              },
            ),
          ],
        ),
        actions: [
          if (!widget.isDirect)
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: widget.inviteCode));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copied to clipboard')),
                );
              },
              child: const Text('COPY'),
            ),
          if (isAdmin && !widget.isDirect)
            TextButton(
              onPressed: _showEditRoomDialog,
              child: const Text('EDIT'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }

  void _showEditRoomDialog() {
    final roomProvider = context.read<RoomProvider>();
    final room = roomProvider.rooms.firstWhere((r) => r.id == widget.roomId);
    final nameCtrl = TextEditingController(text: room.name);
    final descCtrl = TextEditingController(text: room.description);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Room Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Room Name'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () async {
              await roomProvider.updateRoom(widget.roomId, nameCtrl.text, descCtrl.text);
              if (mounted) {
                Navigator.pop(ctx);
                Navigator.pop(context); // Close info dialog
              }
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Consumer<RoomProvider>(
          builder: (ctx, roomProvider, _) {
            String currentName = widget.roomName;
            try {
              currentName = roomProvider.rooms.firstWhere((r) => r.id == widget.roomId).name;
            } catch (_) {}
            
            final onlineUsers = roomProvider.onlineUsers[widget.roomId] ?? [];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(currentName, style: const TextStyle(fontSize: 18)),
                if (onlineUsers.isNotEmpty)
                  Text(
                    '${onlineUsers.length} online',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: Colors.white70),
                  ),
              ],
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showRoomInfo,
          ),
        ],
      ),
      body: Consumer<ChatProvider>(
        builder: (context, chatProvider, _) {
          if (chatProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }



          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.light 
                 ? const Color(0xFFF0F4F8) 
                 : Colors.black87,
            ),
            child: Column(
              children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: chatProvider.messages.length + (_isLoadingOlder ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (_isLoadingOlder && index == 0) {
                      return const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      );
                    }
                    final messageIndex = _isLoadingOlder ? index - 1 : index;
                    final message = chatProvider.messages[messageIndex];
                    return MessageBubble(
                      message: message,
                      onSwipeToReply: () {
                        setState(() => replyingTo = message);
                      },
                    );
                  },
                ),
              ),
              TypingIndicator(typingUsers: chatProvider.typingUsers),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  boxShadow: [
                    BoxShadow(
                      offset: const Offset(0, -1),
                      blurRadius: 4,
                      color: Colors.black.withOpacity(0.1),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (replyingTo != null)
                        Container(
                          padding: const EdgeInsets.only(left: 12, right: 4, top: 4, bottom: 4),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border(left: BorderSide(color: Theme.of(context).primaryColor, width: 4)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Replying to ${replyingTo!.sender}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Theme.of(context).primaryColor)),
                                    const SizedBox(height: 2),
                                    Text(replyingTo!.content, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, size: 16),
                                onPressed: () => setState(() => replyingTo = null),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              )
                            ],
                          ),
                        ),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              decoration: InputDecoration(
                                hintText: 'Type a message...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Theme.of(context).scaffoldBackgroundColor,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              ),
                              onChanged: (val) {
                                chatProvider.emitTyping(widget.roomId, val.isNotEmpty);
                              },
                              onSubmitted: (_) => _sendMessage(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          CircleAvatar(
                            backgroundColor: Theme.of(context).primaryColor,
                            child: IconButton(
                              icon: const Icon(Icons.send, color: Colors.white),
                              onPressed: _sendMessage,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              ],
            ),
          );
        },
      ),
    );
  }
}
