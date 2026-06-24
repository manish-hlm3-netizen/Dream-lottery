const User = require('../models/User');
const Transaction = require('../models/Transaction');
const Lottery = require('../models/Lottery');
const Ticket = require('../models/Ticket');
const Withdrawal = require('../models/Withdrawal');
const Announcement = require('../models/Announcement');
const Settings = require('../models/Settings');
const Message = require('../models/Message');
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
      totalRevenue,
      unreadChats
    ] = await Promise.all([
      User.countDocuments({ role: 'user' }),
      Transaction.countDocuments({ type: 'deposit', status: 'pending' }),
      Withdrawal.countDocuments({ status: 'pending' }),
      Lottery.countDocuments({ status: { $in: ['upcoming', 'active'] } }),
      Lottery.countDocuments({ status: 'completed' }),
      Lottery.aggregate([
        { $match: { status: 'completed' } },
        { $group: { _id: null, total: { $sum: '$totalRevenue' } } }
      ]),
      Message.countDocuments({ sender: 'user', isRead: false })
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
          totalRevenue: totalRevenue[0]?.total || 0,
          unreadChats
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
    const isBot = req.query.isBot;
    const filter = { role: 'user' };

    if (isBot === 'true') {
      filter.isBot = true;
    } else if (isBot === 'false') {
      filter.isBot = { $ne: true };
    }

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
      .populate('userId', 'name email phone walletBalance winningBalance')
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
      .populate('userId', 'name email phone walletBalance winningBalance')
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
    } else {
      // Refund the amount back to user's wallet or winning balance
      const user = await User.findById(withdrawal.userId);
      if (withdrawal.isWinnings) {
        user.winningBalance = (user.winningBalance || 0) + withdrawal.amount;
      } else {
        user.walletBalance += withdrawal.amount;
      }
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
    const { name, description, ticketPrice, prizes, maxNumber, pickCount, drawDate, isAutomatic, maxTicketsPerUser, maxTickets, ticketsSoldMultiplier } = req.body;

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
      { match: 1, label: '1st Winner', amount: ticketPrice * 50 },
      { match: 2, label: '2nd Winner', amount: ticketPrice * 25 },
      { match: 3, label: '3rd Winner', amount: ticketPrice * 10 },
      { match: 4, label: '4th to 10th Winner', amount: ticketPrice * 3 }
    ];

    const lottery = await Lottery.create({
      name,
      description: description || '',
      ticketPrice,
      prizes: prizes || defaultPrizes,
      maxNumber: maxNumber || 49,
      pickCount: pickCount || 6,
      maxTicketsPerUser: maxTicketsPerUser !== undefined ? maxTicketsPerUser : 3,
      maxTickets: maxTickets !== undefined ? maxTickets : 1000,
      ticketsSoldMultiplier: ticketsSoldMultiplier !== undefined ? ticketsSoldMultiplier : 67,
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

    const allowedUpdates = ['name', 'description', 'ticketPrice', 'prizes', 'drawDate', 'isAutomatic', 'status', 'maxTicketsPerUser', 'maxTickets', 'ticketsSoldMultiplier', 'totalTicketsSold', 'totalRevenue'];
    const updates = {};
    for (const key of allowedUpdates) {
      if (req.body[key] !== undefined) {
        updates[key] = req.body[key];
      }
    }

    // Automatically recalculate totalRevenue if totalTicketsSold was modified but totalRevenue was not explicitly sent
    if (req.body.totalTicketsSold !== undefined && req.body.totalRevenue === undefined) {
      const ticketPrice = req.body.ticketPrice !== undefined ? req.body.ticketPrice : lottery.ticketPrice;
      updates.totalRevenue = Number(req.body.totalTicketsSold) * ticketPrice;
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

    // Helper to validate a winning numbers array
    const validateNumbers = (nums, name) => {
      if (!Array.isArray(nums) || nums.length !== lottery.pickCount) {
        throw new Error(`${name} must be an array of exactly ${lottery.pickCount} numbers.`);
      }
      const unique = new Set(nums);
      if (unique.size !== nums.length) {
        throw new Error(`All numbers in ${name} must be unique.`);
      }
      const invalid = nums.filter(
        n => isNaN(n) || !Number.isInteger(n) || n < 1 || n > lottery.maxNumber
      );
      if (invalid.length > 0) {
        throw new Error(`Numbers in ${name} must be between 1 and ${lottery.maxNumber}.`);
      }
      return nums.map(n => parseInt(n)).sort((a, b) => a - b);
    };

    let winningNumbers;
    const validatedRankWinningNumbers = Array(10).fill(null);

    try {
      if (req.body.rankWinningNumbers && Array.isArray(req.body.rankWinningNumbers)) {
        for (let i = 0; i < Math.min(10, req.body.rankWinningNumbers.length); i++) {
          const combo = req.body.rankWinningNumbers[i];
          if (combo) {
            validatedRankWinningNumbers[i] = validateNumbers(combo, `Rank ${i + 1} numbers`);
          }
        }
      }

      if (req.body.winningNumbers) {
        winningNumbers = validateNumbers(req.body.winningNumbers, 'Winning numbers');
      }
    } catch (err) {
      return res.status(400).json({
        success: false,
        message: err.message
      });
    }

    // Get all tickets for this lottery
    const tickets = await Ticket.find({ lotteryId: lottery._id });

    // Shuffle tickets randomly for raffle
    const shuffledTickets = [...tickets];
    for (let i = shuffledTickets.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [shuffledTickets[i], shuffledTickets[j]] = [shuffledTickets[j], shuffledTickets[i]];
    }

    // Determine final lottery winning numbers
    if (winningNumbers) {
      // Use explicit custom numbers
    } else if (validatedRankWinningNumbers[0]) {
      // Use Rank 1 custom numbers
      winningNumbers = validatedRankWinningNumbers[0];
    } else if (shuffledTickets.length > 0) {
      // Otherwise, match 1st winner's selectedNumbers
      winningNumbers = shuffledTickets[0].selectedNumbers;
    } else {
      // If no tickets, just generate random winning numbers
      winningNumbers = generateWinningNumbers(lottery.pickCount, lottery.maxNumber);
    }

    // Update lottery
    lottery.winningNumbers = winningNumbers;
    lottery.status = 'completed';

    let totalPrizesPaid = 0;
    const winners = [];

    // Helper to find prize by rank
    const getPrizeByRank = (rank, prizes) => {
      let targetMatch = 4;
      if (rank === 1) targetMatch = 1;
      else if (rank === 2) targetMatch = 2;
      else if (rank === 3) targetMatch = 3;

      const prizeTier = prizes.find(p => p.match === targetMatch);
      return prizeTier ? prizeTier.amount : 0;
    };

    // Determine initial ranks and prize tiers for all tickets in memory
    const ticketResults = [];
    for (const ticket of tickets) {
      const ticketNumsStr = ticket.selectedNumbers.join(',');

      let rank = 0;

      // 1. Check if this ticket matches any of the admin's custom rank winning combinations
      for (let r = 1; r <= 10; r++) {
        const customCombo = validatedRankWinningNumbers[r - 1];
        if (customCombo && ticketNumsStr === customCombo.join(',')) {
          rank = r;
          break;
        }
      }

      // 2. If no rank matched yet, fall back to standard raffle rank ONLY if no custom ranks were supplied
      if (rank === 0 && !req.body.rankWinningNumbers) {
        const shuffledIndex = shuffledTickets.findIndex(t => t._id.toString() === ticket._id.toString());
        if (shuffledIndex >= 0 && shuffledIndex < 10) {
          rank = shuffledIndex + 1;
        } else {
          // Check if it shares identical selected numbers with any of the primary winners
          for (let idx = 0; idx < Math.min(10, shuffledTickets.length); idx++) {
            if (shuffledTickets[idx].selectedNumbers.join(',') === ticketNumsStr) {
              rank = idx + 1;
              break;
            }
          }
        }
      }

      let initialPrize = 0;
      let matchedNumbers = [];
      let matchCount = 0;

      if (rank > 0) {
        initialPrize = getPrizeByRank(rank, lottery.prizes);
        matchedNumbers = ticket.selectedNumbers;
        matchCount = ticket.selectedNumbers.length; // 100% matched for winning tickets
      }

      ticketResults.push({
        ticket,
        rank,
        initialPrize,
        matchedNumbers,
        matchCount
      });
    }

    // Group winning tickets by their exact selectedNumbers string to calculate splits
    const groupCounts = {};
    for (const res of ticketResults) {
      if (res.initialPrize > 0) {
        const numsStr = res.ticket.selectedNumbers.join(',');
        groupCounts[numsStr] = (groupCounts[numsStr] || 0) + 1;
      }
    }

    // Apply the split division to final prizeWon and process tickets
    for (const res of ticketResults) {
      let finalPrize = res.initialPrize;
      let splitCount = 1;
      if (res.initialPrize > 0) {
        const numsStr = res.ticket.selectedNumbers.join(',');
        splitCount = groupCounts[numsStr] || 1;
        if (splitCount > 1) {
          finalPrize = Math.round((res.initialPrize / splitCount) * 100) / 100;
        }
      }

      const ticket = res.ticket;
      const prizeWon = finalPrize;
      const matchedNumbers = res.matchedNumbers;
      const matchCount = res.matchCount;

      ticket.matchedNumbers = matchedNumbers;
      ticket.matchCount = matchCount;
      ticket.prizeWon = prizeWon;
      ticket.status = prizeWon > 0 ? 'won' : 'lost';
      ticket.rank = res.rank;
      await ticket.save();

      if (prizeWon > 0) {
        // Credit winnings to user's wallet
        const user = await User.findById(ticket.userId);
        if (user) {
          user.winningBalance += prizeWon;
          await user.save();
        }

        // Create winnings transaction
        const splitDesc = splitCount > 1
          ? ` (Split among ${splitCount} winners with identical numbers)`
          : '';
        await Transaction.create({
          userId: ticket.userId,
          type: 'winnings',
          amount: prizeWon,
          status: 'approved',
          description: `Won ₹${prizeWon} in ${lottery.name} (matched ${matchCount} numbers)${splitDesc}`
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

    // Construct finalRankWinningNumbers array for transparency and fairness (10 ranks)
    const finalRankWinningNumbers = Array(10).fill(null);
    for (let r = 1; r <= 10; r++) {
      // 1. If custom combination was provided by admin for this rank, use it!
      if (validatedRankWinningNumbers[r - 1]) {
        finalRankWinningNumbers[r - 1] = validatedRankWinningNumbers[r - 1];
      }
      // 2. Otherwise, check if any ticket actually won this rank, and use its numbers!
      else {
        const winningRes = ticketResults.find(res => res.rank === r);
        if (winningRes) {
          finalRankWinningNumbers[r - 1] = winningRes.ticket.selectedNumbers;
        }
        // 3. Otherwise, if it is Rank 1, fall back to the primary winning numbers
        else if (r === 1) {
          finalRankWinningNumbers[0] = winningNumbers;
        }
        // 4. Otherwise, generate a random combination for that rank so users see what the target was
        else {
          finalRankWinningNumbers[r - 1] = generateWinningNumbers(lottery.pickCount, lottery.maxNumber);
        }
      }
    }
    lottery.rankWinningNumbers = finalRankWinningNumbers;

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
    const { balance, winningBalance, referralBalance } = req.body;
    if (balance === undefined && winningBalance === undefined && referralBalance === undefined) {
      return res.status(400).json({
        success: false,
        message: 'Please provide a wallet balance, winning balance, or referral balance to update'
      });
    }

    const user = await User.findById(req.params.id);
    if (!user || user.role === 'admin') {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    if (balance !== undefined) {
      if (isNaN(balance) || balance < 0) {
        return res.status(400).json({
          success: false,
          message: 'Please provide a valid wallet balance (minimum 0)'
        });
      }
      const oldBalance = user.walletBalance;
      user.walletBalance = balance;
      await Transaction.create({
        userId: user._id,
        type: 'deposit',
        amount: Math.abs(balance - oldBalance),
        status: 'approved',
        description: `Manual wallet adjustment by Admin from ₹${oldBalance} to ₹${balance}`
      });
    }

    if (winningBalance !== undefined) {
      if (isNaN(winningBalance) || winningBalance < 0) {
        return res.status(400).json({
          success: false,
          message: 'Please provide a valid winning balance (minimum 0)'
        });
      }
      const oldWinning = user.winningBalance || 0;
      user.winningBalance = winningBalance;
      await Transaction.create({
        userId: user._id,
        type: 'winnings',
        amount: Math.abs(winningBalance - oldWinning),
        status: 'approved',
        description: `Manual winning balance adjustment by Admin from ₹${oldWinning} to ₹${winningBalance}`
      });
    }

    if (referralBalance !== undefined) {
      if (isNaN(referralBalance) || referralBalance < 0) {
        return res.status(400).json({
          success: false,
          message: 'Please provide a valid referral balance (minimum 0)'
        });
      }
      const oldRefBalance = user.referralBalance || 0;
      user.referralBalance = referralBalance;
      await Transaction.create({
        userId: user._id,
        type: 'referral',
        amount: Math.abs(referralBalance - oldRefBalance),
        status: 'approved',
        description: `Manual referral balance adjustment by Admin from ₹${oldRefBalance} to ₹${referralBalance}`
      });
    }

    await user.save();

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
      data: announcements
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
    const { title, content, titleHi, contentHi } = req.body;
    if (!title || !content) {
      return res.status(400).json({
        success: false,
        message: 'Title and content are required'
      });
    }

    const announcement = await Announcement.create({ title, content, titleHi, contentHi });
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

/**
 * @desc    Update an announcement
 * @route   PUT /api/admin/announcements/:id
 * @access  Admin
 */
exports.updateAnnouncement = async (req, res) => {
  try {
    const { title, content, titleHi, contentHi } = req.body;
    if (!title || !content) {
      return res.status(400).json({
        success: false,
        message: 'Title and content are required'
      });
    }

    const announcement = await Announcement.findById(req.params.id);
    if (!announcement) {
      return res.status(404).json({
        success: false,
        message: 'Announcement not found'
      });
    }

    announcement.title = title;
    announcement.content = content;
    announcement.titleHi = titleHi;
    announcement.contentHi = contentHi;

    await announcement.save();

    res.json({
      success: true,
      message: 'Announcement updated successfully',
      data: { announcement }
    });
  } catch (error) {
    console.error('Update announcement error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

/**
 * @desc    Get current UPI payment settings
 * @route   GET /api/admin/settings/upi
 * @access  Admin
 */
exports.getUPISettings = async (req, res) => {
  try {
    let settings = await Settings.findOne({ key: 'upi_settings' });
    if (!settings) {
      settings = await Settings.create({
        key: 'upi_settings',
        upiId: 'pay@upi',
        qrCodeUrl: '',
        appVersion: '1.0.0',
        appDownloadUrl: 'https://dream-lottery.onrender.com/api/app/download'
      });
    }
    res.json({
      success: true,
      data: settings
    });
  } catch (error) {
    console.error('Get UPI settings error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

/**
 * @desc    Update UPI payment settings
 * @route   PUT /api/admin/settings/upi
 * @access  Admin
 */
exports.updateUPISettings = async (req, res) => {
  try {
    const { upiId, qrCodeUrl, appVersion, appDownloadUrl } = req.body;
    if (!upiId) {
      return res.status(400).json({
        success: false,
        message: 'UPI ID is required'
      });
    }

    let settings = await Settings.findOne({ key: 'upi_settings' });
    if (!settings) {
      settings = new Settings({ key: 'upi_settings' });
    }

    settings.upiId = upiId;
    if (qrCodeUrl !== undefined) {
      settings.qrCodeUrl = qrCodeUrl;
    }
    if (appVersion !== undefined) {
      settings.appVersion = appVersion;
    }
    if (appDownloadUrl !== undefined) {
      settings.appDownloadUrl = appDownloadUrl;
    }

    await settings.save();

    res.json({
      success: true,
      message: 'UPI payment settings updated successfully',
      data: settings
    });
  } catch (error) {
    console.error('Update UPI settings error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

/**
 * @desc    Get all unique users who have chat history
 * @route   GET /api/admin/chat/users
 * @access  Admin
 */
exports.getChatUsers = async (req, res) => {
  try {
    const uniqueUserIds = await Message.distinct('userId');
    const chatUsers = [];

    for (const userId of uniqueUserIds) {
      const user = await User.findById(userId).select('name email phone');
      if (!user) continue;

      const latestMessage = await Message.findOne({ userId }).sort({ createdAt: -1 });
      const unreadCount = await Message.countDocuments({ userId, sender: 'user', isRead: false });

      chatUsers.push({
        user,
        latestMessage: latestMessage ? {
          text: latestMessage.text,
          createdAt: latestMessage.createdAt,
          sender: latestMessage.sender
        } : null,
        unreadCount
      });
    }

    // Sort by latest message date descending (most active first)
    chatUsers.sort((a, b) => {
      const aTime = a.latestMessage ? new Date(a.latestMessage.createdAt) : 0;
      const bTime = b.latestMessage ? new Date(b.latestMessage.createdAt) : 0;
      return bTime - aTime;
    });

    res.json({
      success: true,
      data: { chatUsers }
    });
  } catch (error) {
    console.error('Get chat users error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

/**
 * @desc    Get full support chat history for a specific user
 * @route   GET /api/admin/chat/:userId
 * @access  Admin
 */
exports.getChatHistory = async (req, res) => {
  try {
    const { userId } = req.params;

    const user = await User.findById(userId).select('name email phone');
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    const messages = await Message.find({ userId }).sort({ createdAt: 1 });

    // Mark user's incoming messages as read
    await Message.updateMany(
      { userId, sender: 'user', isRead: false },
      { isRead: true }
    );

    res.json({
      success: true,
      data: {
        user,
        messages
      }
    });
  } catch (error) {
    console.error('Get chat history error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

/**
 * @desc    Send an admin reply message to a user
 * @route   POST /api/admin/chat/:userId
 * @access  Admin
 */
exports.adminSendMessage = async (req, res) => {
  try {
    const { userId } = req.params;
    const { text } = req.body;

    if (!text || !text.trim()) {
      return res.status(400).json({ success: false, message: 'Message text is required' });
    }

    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    const message = await Message.create({
      userId,
      sender: 'admin',
      text: text.trim(),
      isRead: true
    });

    res.status(201).json({
      success: true,
      data: { message }
    });
  } catch (error) {
    console.error('Admin send message error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

