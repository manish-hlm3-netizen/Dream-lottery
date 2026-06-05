const mongoose = require('mongoose');

const withdrawalSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    index: true
  },
  amount: {
    type: Number,
    required: [true, 'Amount is required'],
    min: [100, 'Minimum withdrawal is ₹100']
  },
  method: {
    type: String,
    enum: ['upi', 'bank'],
    default: 'upi'
  },
  upiId: {
    type: String,
    trim: true
  },
  bankDetails: {
    bankName: { type: String, trim: true },
    accountNumber: { type: String, trim: true },
    ifscCode: { type: String, trim: true },
    accountHolderName: { type: String, trim: true }
  },
  status: {
    type: String,
    enum: ['pending', 'approved', 'rejected'],
    default: 'pending'
  },
  adminNote: {
    type: String,
    trim: true
  },
  processedBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  },
  processedAt: {
    type: Date
  },
  isWinnings: {
    type: Boolean,
    default: false
  },
  tdsAmount: {
    type: Number,
    default: 0
  },
  netAmount: {
    type: Number,
    default: 0
  },
  cessAmount: {
    type: Number,
    default: 0
  },
  cessTransactionId: {
    type: String,
    trim: true
  }
}, {
  timestamps: true
});

// Index for admin queries
withdrawalSchema.index({ status: 1, createdAt: -1 });

module.exports = mongoose.model('Withdrawal', withdrawalSchema);
