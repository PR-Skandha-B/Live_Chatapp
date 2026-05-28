import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/room_model.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../main.dart';

class RoomProvider extends ChangeNotifier {
  List<RoomModel> rooms = [];
  bool isLoading = false;
  String? error;

  Map<String, int> unreadCounts = {};
  Map<String, String> latestMessages = {};
  Map<String, List<String>> onlineUsers = {};
  String? currentActiveRoom;
  bool _isListening = false;
  Set<String> mutedRooms = {};
  Set<String> archivedRooms = {};
  Set<String> pinnedRooms = {};

  RoomProvider() {
    try {
      final box = Hive.box('settings');
      
      final mutedList = box.get('muted_rooms', defaultValue: <dynamic>[]);
      mutedRooms = Set<String>.from(mutedList.map((e) => e.toString()));

      final archivedList = box.get('archived_rooms', defaultValue: <dynamic>[]);
      archivedRooms = Set<String>.from(archivedList.map((e) => e.toString()));

      final pinnedList = box.get('pinned_rooms', defaultValue: <dynamic>[]);
      pinnedRooms = Set<String>.from(pinnedList.map((e) => e.toString()));
    } catch (_) {}
  }

  void toggleMute(String roomId) {
    if (mutedRooms.contains(roomId)) {
      mutedRooms.remove(roomId);
    } else {
      mutedRooms.add(roomId);
    }
    notifyListeners();
    Hive.box('settings').put('muted_rooms', mutedRooms.toList());
  }

  void toggleArchive(String roomId) {
    if (archivedRooms.contains(roomId)) {
      archivedRooms.remove(roomId);
    } else {
      archivedRooms.add(roomId);
    }
    notifyListeners();
    Hive.box('settings').put('archived_rooms', archivedRooms.toList());
  }

  void togglePin(String roomId) {
    if (pinnedRooms.contains(roomId)) {
      pinnedRooms.remove(roomId);
    } else {
      pinnedRooms.add(roomId);
    }
    notifyListeners();
    Hive.box('settings').put('pinned_rooms', pinnedRooms.toList());
  }

  Future<void> leaveRoom(String roomId) async {
    try {
      await ApiService.instance.leaveRoom(roomId);
      rooms.removeWhere((r) => r.id == roomId);
      notifyListeners();
    } catch (e) {
      error = e.toString();
      notifyListeners();
    }
  }

  List<RoomModel> get activeRoomsList {
    final list = rooms.where((r) => !archivedRooms.contains(r.id)).toList();
    list.sort((a, b) {
      final aPinned = pinnedRooms.contains(a.id) ? 1 : 0;
      final bPinned = pinnedRooms.contains(b.id) ? 1 : 0;
      if (aPinned != bPinned) return bPinned.compareTo(aPinned);
      return 0; // maintain original order (usually by recent message/created)
    });
    return list;
  }

  List<RoomModel> get archivedRoomsList {
    return rooms.where((r) => archivedRooms.contains(r.id)).toList();
  }

  void setActiveRoom(String? roomId) {
    currentActiveRoom = roomId;
    if (roomId != null) {
      unreadCounts[roomId] = 0;
      notifyListeners();
    }
  }

  void initSocketListeners() {
    if (_isListening) return;
    _isListening = true;
    
    SocketService.instance.on('online_users', (data) {
      final roomId = data['roomId'];
      final users = List<String>.from(data['users']);
      if (roomId != null) {
        onlineUsers[roomId] = users;
        notifyListeners();
      }
    });

    SocketService.instance.on('room_restored', (data) {
      final roomId = data['roomId'];
      if (roomId != null) {
        fetchRooms();
      }
    });

    SocketService.instance.on('new_message', (data) async {
      final roomId = data['roomId'];
      if (roomId == null) return;
      if (mutedRooms.contains(roomId)) return; // Muted room
      
      final content = data['content'];

      if (!rooms.any((r) => r.id == roomId)) {
        await fetchRooms();
      }
      
      if (currentActiveRoom != roomId) {
        unreadCounts[roomId] = (unreadCounts[roomId] ?? 0) + 1;
        latestMessages[roomId] = content;
        notifyListeners();
        
        String roomName = 'Room';
        try {
          roomName = rooms.firstWhere((r) => r.id == roomId).name;
        } catch (_) {}
        
        final msgCount = unreadCounts[roomId];
        final context = navigatorKey.currentContext;
        if (context != null) {
          _showNotificationBubble(context, '[$roomName] ($msgCount new)', content);
        }
      }
    });
  }

  void _showNotificationBubble(BuildContext context, String title, String content) {
    final overlayState = Overlay.of(context);
    if (overlayState == null) return;
    
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) {
        final isWeb = kIsWeb;
        return Positioned(
          top: isWeb ? null : MediaQuery.of(context).padding.top + 16,
          bottom: isWeb ? 80 : null,
          right: 16,
          left: isWeb ? null : 16,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: isWeb ? 300 : null,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))],
              ),
              child: Row(
                children: [
                  const Icon(Icons.message, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        Text(content, style: const TextStyle(color: Colors.white70), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    overlayState.insert(entry);
    Future.delayed(const Duration(seconds: 4), () {
      if (entry.mounted) entry.remove();
    });
  }

  Future<void> fetchRooms() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      rooms = await ApiService.instance.getRooms();
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<RoomModel?> createRoom(String name, String desc) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final room = await ApiService.instance.createRoom(name, desc);
      rooms.insert(0, room);
      SocketService.instance.joinRoom(room.id);
      isLoading = false;
      notifyListeners();
      return room;
    } catch (e) {
      error = e.toString();
      isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<RoomModel?> createDirectRoom(String targetUsername) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final newRoom = await ApiService.instance.createDirectRoom(targetUsername);
      if (!rooms.any((r) => r.id == newRoom.id)) {
        rooms.insert(0, newRoom);
        SocketService.instance.joinRoom(newRoom.id); 
      }
      return newRoom;
    } catch (e) {
      error = e.toString();
      return null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<RoomModel?> joinRoom(String inviteCode) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final room = await ApiService.instance.joinRoom(inviteCode);
      if (!rooms.any((r) => r.id == room.id)) {
        rooms.insert(0, room);
      }
      SocketService.instance.joinRoom(room.id);
      isLoading = false;
      notifyListeners();
      return room;
    } catch (e) {
      error = e.toString();
      isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<RoomModel?> updateRoom(String roomId, String name, String description) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final updatedRoom = await ApiService.instance.updateRoom(roomId, name, description);
      final index = rooms.indexWhere((r) => r.id == roomId);
      if (index != -1) {
        rooms[index] = updatedRoom;
      }
      isLoading = false;
      notifyListeners();
      return updatedRoom;
    } catch (e) {
      error = e.toString();
      isLoading = false;
      notifyListeners();
      return null;
    }
  }
}
