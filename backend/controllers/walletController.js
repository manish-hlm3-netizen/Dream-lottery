const { validationResult } = require('express-validator');
const User = require('../models/User');
const Transaction = require('../models/Transaction');
const Withdrawal = require('../models/Withdrawal');

/**
 * @desc    Get wallet balance
 * @route   GET /api/wallet/balance
 * @access  Private
 */
exports.getBalance = async (req, res) => {
  try {
    const user = await User.findById(req.user._id);
    res.json({
      success: true,
      data: {
        balance: user.walletBalance
      }
    });
  } catch (error) {
    console.error('Get balance error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

/**
 * @desc    Submit deposit request (UPI payment)
 * @route   POST /api/wallet/deposit
 * @access  Private
 */
exports.deposit = async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Validation failed',
        errors: errors.array()
      });
    }

    const { amount, upiTransactionId } = req.body;

    // Check if UPI transaction ID already used
    const existingTxn = await Transaction.findOne({
      upiTransactionId,
      type: 'deposit',
      status: { $ne: 'rejected' }
    });

    if (existingTxn) {
      return res.status(400).json({
        success: false,
        message: 'This UPI transaction ID has already been submitted'
      });
    }

    // Create pending deposit transaction
    const transaction = await Transaction.create({
      userId: req.user._id,
      type: 'deposit',
      amount,
      upiTransactionId,
      status: 'pending',
      description: `Deposit of ₹${amount} via UPI`
    });

    res.status(201).json({
      success: true,
      message: 'Deposit request submitted. Waiting for admin approval.',
      data: {
        transactionId: transaction._id,
        amount: transaction.amount,
        status: transaction.status,
        upiTransactionId: transaction.upiTransactionId,
        createdAt: transaction.createdAt
      }
    });
  } catch (error) {
    console.error('Deposit error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

/**
 * @desc    Submit withdrawal request
 * @route   POST /api/wallet/withdraw
 * @access  Private
 */
exports.withdraw = async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Validation failed',
        errors: errors.array()
      });
    }

    const { amount, upiId } = req.body;

    // Check sufficient balance
    const user = await User.findById(req.user._id);
    if (user.walletBalance < amount) {
      return res.status(400).json({
        success: false,
        message: `Insufficient balance. Current balance: ₹${user.walletBalance}`
      });
    }

    // Check for existing pending withdrawal
    const pendingWithdrawal = await Withdrawal.findOne({
      userId: req.user._id,
      status: 'pending'
    });

    if (pendingWithdrawal) {
      return res.status(400).json({
        success: false,
        message: 'You already have a pending withdrawal request. Please wait for it to be processed.'
      });
    }

    // Deduct from wallet immediately (hold the amount)
    user.walletBalance -= amount;
    await user.save();

    // Create withdrawal request
    const withdrawal = await Withdrawal.create({
      userId: req.user._id,
      amount,
      upiId,
      status: 'pending'
    });

    // Create transaction record
    await Transaction.create({
      userId: req.user._id,
      type: 'withdraw',
      amount,
      status: 'pending',
      description: `Withdrawal of ₹${amount} to UPI: ${upiId}`
    });

    res.status(201).json({
      success: true,
      message: 'Withdrawal request submitted. Admin will process it shortly.',
      data: {
        withdrawalId: withdrawal._id,
        amount: withdrawal.amount,
        upiId: withdrawal.upiId,
        status: withdrawal.status,
        newBalance: user.walletBalance,
        createdAt: withdrawal.createdAt
      }
    });
  } catch (error) {
    console.error('Withdraw error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

/**
 * @desc    Get transaction history
 * @route   GET /api/wallet/transactions
 * @access  Private
 */
exports.getTransactions = async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const skip = (page - 1) * limit;

    const filter = { userId: req.user._id };

    // Optional type filter
    if (req.query.type) {
      filter.type = req.query.type;
    }

    const [transactions, total] = await Promise.all([
      Transaction.find(filter)
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit),
      Transaction.countDocuments(filter)
    ]);

    res.json({
      success: true,
      data: {
        transactions,
        pagination: {
          page,
          limit,
          total,
          pages: Math.ceil(total / limit)
        }
      }
    });
  } catch (error) {
    console.error('Get transactions error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

/**
 * @desc    Get withdrawal history
 * @route   GET /api/wallet/withdrawals
 * @access  Private
 */
exports.getWithdrawals = async (req, res) => {
  try {
    const withdrawals = await Withdrawal.find({ userId: req.user._id })
      .sort({ createdAt: -1 });

    res.json({
      success: true,
      data: { withdrawals }
    });
  } catch (error) {
    console.error('Get withdrawals error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};
