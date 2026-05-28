const User = require('../models/User');
const Transaction = require('../models/Transaction');
const Lottery = require('../models/Lottery');
const Ticket = require('../models/Ticket');
const Withdrawal = require('../models/Withdrawal');
const Announcement = require('../models/Announcement');
const { generateWinningNumbers, calculateMatches, determinePrize } = require('../utils/drawEngine');


/**
 * @desc    Get admin dashboard stats
 * @route   GET /api/admin/dashboard
 * @access  Admin
 */
exports.getDashboard = async (req, res) => {
  try {
    const [
      totalUsers,
      pendingDeposits,
      pendingWithdrawals,
      activeLotteries,
      completedLotteries,
      totalRevenue
    ] = await Promise.all([
      User.countDocuments({ role: 'user' }),
      Transaction.countDocuments({ type: 'deposit', status: 'pending' }),
      Withdrawal.countDocuments({ status: 'pending' }),
      Lottery.countDocuments({ status: { $in: ['upcoming', 'active'] } }),
      Lottery.countDocuments({ status: 'completed' }),
      Lottery.aggregate([
        { $match: { status: 'completed' } },
        { $group: { _id: null, total: { $sum: '$totalRevenue' } } }
      ])
    ]);

    // Recent transactions
    const recentTransactions = await Transaction.find()
      .populate('userId', 'name email')
      .sort({ createdAt: -1 })
      .limit(10);

    res.json({
      success: true,
      data: {
        stats: {
          totalUsers,
          pendingDeposits,
          pendingWithdrawals,
          activeLotteries,
          completedLotteries,
          totalRevenue: totalRevenue[0]?.total || 0
        },
        recentTransactions
      }
    });
  } catch (error) {
    console.error('Dashboard error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

/**
 * @desc    Get all users
 * @route   GET /api/admin/users
 * @access  Admin
 */
exports.getUsers = async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const skip = (page - 1) * limit;

    const search = req.query.search || '';
    const filter = { role: 'user' };

    if (search) {
      filter.$or = [
        { name: { $regex: search, $options: 'i' } },
        { email: { $regex: search, $options: 'i' } },
        { phone: { $regex: search, $options: 'i' } }
      ];
    }

    const [users, total] = await Promise.all([
      User.find(filter)
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit),
      User.countDocuments(filter)
    ]);

    res.json({
      success: true,
      data: {
        users,
        pagination: { page, limit, total, pages: Math.ceil(total / limit) }
      }
    });
  } catch (error) {
    console.error('Get users error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

/**
 * @desc    Toggle user active status
 * @route   PUT /api/admin/users/:id/toggle
 * @access  Admin
 */
exports.toggleUserStatus = async (req, res) => {
  try {
    const user = await User.findById(req.params.id);
    if (!user || user.role === 'admin') {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    user.isActive = !user.isActive;
    await user.save();

    res.json({
      success: true,
      message: `User ${user.isActive ? 'activated' : 'deactivated'} successfully`,
      data: { user }
    });
  } catch (error) {
    console.error('Toggle user error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

/**
 * @desc    Get pending deposits
 * @route   GET /api/admin/deposits
 * @access  Admin
 */
exports.getDeposits = async (req, res) => {
  try {
    const status = req.query.status || 'pending';
    const filter = { type: 'deposit' };
    if (status !== 'all') filter.status = status;

    const deposits = await Transaction.find(filter)
      .populate('userId', 'name email phone walletBalance')
      .sort({ createdAt: -1 });

    res.json({
      success: true,
      data: { deposits }
    });
  } catch (error) {
    console.error('Get deposits error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

/**
 * @desc    Approve or reject a deposit
 * @route   PUT /api/admin/deposits/:id
 * @access  Admin
 */
exports.processDeposit = async (req, res) => {
  try {
    const { action, adminNote } = req.body; // action: 'approve' or 'reject'

    if (!['approve', 'reject'].includes(action)) {
      return res.status(400).json({
        success: false,
        message: 'Action must be "approve" or "reject"'
      });
    }

    const transaction = await Transaction.findById(req.params.id);
    if (!transaction || transaction.type !== 'deposit') {
      return res.status(404).json({
        success: false,
        message: 'Deposit transaction not found'
      });
    }

    if (transaction.status !== 'pending') {
      return res.status(400).json({
        success: false,
        message: `Deposit already ${transaction.status}`
      });
    }

    if (action === 'approve') {
      // Add to user wallet
      const user = await User.findById(transaction.userId);
      user.walletBalance += transaction.amount;
      await user.save();

      transaction.status = 'approved';
    } else {
      transaction.status = 'rejected';
    }

    transaction.adminNote = adminNote || '';
    transaction.processedBy = req.user._id;
    transaction.processedAt = new Date();
    await transaction.save();

    res.json({
      success: true,
      message: `Deposit ${action === 'approve' ? 'approved' : 'rejected'} successfully`,
      data: { transaction }
    });
  } catch (error) {
    console.error('Process deposit error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

/**
 * @desc    Get withdrawals
 * @route   GET /api/admin/withdrawals
 * @access  Admin
 */
exports.getWithdrawals = async (req, res) => {
  try {
    const status = req.query.status || 'pending';
    const filter = {};
    if (status !== 'all') filter.status = status;

    const withdrawals = await Withdrawal.find(filter)
      .populate('userId', 'name email phone walletBalance')
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
 * @desc    Approve or reject a withdrawal
 * @route   PUT /api/admin/withdrawals/:id
 * @access  Admin
 */
exports.processWithdrawal = async (req, res) => {
  try {
    const { action, adminNote } = req.body;

    if (!['approve', 'reject'].includes(action)) {
      return res.status(400).json({
        success: false,
        message: 'Action must be "approve" or "reject"'
      });
    }

    const withdrawal = await Withdrawal.findById(req.params.id);
    if (!withdrawal) {
      return res.status(404).json({
        success: false,
        message: 'Withdrawal not found'
      });
    }

    if (withdrawal.status !== 'pending') {
      return res.status(400).json({
        success: false,
        message: `Withdrawal already ${withdrawal.status}`
      });
    }

    if (action === 'approve') {
      withdrawal.status = 'approved';
      // Amount was already deducted when user submitted the request
    } else {
      // Refund the amount back to user's wallet
      const user = await User.findById(withdrawal.userId);
      user.walletBalance += withdrawal.amount;
      await user.save();

      withdrawal.status = 'rejected';
    }

    withdrawal.adminNote = adminNote || '';
    withdrawal.processedBy = req.user._id;
    withdrawal.processedAt = new Date();
    await withdrawal.save();

    // Update corresponding transaction
    await Transaction.findOneAndUpdate(
      { userId: withdrawal.userId, type: 'withdraw', status: 'pending' },
      {
        status: action === 'approve' ? 'approved' : 'rejected',
        adminNote: adminNote || '',
        processedBy: req.user._id,
        processedAt: new Date()
      }
    );

    res.json({
      success: true,
      message: `Withdrawal ${action === 'approve' ? 'approved' : 'rejected'} successfully`,
      data: { withdrawal }
    });
  } catch (error) {
    console.error('Process withdrawal error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

/**
 * @desc    Create a new lottery
 * @route   POST /api/admin/lotteries
 * @access  Admin
 */
exports.createLottery = async (req, res) => {
  try {
    const { name, description, ticketPrice, prizes, maxNumber, pickCount, drawDate, isAutomatic } = req.body;

    if (!name || !ticketPrice || !drawDate) {
      return res.status(400).json({
        success: false,
        message: 'Name, ticket price, and draw date are required'
      });
    }

    // Validate draw date is in the future
    if (new Date(drawDate) <= new Date()) {
      return res.status(400).json({
        success: false,
        message: 'Draw date must be in the future'
      });
    }

    // Default prizes if not provided
    const defaultPrizes = [
      { match: pickCount || 6, label: 'Jackpot', amount: ticketPrice * 1000 },
      { match: (pickCount || 6) - 1, label: '2nd Prize', amount: ticketPrice * 100 },
      { match: (pickCount || 6) - 2, label: '3rd Prize', amount: ticketPrice * 10 },
      { match: (pickCount || 6) - 3, label: 'Consolation', amount: ticketPrice * 2 }
    ];

    const lottery = await Lottery.create({
      name,
      description: description || '',
      ticketPrice,
      prizes: prizes || defaultPrizes,
      maxNumber: maxNumber || 49,
      pickCount: pickCount || 6,
      drawDate: new Date(drawDate),
      isAutomatic: isAutomatic !== undefined ? isAutomatic : true,
      status: 'upcoming',
      createdBy: req.user._id
    });

    res.status(201).json({
      success: true,
      message: 'Lottery created successfully',
      data: { lottery }
    });
  } catch (error) {
    console.error('Create lottery error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

/**
 * @desc    Get all lotteries (admin view)
 * @route   GET /api/admin/lotteries
 * @access  Admin
 */
exports.getAllLotteries = async (req, res) => {
  try {
    const lotteries = await Lottery.find()
      .sort({ createdAt: -1 })
      .populate('createdBy', 'name email');

    res.json({
      success: true,
      data: { lotteries }
    });
  } catch (error) {
    console.error('Get all lotteries error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

/**
 * @desc    Update a lottery
 * @route   PUT /api/admin/lotteries/:id
 * @access  Admin
 */
exports.updateLottery = async (req, res) => {
  try {
    const lottery = await Lottery.findById(req.params.id);
    if (!lottery) {
      return res.status(404).json({
        success: false,
        message: 'Lottery not found'
      });
    }

    if (lottery.status === 'completed') {
      return res.status(400).json({
        success: false,
        message: 'Cannot edit a completed lottery'
      });
    }

    const allowedUpdates = ['name', 'description', 'ticketPrice', 'prizes', 'drawDate', 'isAutomatic', 'status'];
    const updates = {};
    for (const key of allowedUpdates) {
      if (req.body[key] !== undefined) {
        updates[key] = req.body[key];
      }
    }

    const updatedLottery = await Lottery.findByIdAndUpdate(
      req.params.id,
      updates,
      { new: true, runValidators: true }
    );

    res.json({
      success: true,
      message: 'Lottery updated successfully',
      data: { lottery: updatedLottery }
    });
  } catch (error) {
    console.error('Update lottery error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

/**
 * @desc    Manual draw - generate results and process winners
 * @route   POST /api/admin/lotteries/:id/draw
 * @access  Admin
 */
exports.drawLottery = async (req, res) => {
  try {
    const lottery = await Lottery.findById(req.params.id);
    if (!lottery) {
      return res.status(404).json({
        success: false,
        message: 'Lottery not found'
      });
    }

    if (lottery.status === 'completed') {
      return res.status(400).json({
        success: false,
        message: 'Draw has already been conducted'
      });
    }

    if (lottery.status === 'cancelled') {
      return res.status(400).json({
        success: false,
        message: 'This lottery was cancelled'
      });
    }

    // Generate winning numbers
    const winningNumbers = generateWinningNumbers(lottery.pickCount, lottery.maxNumber);

    // Update lottery
    lottery.winningNumbers = winningNumbers;
    lottery.status = 'completed';

    // Get all tickets for this lottery
    const tickets = await Ticket.find({ lotteryId: lottery._id });

    let totalPrizesPaid = 0;
    const winners = [];

    // Process each ticket
    for (const ticket of tickets) {
      const { matchedNumbers, matchCount } = calculateMatches(
        ticket.selectedNumbers,
        winningNumbers
      );

      const prizeWon = determinePrize(matchCount, lottery.prizes);

      ticket.matchedNumbers = matchedNumbers;
      ticket.matchCount = matchCount;
      ticket.prizeWon = prizeWon;
      ticket.status = prizeWon > 0 ? 'won' : 'lost';
      await ticket.save();

      if (prizeWon > 0) {
        // Credit winnings to user's wallet
        const user = await User.findById(ticket.userId);
        user.walletBalance += prizeWon;
        await user.save();

        // Create winnings transaction
        await Transaction.create({
          userId: ticket.userId,
          type: 'winnings',
          amount: prizeWon,
          status: 'approved',
          description: `Won ₹${prizeWon} in ${lottery.name} (matched ${matchCount} numbers)`
        });

        totalPrizesPaid += prizeWon;
        winners.push({
          userId: ticket.userId,
          matchCount,
          prizeWon,
          matchedNumbers
        });
      }
    }

    lottery.totalPrizesPaid = totalPrizesPaid;
    await lottery.save();

    res.json({
      success: true,
      message: 'Draw completed successfully!',
      data: {
        winningNumbers,
        totalTickets: tickets.length,
        totalWinners: winners.length,
        totalPrizesPaid,
        winners
      }
    });
  } catch (error) {
    console.error('Draw lottery error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

/**
 * @desc    Get lottery detail with tickets (admin view)
 * @route   GET /api/admin/lotteries/:id
 * @access  Admin
 */
exports.getLotteryDetail = async (req, res) => {
  try {
    const lottery = await Lottery.findById(req.params.id)
      .populate('createdBy', 'name email');

    if (!lottery) {
      return res.status(404).json({
        success: false,
        message: 'Lottery not found'
      });
    }

    const tickets = await Ticket.find({ lotteryId: lottery._id })
      .populate('userId', 'name email phone');

    res.json({
      success: true,
      data: { lottery, tickets }
    });
  } catch (error) {
    console.error('Get lottery detail error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

/**
 * @desc    Update a user's wallet balance directly
 * @route   PUT /api/admin/users/:id/wallet
 * @access  Admin
 */
exports.updateUserWallet = async (req, res) => {
  try {
    const { balance } = req.body;
    if (balance === undefined || isNaN(balance) || balance < 0) {
      return res.status(400).json({
        success: false,
        message: 'Please provide a valid wallet balance (minimum 0)'
      });
    }

    const user = await User.findById(req.params.id);
    if (!user || user.role === 'admin') {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    const oldBalance = user.walletBalance;
    user.walletBalance = balance;
    await user.save();

    // Create a transaction log for manual adjustments
    await Transaction.create({
      userId: user._id,
      type: 'deposit',
      amount: Math.abs(balance - oldBalance),
      status: 'approved',
      description: `Manual wallet adjustment by Admin from ₹${oldBalance} to ₹${balance}`
    });

    res.json({
      success: true,
      message: 'Wallet balance updated successfully',
      data: { user }
    });
  } catch (error) {
    console.error('Update wallet error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

/**
 * @desc    Change user's password directly
 * @route   PUT /api/admin/users/:id/password
 * @access  Admin
 */
exports.changeUserPassword = async (req, res) => {
  try {
    const { password } = req.body;
    if (!password || password.length < 6) {
      return res.status(400).json({
        success: false,
        message: 'Password must be at least 6 characters'
      });
    }

    const user = await User.findById(req.params.id);
    if (!user || user.role === 'admin') {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    user.password = password;
    await user.save(); // Triggers pre('save') to set plainPassword and hash it!

    res.json({
      success: true,
      message: 'User password updated successfully'
    });
  } catch (error) {
    console.error('Change password error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

/**
 * @desc    Get all announcements
 * @route   GET /api/admin/announcements
 * @access  Admin
 */
exports.getAdminAnnouncements = async (req, res) => {
  try {
    const announcements = await Announcement.find().sort({ createdAt: -1 });
    res.json({
      success: true,
      data: { announcements }
    });
  } catch (error) {
    console.error('Get announcements error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

/**
 * @desc    Create a new announcement
 * @route   POST /api/admin/announcements
 * @access  Admin
 */
exports.createAnnouncement = async (req, res) => {
  try {
    const { title, content } = req.body;
    if (!title || !content) {
      return res.status(400).json({
        success: false,
        message: 'Title and content are required'
      });
    }

    const announcement = await Announcement.create({ title, content });
    res.status(201).json({
      success: true,
      message: 'Announcement created successfully',
      data: { announcement }
    });
  } catch (error) {
    console.error('Create announcement error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

/**
 * @desc    Delete an announcement
 * @route   DELETE /api/admin/announcements/:id
 * @access  Admin
 */
exports.deleteAnnouncement = async (req, res) => {
  try {
    const announcement = await Announcement.findById(req.params.id);
    if (!announcement) {
      return res.status(404).json({
        success: false,
        message: 'Announcement not found'
      });
    }

    await announcement.deleteOne();
    res.json({
      success: true,
      message: 'Announcement deleted successfully'
    });
  } catch (error) {
    console.error('Delete announcement error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

