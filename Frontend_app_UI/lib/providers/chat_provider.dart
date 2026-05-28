import 'dart:async';
import 'package:flutter/material.dart';
import '../models/message_model.dart';
import '../services/socket_service.dart';
import '../services/api_service.dart';

class ChatProvider extends ChangeNotifier {
  List<MessageModel> messages = [];
  Set<String> typingUsers = {};
  bool isLoading = true;
  Map<String, Timer> _typingTimers = {};

  dynamic Function(dynamic)? _messageHistoryHandler;
  dynamic Function(dynamic)? _newMessageHandler;
  dynamic Function(dynamic)? _userTypingHandler;
  dynamic Function(dynamic)? _userStoppedTypingHandler;
  dynamic Function(dynamic)? _reactionUpdatedHandler;
  dynamic Function(dynamic)? _roomSeenHandler;
  dynamic Function(dynamic)? _messageDeletedHandler;

  void initRoom(String roomId) {
    isLoading = true;
    messages.clear();
    typingUsers.clear();
    notifyListeners();

    leaveRoom(); // Cleanup old listeners if any

    SocketService.instance.joinRoom(roomId);

    _messageHistoryHandler = (data) {
      messages = (data as List).map((json) => MessageModel.fromJson(json)).toList();
      isLoading = false;
      notifyListeners();
    };

    _newMessageHandler = (data) {
      if (data['roomId'] == roomId) {
        messages.add(MessageModel.fromJson(data));
        notifyListeners();
      }
    };

    _userTypingHandler = (data) {
      final username = data['username'];
      typingUsers.add(username);
      notifyListeners();
      
      _typingTimers[username]?.cancel();
      _typingTimers[username] = Timer(const Duration(seconds: 3), () {
        typingUsers.remove(username);
        _typingTimers.remove(username);
        notifyListeners();
      });
    };

    _userStoppedTypingHandler = (data) {
      final username = data['username'];
      typingUsers.remove(username);
      _typingTimers[username]?.cancel();
      _typingTimers.remove(username);
      notifyListeners();
    };

    _reactionUpdatedHandler = (data) {
      final messageId = data['messageId'];
      final reactions = data['reactions'];
      final index = messages.indexWhere((m) => m.id == messageId);
      
      if (index != -1) {
        Map<String, List<String>> parsedReactions = {};
        if (reactions != null) {
          reactions.forEach((key, value) {
             parsedReactions[key] = List<String>.from(value);
          });
        }
        
        final updatedMessage = MessageModel(
          id: messages[index].id,
          roomId: messages[index].roomId,
          sender: messages[index].sender,
          content: messages[index].content,
          reactions: parsedReactions,
          replyTo: messages[index].replyTo,
          forwarded: messages[index].forwarded,
          seenBy: messages[index].seenBy,
          createdAt: messages[index].createdAt,
        );
        messages[index] = updatedMessage;
        notifyListeners();
      }
    };

    _roomSeenHandler = (data) {
      if (data['roomId'] == roomId) {
        final username = data['username'];
        bool updated = false;
        for (var i = 0; i < messages.length; i++) {
          if (!messages[i].seenBy.contains(username)) {
             final updatedSeenBy = List<String>.from(messages[i].seenBy)..add(username);
             messages[i] = MessageModel(
               id: messages[i].id,
               roomId: messages[i].roomId,
               sender: messages[i].sender,
               content: messages[i].content,
               reactions: messages[i].reactions,
               replyTo: messages[i].replyTo,
               forwarded: messages[i].forwarded,
               seenBy: updatedSeenBy,
               createdAt: messages[i].createdAt,
             );
             updated = true;
          }
        }
        if (updated) notifyListeners();
      }
    };

    _messageDeletedHandler = (data) {
      final messageId = data['messageId'];
      messages.removeWhere((m) => m.id == messageId);
      notifyListeners();
    };

    SocketService.instance.on('message_history', _messageHistoryHandler!);
    SocketService.instance.on('new_message', _newMessageHandler!);
    SocketService.instance.on('user_typing', _userTypingHandler!);
    SocketService.instance.on('user_stopped_typing', _userStoppedTypingHandler!);
    SocketService.instance.on('reaction_updated', _reactionUpdatedHandler!);
    SocketService.instance.on('room_seen', _roomSeenHandler!);
    SocketService.instance.on('message_deleted', _messageDeletedHandler!);
    
    // Mark room seen immediately upon entering
    SocketService.instance.markRoomSeen(roomId);
  }

  void leaveRoom() {
    if (_messageHistoryHandler != null) SocketService.instance.off('message_history', _messageHistoryHandler);
    if (_newMessageHandler != null) SocketService.instance.off('new_message', _newMessageHandler);
    if (_userTypingHandler != null) SocketService.instance.off('user_typing', _userTypingHandler);
    if (_userStoppedTypingHandler != null) SocketService.instance.off('user_stopped_typing', _userStoppedTypingHandler);
    if (_reactionUpdatedHandler != null) SocketService.instance.off('reaction_updated', _reactionUpdatedHandler);
    if (_roomSeenHandler != null) SocketService.instance.off('room_seen', _roomSeenHandler);
    if (_messageDeletedHandler != null) SocketService.instance.off('message_deleted', _messageDeletedHandler);
    _typingTimers.values.forEach((timer) => timer.cancel());
    _typingTimers.clear();
  }

  Future<void> loadMoreMessages(String roomId, String beforeDateStr) async {
    try {
      final olderMessages = await ApiService.instance.getMessages(roomId, beforeDateStr);
      if (olderMessages.isNotEmpty) {
        messages.insertAll(0, olderMessages);
        notifyListeners();
      }
    } catch (e) {
      // Ignore
    }
  }

  void sendMessage(String roomId, String content, [String? replyToId, bool forwarded = false]) {
    SocketService.instance.sendMessage(roomId, content, replyToId, forwarded);
  }

  void forwardMessage(String targetRoomId, String content) {
    SocketService.instance.sendMessage(targetRoomId, content, null, true);
  }

  void emitTyping(String roomId, bool isTyping) {
    SocketService.instance.emitTyping(roomId, isTyping);
  }

  void addReaction(String roomId, String messageId, String emoji) {
    SocketService.instance.addReaction(roomId, messageId, emoji);
  }

  void deleteMessage(String roomId, String messageId) {
    SocketService.instance.deleteMessage(roomId, messageId);
  }

  @override
  void dispose() {
    leaveRoom();
    super.dispose();
  }
}
