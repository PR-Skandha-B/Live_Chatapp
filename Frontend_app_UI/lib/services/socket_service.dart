import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../utils/constants.dart';

class SocketService {
  SocketService._privateConstructor();
  static final SocketService instance = SocketService._privateConstructor();

  IO.Socket? _socket;
  String? _token;

  bool get isConnected => _socket?.connected ?? false;

  void connect(String token) {
    _token = token;
    if (_socket != null) {
      _socket!.disconnect();
    }
    
    _socket = IO.io(
      AppConstants.socketUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setQuery({'token': token})
          .build(),
    );

    _socket!.connect();
    
    _socket!.onConnectError((data) => print('Socket Connect Error: $data'));
    _socket!.onError((data) => print('Socket Error: $data'));
  }

  void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket = null;
      _token = null;
    }
  }

  void joinRoom(String roomId) {
    if (_socket != null && _token != null) {
      _socket!.emit('join_room', {'roomId': roomId, 'token': _token});
    }
  }

  void sendMessage(String roomId, String content, [String? replyToId, bool forwarded = false]) {
    if (_socket != null) {
      _socket!.emit('send_message', {
        'roomId': roomId, 
        'content': content,
        if (replyToId != null) 'replyToId': replyToId,
        'forwarded': forwarded,
      });
    }
  }

  void markRoomSeen(String roomId) {
    if (_socket != null) {
      _socket!.emit('mark_room_seen', {'roomId': roomId});
    }
  }

  void emitTyping(String roomId, bool isTyping) {
    if (_socket != null) {
      if (isTyping) {
        _socket!.emit('typing_start', {'roomId': roomId});
      } else {
        _socket!.emit('typing_stop', {'roomId': roomId});
      }
    }
  }

  void addReaction(String roomId, String messageId, String emoji) {
    if (_socket != null) {
      _socket!.emit('add_reaction', {'roomId': roomId, 'messageId': messageId, 'emoji': emoji});
    }
  }

  void deleteMessage(String roomId, String messageId) {
    if (_socket != null) {
      _socket!.emit('delete_message', {'roomId': roomId, 'messageId': messageId});
    }
  }

  void on(String event, dynamic Function(dynamic) handler) {
    if (_socket != null) {
      _socket!.on(event, handler);
    }
  }

  void off(String event, [dynamic Function(dynamic)? handler]) {
    if (_socket != null) {
      if (handler != null) {
        _socket!.off(event, handler);
      } else {
        _socket!.off(event);
      }
    }
  }
}
