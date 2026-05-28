const mongoose = require('mongoose');

const roomSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true,
    trim: true,
  },
  description: {
    type: String,
    default: '',
  },
  isDirect: {
    type: Boolean,
    default: false,
  },
  icon: {
    type: String,
    default: '',
  },
  inviteCode: {
    type: String,
    required: true,
    unique: true,
  },
  createdBy: {
    type: String,
    required: true,
  },
  members: [{
    type: String,
  }],
  participants: [{
    type: String,
  }],
  deletedFor: {
    type: Map,
    of: Date,
    default: {},
  },
  createdAt: {
    type: Date,
    default: Date.now,
  },
  deletedAt: {
    type: Date,
    default: null,
    expires: 2592000, // 30 days in seconds
  },
});

module.exports = mongoose.model('Room', roomSchema);
