const mongoose = require('mongoose');

const messageSchema = new mongoose.Schema({
  roomId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Room',
    required: true,
  },
  sender: { type: String, required: true },
  content: { type: String, required: true },
  reactions: { type: Map, of: [String], default: {} },
  replyTo: { type: mongoose.Schema.Types.ObjectId, ref: 'Message', default: null },
  forwarded: { type: Boolean, default: false },
  seenBy: [{ type: String }],
  createdAt: { type: Date, default: Date.now },
});

messageSchema.index({ roomId: 1, createdAt: -1 });

module.exports = mongoose.model('Message', messageSchema);
