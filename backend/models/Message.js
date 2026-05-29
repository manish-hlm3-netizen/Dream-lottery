const mongoose = require('mongoose');

const messageSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  sender: {
    type: String,
    enum: ['user', 'admin'],
    required: true
  },
  text: {
    type: String,
    required: [true, 'Message text is required'],
    trim: true
  },
  isRead: {
    type: Boolean,
    default: false
  }
}, {
  timestamps: true
});

// Indexes for fast lookups and chat sorting
messageSchema.index({ userId: 1, createdAt: 1 });
messageSchema.index({ sender: 1, isRead: 1 });

module.exports = mongoose.model('Message', messageSchema);
