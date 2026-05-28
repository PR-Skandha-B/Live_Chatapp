const express = require('express');
const crypto = require('crypto');
const Room = require('../models/Room');
const Message = require('../models/Message');
const User = require('../models/User');
const { protect } = require('../middleware/auth');

const router = express.Router();
router.use(protect);

router.get('/', async (req, res) => {
  try {
    const rooms = await Room.find({
      members: req.user.username,
      deletedAt: null,
      [`deletedFor.${req.user.username}`]: { $exists: false }
    }).sort({ createdAt: -1 });
    res.status(200).json({ rooms });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.post('/', async (req, res) => {
  try {
    const { name, description } = req.body;
    if (!name) {
      return res.status(400).json({ error: 'Room name is required' });
    }

    const inviteCode = crypto.randomBytes(3).toString('hex').toUpperCase();

    const room = await Room.create({
      name,
      description,
      inviteCode,
      createdBy: req.user.username,
      members: [req.user.username],
      participants: [req.user.username],
    });

    res.status(201).json({ room });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.post('/direct', async (req, res) => {
  try {
    const { targetUsername } = req.body;
    if (!targetUsername) return res.status(400).json({ error: 'Target username is required' });
    if (targetUsername === req.user.username) return res.status(400).json({ error: 'Cannot create direct room with yourself' });

    const targetUser = await User.findOne({ username: targetUsername });
    if (!targetUser) return res.status(404).json({ error: 'User not found' });

    let room = await Room.findOne({
      isDirect: true,
      $or: [
        { participants: { $all: [req.user.username, targetUsername] } },
        { name: `${req.user.username}_${targetUsername}` },
        { name: `${targetUsername}_${req.user.username}` }
      ]
    });

    if (room) {
      if (!room.members.includes(req.user.username)) {
        room.members.push(req.user.username);
      }
      room.deletedAt = null; // restore from deletion if needed
      await room.save();
    } else {
      const inviteCode = crypto.randomBytes(3).toString('hex').toUpperCase();
      room = await Room.create({
        name: `${req.user.username}_${targetUsername}`,
        isDirect: true,
        inviteCode,
        createdBy: req.user.username,
        members: [req.user.username, targetUsername],
        participants: [req.user.username, targetUsername],
      });
    }
    res.status(200).json({ room });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.post('/join', async (req, res) => {
  try {
    const { inviteCode } = req.body;
    if (!inviteCode) {
      return res.status(400).json({ error: 'Invite code is required' });
    }

    const room = await Room.findOne({ inviteCode: inviteCode.toUpperCase() });
    if (!room) {
      return res.status(404).json({ error: 'Room not found' });
    }

    if (!room.members.includes(req.user.username)) {
      room.members.push(req.user.username);
      await room.save();
    }

    res.status(200).json({ room });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.get('/:id/messages', async (req, res) => {
  try {
    const room = await Room.findById(req.params.id);
    if (!room) return res.status(404).json({ error: 'Room not found' });

    let query = { roomId: req.params.id };
    
    if (req.query.before) {
       query.createdAt = { $lt: new Date(req.query.before) };
    }
    
    if (room.deletedFor && room.deletedFor.get(req.user.username)) {
      const deletedAt = room.deletedFor.get(req.user.username);
      if (query.createdAt) {
        query.createdAt = { ...query.createdAt, $gt: deletedAt };
      } else {
        query.createdAt = { $gt: deletedAt };
      }
    }

    const messages = await Message.find(query)
      .populate('replyTo', 'sender content')
      .sort({ createdAt: -1 })
      .limit(50);
      
    res.status(200).json({ messages: messages.reverse() });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.put('/:id', async (req, res) => {
  try {
    const { name, description } = req.body;
    let room = await Room.findById(req.params.id);
    if (!room) return res.status(404).json({ error: 'Room not found' });
    
    if (room.createdBy !== req.user.username) {
      return res.status(403).json({ error: 'Forbidden' });
    }

    room.name = name;
    room.description = description;
    await room.save();

    res.json({ room });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.delete('/:id/leave', async (req, res) => {
  try {
    const room = await Room.findById(req.params.id);

    if (!room) {
      return res.status(404).json({ error: 'Room not found' });
    }

    // Direct chats → hide only
    if (room.isDirect) {

      if (!room.deletedFor) {
        room.deletedFor = new Map();
      }

      room.deletedFor.set(req.user.username, new Date());

      await room.save();

      return res.status(200).json({ success: true });
    }

    // Group rooms → actually leave
    if (room.members.includes(req.user.username)) {

      room.members.pull(req.user.username);

      if (room.members.length === 0) {
        room.deletedAt = new Date();
      }

      await room.save();
    }

    res.status(200).json({ success: true });

  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});
module.exports = router;
