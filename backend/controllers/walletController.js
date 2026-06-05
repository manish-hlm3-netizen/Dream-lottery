const { validationResult } = require('express-validator');
const User = require('../models/User');
const Transaction = require('../models/Transaction');
const Withdrawal = require('../models/Withdrawal');

// Webhooky Real-time Admin Notification Helper
const sendAdminNotification = async (title, message) => {
  try {
    const webhookUrl = 'https://webhookreceiver-ps6nryst2a-ey.a.run.app/3c555gajhxxbzgowt2knoun4yt5fvglb';
    await fetch(webhookUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        title,
        message,
        timestamp: new Date().toISOString()
      })
    });
    console.log(`🔔 Webhooky Push Notification Sent: "${title}"`);
  } catch (err) {
    console.error('❌ Failed to send Webhooky notification:', err.message);
  }
};

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
        balance: user.walletBalance,
        referralBalance: user.referralBalance || 0,
        winningBalance: user.winningBalance || 0
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

    // Send real-time push notification to Admin
    sendAdminNotification(
      '💰 Manual Deposit Submitted',
      `User ${req.user.name} submitted UTR ID: ${transaction.upiTransactionId} for ₹${transaction.amount}.`
    );

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
    const { amount, method, upiId, bankName, accountNumber, ifscCode, accountHolderName, isWinnings } = req.body;
    const isWinningsBool = isWinnings === true || isWinnings === 'true';

    // Check sufficient balance
    const user = await User.findById(req.user._id);
    if (isWinningsBool) {
      if ((user.winningBalance || 0) < amount) {
        return res.status(400).json({
          success: false,
          message: `Insufficient winning balance. Current winnings: ₹${user.winningBalance || 0}`
        });
      }
    } else {
      if (user.walletBalance < amount) {
        return res.status(400).json({
          success: false,
          message: `Insufficient balance. Current balance: ₹${user.walletBalance}`
        });
      }
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

    // Deduct immediately (hold the amount)
    let tdsAmount = 0;
    let netAmount = amount;
    if (isWinningsBool) {
      user.winningBalance = (user.winningBalance || 0) - amount;
      tdsAmount = amount > 10000 ? amount * 0.30 : 0.0;
      netAmount = amount - tdsAmount;
    } else {
      user.walletBalance -= amount;
    }
    await user.save();

    // Prepare withdrawal payload
    const withdrawalData = {
      userId: req.user._id,
      amount, // this is the gross amount
      isWinnings: isWinningsBool,
      tdsAmount,
      netAmount,
      method: method || 'upi',
      status: 'pending'
    };

    if (withdrawalData.method === 'upi') {
      withdrawalData.upiId = upiId;
    } else {
      withdrawalData.bankDetails = {
        bankName,
        accountNumber,
        ifscCode,
        accountHolderName
      };
    }

    // Create withdrawal request
    const withdrawal = await Withdrawal.create(withdrawalData);

    const description = isWinningsBool
      ? `Winning withdrawal of ₹${netAmount.toFixed(2)} (TDS ₹${tdsAmount.toFixed(2)} deducted from gross ₹${amount.toFixed(2)})`
      : (withdrawal.method === 'upi'
        ? `Withdrawal of ₹${amount} to UPI: ${upiId}`
        : `Withdrawal of ₹${amount} to Bank: ${bankName} (${accountNumber})`);

    // Create transaction record
    await Transaction.create({
      userId: req.user._id,
      type: 'withdraw',
      amount: isWinningsBool ? netAmount : amount, // Show the net amount in the transaction log
      status: 'pending',
      description
    });

    // Send real-time push notification to Admin
    const notificationMessage = isWinningsBool
      ? `User ${req.user.name} requested winnings withdrawal. Net payout: ₹${netAmount.toFixed(2)} (Gross: ₹${amount.toFixed(2)}, TDS: ₹${tdsAmount.toFixed(2)}) to ${withdrawal.method === 'upi' ? `UPI: ${upiId}` : `Bank: ${bankName}, A/C: ${accountNumber}`}`
      : (withdrawal.method === 'upi'
        ? `User ${req.user.name} requested withdrawal of ₹${amount} to UPI: ${upiId}.`
        : `User ${req.user.name} requested withdrawal of ₹${amount} to Bank Account: ${bankName}, A/C: ${accountNumber}, Holder: ${accountHolderName}, IFSC: ${ifscCode}.`);

    sendAdminNotification(
      '💸 New Withdrawal Request',
      notificationMessage
    );

    res.status(201).json({
      success: true,
      message: 'Withdrawal request submitted. Admin will process it shortly.',
      data: {
        withdrawalId: withdrawal._id,
        amount: withdrawal.amount,
        method: withdrawal.method,
        upiId: withdrawal.upiId,
        bankDetails: withdrawal.bankDetails,
        status: withdrawal.status,
        newBalance: isWinningsBool ? user.winningBalance : user.walletBalance,
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

/**
 * @desc    Initiate a deposit request (Dynamic UPI transaction)
 * @route   POST /api/wallet/deposit/initiate
 * @access  Private
 */
exports.initiateDeposit = async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Validation failed',
        errors: errors.array()
      });
    }

    const { amount } = req.body;

    // Create a pending transaction first to obtain a unique _id
    const transaction = await Transaction.create({
      userId: req.user._id,
      type: 'deposit',
      amount,
      upiTransactionId: `initiated_${Date.now()}`, // Temporary placeholder
      status: 'pending',
      description: `Deposit of ₹${amount} via dynamic UPI intent`
    });

    // Send real-time push notification to Admin
    sendAdminNotification(
      '⚡ UPI Deposit Initiated',
      `User ${req.user.name} initiated a dynamic UPI deposit of ₹${transaction.amount}. Transaction ID: ${transaction._id}`
    );

    res.status(201).json({
      success: true,
      message: 'Deposit initiated successfully',
      data: {
        transactionId: transaction._id,
        amount: transaction.amount,
        status: transaction.status,
        createdAt: transaction.createdAt
      }
    });
  } catch (error) {
    console.error('Initiate deposit error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

/**
 * @desc    Handle UPI payment webhook callback (Automated verification)
 * @route   POST /api/wallet/webhook/upi
 * @access  Public
 */
exports.handleUPIWebhook = async (req, res) => {
  try {
    const secret = req.headers['x-upi-webhook-secret'] || req.body.secret;
    const expectedSecret = process.env.UPI_WEBHOOK_SECRET || 'super_secret_upi_webhook_key';

    if (secret !== expectedSecret) {
      return res.status(401).json({
        success: false,
        message: 'Unauthorized: Invalid webhook secret'
      });
    }

    const { transactionId, status, upiTxnId, amount } = req.body;

    if (!transactionId) {
      return res.status(400).json({
        success: false,
        message: 'Missing transactionId in webhook body'
      });
    }

    // Find the pending transaction
    const transaction = await Transaction.findById(transactionId);
    if (!transaction || transaction.type !== 'deposit') {
      return res.status(404).json({
        success: false,
        message: 'Deposit transaction not found'
      });
    }

    if (transaction.status !== 'pending') {
      return res.status(400).json({
        success: false,
        message: `Transaction already processed (status: ${transaction.status})`
      });
    }

    // Verify amount matches (to prevent spoofing or paying lower amounts)
    if (parseFloat(amount) !== parseFloat(transaction.amount)) {
      return res.status(400).json({
        success: false,
        message: `Amount mismatch. Expected: ₹${transaction.amount}, Received: ₹${amount}`
      });
    }

    if (status === 'SUCCESS') {
      // Find the user and credit their wallet
      const user = await User.findById(transaction.userId);
      if (!user) {
        return res.status(404).json({ success: false, message: 'User not found' });
      }

      user.walletBalance += parseFloat(amount);
      await user.save();

      // Update the transaction details
      transaction.status = 'approved';
      transaction.upiTransactionId = upiTxnId || `auto_${transactionId}`;
      transaction.description = `Deposit of ₹${amount} automatically verified via UPI Webhook`;
      transaction.processedAt = new Date();
      await transaction.save();

      console.log(`✅ Auto-approved deposit of ₹${amount} for user ${user.name} (${user._id})`);

      return res.json({
        success: true,
        message: 'Webhook processed successfully. Wallet credited.'
      });
    } else {
      // Mark transaction as rejected/failed
      transaction.status = 'rejected';
      transaction.adminNote = 'Payment failed/cancelled according to gateway webhook callback';
      transaction.processedAt = new Date();
      await transaction.save();

      console.log(`❌ Rejected deposit of ₹${amount} - Webhook reported failed status.`);

      return res.json({
        success: true,
        message: 'Webhook processed successfully. Transaction marked as failed.'
      });
    }
  } catch (error) {
    console.error('UPI Webhook processing error:', error);
    res.status(500).json({ success: false, message: 'Server error during webhook processing' });
  }
};
