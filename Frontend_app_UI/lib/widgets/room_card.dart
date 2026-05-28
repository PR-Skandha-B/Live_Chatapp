import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/room_model.dart';
import '../screens/chat_screen.dart';
import '../providers/room_provider.dart';
import '../providers/auth_provider.dart';

class RoomCard extends StatelessWidget {
  final RoomModel room;

  const RoomCard({super.key, required this.room});

  @override
  Widget build(BuildContext context) {
    final roomProvider = context.watch<RoomProvider>();
    final unreadCount = roomProvider.unreadCounts[room.id] ?? 0;
    final latestMsg = roomProvider.latestMessages[room.id] ?? room.description;
    
    final currentUser = context.read<AuthProvider>().currentUser?.username;
    String displayName = room.name;
    if (room.isDirect && currentUser != null) {
      displayName = room.members.firstWhere((m) => m != currentUser, orElse: () => room.name);
    }
    
    final avatarUrl = room.isDirect 
      ? null
      : 'https://api.dicebear.com/7.x/identicon/png?seed=$displayName';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: GestureDetector(
        onSecondaryTapDown: (_) {
          _showRoomOptions(context, roomProvider);
        },
        child: ListTile(
          onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatScreen(roomId: room.id, roomName: displayName, inviteCode: room.inviteCode, membersCount: room.members.length, isDirect: room.isDirect),
            ),
          );
        },
        onLongPress: () {
          _showRoomOptions(context, roomProvider);
        },
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
          backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
          child: avatarUrl == null ? Icon(room.isDirect ? Icons.person : Icons.group, color: Theme.of(context).primaryColor) : const SizedBox.shrink(),
        ),
        title: Text(
          displayName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: latestMsg.isNotEmpty 
            ? Text(latestMsg, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal))
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (roomProvider.pinnedRooms.contains(room.id))
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Icon(Icons.push_pin, size: 16, color: Colors.grey),
              ),
            if (roomProvider.mutedRooms.contains(room.id))
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Icon(Icons.volume_off, size: 16, color: Colors.grey),
              ),
            if (unreadCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('$unreadCount', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            if (unreadCount > 0) const SizedBox(width: 8),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
      ),
    );
  }

  void _showRoomOptions(BuildContext context, RoomProvider roomProvider) {
    final isPinned = roomProvider.pinnedRooms.contains(room.id);
    final isArchived = roomProvider.archivedRooms.contains(room.id);
    final isMuted = roomProvider.mutedRooms.contains(room.id);

    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(isPinned ? Icons.push_pin : Icons.push_pin_outlined),
                title: Text(isPinned ? 'Unpin Chat' : 'Pin Chat'),
                onTap: () {
                  roomProvider.togglePin(room.id);
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: Icon(isArchived ? Icons.unarchive : Icons.archive),
                title: Text(isArchived ? 'Unarchive Chat' : 'Archive Chat'),
                onTap: () {
                  roomProvider.toggleArchive(room.id);
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: Icon(isMuted ? Icons.volume_up : Icons.volume_off),
                title: Text(isMuted ? 'Unmute Notifications' : 'Mute Notifications'),
                onTap: () {
                  roomProvider.toggleMute(room.id);
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete / Leave Chat', style: TextStyle(color: Colors.red)),
                onTap: () {
                  roomProvider.leaveRoom(room.id);
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
