import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/room_provider.dart';
import '../widgets/room_card.dart';

class ArchivedRoomsScreen extends StatelessWidget {
  const ArchivedRoomsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Archived Chats'),
      ),
      body: Consumer<RoomProvider>(
        builder: (context, roomProvider, _) {
          final archivedRooms = roomProvider.archivedRoomsList;
          if (archivedRooms.isEmpty) {
            return const Center(child: Text('No archived chats'));
          }

          return ListView.builder(
            itemCount: archivedRooms.length,
            itemBuilder: (context, index) {
              return RoomCard(room: archivedRooms[index]);
            },
          );
        },
      ),
    );
  }
}
