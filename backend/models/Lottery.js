const mongoose = require('mongoose');

const lotterySchema = new mongoose.Schema({
  name: {
    type: String,
    required: [true, 'Lottery name is required'],
    trim: true,
    maxlength: [100, 'Name cannot exceed 100 characters']
  },
  description: {
    type: String,
    trim: true,
    maxlength: [500, 'Description cannot exceed 500 characters']
  },
  ticketPrice: {
    type: Number,
    required: [true, 'Ticket price is required'],
    min: [1, 'Ticket price must be at least ₹1']
  },
  prizePool: {
    type: Number,
    default: 0
  },
  prizes: [
    {
      match: { type: Number, required: true },
      label: { type: String, required: true },
      amount: { type: Number, required: true, min: 0 }
    }
  ],
  maxNumber: {
    type: Number,
    default: 49,
    min: [10, 'Max number must be at least 10'],
    max: [999, 'Max number cannot exceed 999']
  },
  pickCount: {
    type: Number,
    default: 6,
    min: [1, 'Must pick at least 1 number'],
    max: [10, 'Cannot pick more than 10 numbers']
  },
  maxTicketsPerUser: {
    type: Number,
    default: 3,
    min: [1, 'Must allow at least 1 ticket per user']
  },
  maxTickets: {
    type: Number,
    default: 1000,
    min: [1, 'Must allow at least 1 ticket in the lottery']
  },
  ticketsSoldMultiplier: {
    type: Number,
    default: 67,
    min: [1, 'Multiplier must be at least 1']
  },
  drawDate: {
    type: Date,
    required: [true, 'Draw date is required']
  },
  status: {
    type: String,
    enum: ['upcoming', 'active', 'drawing', 'completed', 'cancelled'],
    default: 'upcoming'
  },
  winningNumbers: {
    type: [Number],
    default: []
  },
  rankWinningNumbers: {
    type: [[Number]],
    default: []
  },
  isAutomatic: {
    type: Boolean,
    default: true
  },
  totalTicketsSold: {
    type: Number,
    default: 0
  },
  totalRevenue: {
    type: Number,
    default: 0
  },
  totalPrizesPaid: {
    type: Number,
    default: 0
  },
  createdBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  }
}, {
  timestamps: true
});

// Index for efficient queries
lotterySchema.index({ status: 1, drawDate: 1 });

module.exports = mongoose.model('Lottery', lotterySchema);
