const jwt = require('jsonwebtoken');
const Message = require('../models/Message');
const Room = require('../models/Room');

module.exports = (io) => {
  const getOnlineUsers = async (roomId) => {
    const sockets = await io.in(roomId).fetchSockets();
    return sockets.map(s => s.data.username).filter(Boolean);
  };

  io.on('connection', async (socket) => {
    try {
      const token = socket.handshake.query.token;
      if (token) {
        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        socket.data.username = decoded.username;
        socket.join(decoded.username); // Join personal room
        const userRooms = await Room.find({ members: decoded.username });
        for (const r of userRooms) {
           const roomIdStr = r._id.toString();
           socket.join(roomIdStr);
           const onlineUsers = await getOnlineUsers(roomIdStr);
           io.to(roomIdStr).emit('online_users', { roomId: roomIdStr, users: onlineUsers });
        }
      }
    } catch(err) {
      console.error('Global socket connection error:', err.message);
    }

    socket.on('join_room', async ({ roomId, token }) => {
      try {
        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        const username = decoded.username;

        socket.join(roomId);
        socket.data = { username, roomId };

        const room = await Room.findById(roomId);
        let query = { roomId };
        
        if (room && room.deletedFor && room.deletedFor.get(username)) {
          const deletedAt = room.deletedFor.get(username);
          query.createdAt = { $gt: deletedAt };
        }

        const messages = await Message.find(query)
          .populate('replyTo', 'sender content')
          .sort({ createdAt: 1 })
          .limit(50);

        socket.emit('message_history', messages);

        socket.to(roomId).emit('user_joined', { 
          username, 
          timestamp: new Date() 
        });

        const onlineUsers = await getOnlineUsers(roomId);
        io.to(roomId).emit('online_users', { roomId, users: onlineUsers });

      } catch (err) {
        socket.emit('error', { message: 'Invalid token' });
      }
    });

    socket.on('send_message', async ({ roomId, content, replyToId, forwarded }) => {
      if (!socket.data.username) return;

      try {
        let msg = await Message.create({
          roomId,
          sender: socket.data.username,
          content,
          replyTo: replyToId || null,
          forwarded: forwarded || false,
          seenBy: [socket.data.username]
        });

        const room = await Room.findById(roomId);

        let restoredParticipants = [];

        if (room && room.isDirect) {

          room.participants.forEach(p => {

            // Restore deleted chats
            if (room.deletedFor && room.deletedFor.get(p)) {

              // Don't restore for sender
              if (p !== socket.data.username) {
                room.deletedFor.delete(p);
                restoredParticipants.push(p);
              }
            }

            // Re-add removed members if needed
            if (!room.members.includes(p)) {
              room.members.push(p);
            }
          });

          room.deletedAt = null;

          await room.save();
        }

        msg = await msg.populate('replyTo', 'sender content');

        const msgPayload = {
          _id: msg._id,
          roomId: msg.roomId,
          sender: msg.sender,
          content: msg.content,
          reactions: msg.reactions,
          replyTo: msg.replyTo,
          forwarded: msg.forwarded,
          seenBy: msg.seenBy,
          createdAt: msg.createdAt,
        };

        if (room && room.isDirect) {
          room.participants.forEach(p => {
            io.to(p).emit('new_message', msgPayload);
          });
        } else {
          io.to(roomId).emit('new_message', msgPayload);
        }

        if (restoredParticipants.length > 0) {
          restoredParticipants.forEach(p => {
            io.to(p).emit('room_restored', { roomId });
          });
        }
      } catch (err) {
        console.error('Error saving message:', err);
      }
    });

    socket.on('typing_start', ({ roomId }) => {
      if (!socket.data.username) return;
      socket.to(roomId).emit('user_typing', { username: socket.data.username });
    });

    socket.on('typing_stop', ({ roomId }) => {
      if (!socket.data.username) return;
      socket.to(roomId).emit('user_stopped_typing', { username: socket.data.username });
    });

    socket.on('add_reaction', async ({ roomId, messageId, emoji }) => {
      if (!socket.data.username) return;
      
      try {
        const msg = await Message.findById(messageId);
        if (!msg) return;

        let reactions = msg.reactions || new Map();
        let users = reactions.get(emoji) || [];
        
        if (users.includes(socket.data.username)) {
          // Remove reaction
          users = users.filter(u => u !== socket.data.username);
          if (users.length === 0) reactions.delete(emoji);
          else reactions.set(emoji, users);
        } else {
          // Exchange/Add: remove from all other emojis first
          for (let [key, val] of reactions.entries()) {
            let filtered = val.filter(u => u !== socket.data.username);
            if (filtered.length === 0) reactions.delete(key);
            else reactions.set(key, filtered);
          }
          let newUsers = reactions.get(emoji) || [];
          newUsers.push(socket.data.username);
          reactions.set(emoji, newUsers);
        }
        
        msg.reactions = reactions;
        await msg.save();
        
        io.to(roomId).emit('reaction_updated', { 
          messageId, 
          reactions: Object.fromEntries(msg.reactions) 
        });
      } catch (err) {
        console.error('Error adding reaction:', err);
      }
    });

    socket.on('mark_room_seen', async ({ roomId }) => {
      if (!socket.data.username) return;
      try {
        await Message.updateMany(
          { roomId, seenBy: { $ne: socket.data.username } },
          { $push: { seenBy: socket.data.username } }
        );
        io.to(roomId).emit('room_seen', { roomId, username: socket.data.username });
      } catch (err) {
        console.error('Error marking seen:', err);
      }
    });

    socket.on('delete_message', async ({ roomId, messageId }) => {
      if (!socket.data.username) return;
      try {
        const msg = await Message.findById(messageId);
        if (!msg) return;
        if (msg.sender !== socket.data.username) return; // Only allow sender to delete

        await Message.findByIdAndDelete(messageId);
        io.to(roomId).emit('message_deleted', { messageId });
      } catch (err) {
        console.error('Error deleting message:', err);
      }
    });

    socket.on('disconnecting', async () => {
      for (const roomId of socket.rooms) {
        if (roomId !== socket.id) {
           const sockets = await io.in(roomId).fetchSockets();
           const onlineUsers = sockets
               .filter(s => s.id !== socket.id)
               .map(s => s.data.username)
               .filter(Boolean);
           io.to(roomId).emit('online_users', { roomId, users: onlineUsers });
        }
      }
    });

    socket.on('disconnect', () => {
      if (socket.data.roomId && socket.data.username) {
        socket.to(socket.data.roomId).emit('user_left', { username: socket.data.username });
      }
    });

  });
};
