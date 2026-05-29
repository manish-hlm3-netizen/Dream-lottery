const mongoose = require('mongoose');

const ticketSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    index: true
  },
  lotteryId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Lottery',
    required: true,
    index: true
  },
  selectedNumbers: {
    type: [Number],
    required: [true, 'Selected numbers are required'],
    validate: {
      validator: function(arr) {
        return arr.length >= 1 && arr.length <= 10;
      },
      message: 'Must select between 1 and 10 numbers'
    }
  },
  matchedNumbers: {
    type: [Number],
    default: []
  },
  matchCount: {
    type: Number,
    default: 0
  },
  prizeWon: {
    type: Number,
    default: 0
  },
  status: {
    type: String,
    enum: ['active', 'won', 'lost'],
    default: 'active'
  },
  rank: {
    type: Number,
    default: 0
  },
  purchasedAt: {
    type: Date,
    default: Date.now
  }
}, {
  timestamps: true
});

// Compound index for checking duplicate tickets
ticketSchema.index({ userId: 1, lotteryId: 1 });

module.exports = mongoose.model('Ticket', ticketSchema);
