import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/room_provider.dart';
import '../widgets/room_card.dart';
import 'create_room_screen.dart';
import 'join_room_screen.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import 'archived_rooms_screen.dart';
import 'chat_screen.dart';

class RoomsScreen extends StatefulWidget {
  const RoomsScreen({super.key});

  @override
  State<RoomsScreen> createState() => _RoomsScreenState();
}

class _RoomsScreenState extends State<RoomsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RoomProvider>().fetchRooms();
      context.read<RoomProvider>().initSocketListeners();
    });
  }

  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.add_circle_outline),
                title: const Text('Create Room'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CreateRoomScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.login),
                title: const Text('Join Room'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const JoinRoomScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.person_add),
                title: const Text('New Direct Message'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showDirectMessageDialog(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDirectMessageDialog(BuildContext context) {
    final usernameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Direct Message'),
        content: TextField(
          controller: usernameCtrl,
          decoration: const InputDecoration(labelText: 'Enter exact username'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () async {
              if (usernameCtrl.text.trim().isNotEmpty) {
                final newRoom = await context.read<RoomProvider>().createDirectRoom(usernameCtrl.text.trim());
                if (mounted) {
                   final error = context.read<RoomProvider>().error;
                   if (error != null) {
                     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: Colors.red));
                   } else {
                     Navigator.pop(ctx);
                     if (newRoom != null) {
                       final currentUser = context.read<AuthProvider>().currentUser?.username;
                       String displayName = newRoom.name;
                       if (newRoom.isDirect && currentUser != null) {
                         displayName = newRoom.members.firstWhere((m) => m != currentUser, orElse: () => newRoom.name);
                       }
                       Navigator.push(
                         context,
                         MaterialPageRoute(
                           builder: (_) => ChatScreen(roomId: newRoom.id, roomName: displayName, inviteCode: newRoom.inviteCode, membersCount: newRoom.members.length, isDirect: newRoom.isDirect),
                         ),
                       );
                     }
                   }
                }
              }
            },
            child: const Text('START CHAT'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final roomProvider = context.watch<RoomProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rooms'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'profile') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
              } else if (value == 'archived') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ArchivedRoomsScreen()));
              } else if (value == 'logout') {
                await context.read<AuthProvider>().logout();
                if (mounted) {
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                }
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem(value: 'profile', child: Text('Profile')),
                const PopupMenuItem(value: 'archived', child: Text('Archived Chats')),
                const PopupMenuItem(value: 'logout', child: Text('Logout')),
              ];
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<RoomProvider>().fetchRooms(),
        child: roomProvider.isLoading && roomProvider.activeRoomsList.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : roomProvider.error != null && roomProvider.activeRoomsList.isEmpty
                ? Center(child: Text('Error: ${roomProvider.error}'))
                : roomProvider.activeRoomsList.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 100),
                          Center(child: Text('No rooms yet. Create or join one!')),
                        ],
                      )
                    : ListView.builder(
                        itemCount: roomProvider.activeRoomsList.length,
                        itemBuilder: (context, index) {
                          return RoomCard(room: roomProvider.activeRoomsList[index]);
                        },
                      ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddOptions(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
