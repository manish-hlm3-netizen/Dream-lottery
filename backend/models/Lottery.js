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
    max: [99, 'Max number cannot exceed 99']
  },
  pickCount: {
    type: Number,
    default: 6,
    min: [3, 'Must pick at least 3 numbers'],
    max: [10, 'Cannot pick more than 10 numbers']
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
