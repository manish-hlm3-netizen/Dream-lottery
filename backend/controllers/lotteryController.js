const { validationResult } = require('express-validator');
const User = require('../models/User');
const Lottery = require('../models/Lottery');
const Ticket = require('../models/Ticket');
const Transaction = require('../models/Transaction');

/**
 * @desc    Get all active/upcoming lotteries
 * @route   GET /api/lotteries
 * @access  Private
 */
exports.getLotteries = async (req, res) => {
  try {
    const status = req.query.status || 'active';
    const filter = {};

    if (status === 'all') {
      // Return all non-cancelled
      filter.status = { $ne: 'cancelled' };
    } else if (status === 'completed') {
      filter.status = 'completed';
    } else {
      filter.status = { $in: ['upcoming', 'active'] };
    }

    const lotteries = await Lottery.find(filter)
      .sort({ drawDate: 1 })
      .select('-__v');

    res.json({
      success: true,
      data: { lotteries }
    });
  } catch (error) {
    console.error('Get lotteries error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

/**
 * @desc    Get lottery details
 * @route   GET /api/lotteries/:id
 * @access  Private
 */
exports.getLotteryById = async (req, res) => {
  try {
    const lottery = await Lottery.findById(req.params.id);
    if (!lottery) {
      return res.status(404).json({
        success: false,
        message: 'Lottery not found'
      });
    }

    res.json({
      success: true,
      data: { lottery }
    });
  } catch (error) {
    console.error('Get lottery error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

/**
 * @desc    Buy a lottery ticket
 * @route   POST /api/lotteries/:id/buy
 * @access  Private
 */
exports.buyTicket = async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Validation failed',
        errors: errors.array()
      });
    }

    const { selectedNumbers } = req.body;
    const lotteryId = req.params.id;

    // Get lottery
    const lottery = await Lottery.findById(lotteryId);
    if (!lottery) {
      return res.status(404).json({
        success: false,
        message: 'Lottery not found'
      });
    }

    // Check lottery is active
    if (!['upcoming', 'active'].includes(lottery.status)) {
      return res.status(400).json({
        success: false,
        message: 'This lottery is no longer accepting tickets'
      });
    }

    // Check if total tickets sold has reached maxTickets cap
    if (lottery.totalTicketsSold >= (lottery.maxTickets || 1000)) {
      return res.status(400).json({
        success: false,
        message: 'This lottery has reached its maximum tickets capacity.'
      });
    }

    // Check if user already bought maximum tickets for this lottery
    const ticketCount = await Ticket.countDocuments({ userId: req.user._id, lotteryId });
    const userLimit = lottery.maxTicketsPerUser || 3;
    if (ticketCount >= userLimit) {
      return res.status(400).json({
        success: false,
        message: `You have already purchased the maximum of ${userLimit} tickets allowed for this lottery.`
      });
    }

    // Check draw date hasn't passed
    if (new Date(lottery.drawDate) <= new Date()) {
      return res.status(400).json({
        success: false,
        message: 'This lottery draw date has passed'
      });
    }

    // Validate selected numbers
    if (!selectedNumbers || selectedNumbers.length !== lottery.pickCount) {
      return res.status(400).json({
        success: false,
        message: `You must select exactly ${lottery.pickCount} numbers`
      });
    }

    // Check numbers are valid (within range and unique)
    const uniqueNums = new Set(selectedNumbers);
    if (uniqueNums.size !== selectedNumbers.length) {
      return res.status(400).json({
        success: false,
        message: 'All selected numbers must be unique'
      });
    }

    const invalidNums = selectedNumbers.filter(
      n => !Number.isInteger(n) || n < 1 || n > lottery.maxNumber
    );
    if (invalidNums.length > 0) {
      return res.status(400).json({
        success: false,
        message: `Numbers must be between 1 and ${lottery.maxNumber}`
      });
    }

    // Check if user already bought a ticket with these numbers for this lottery
    const sortedNumbers = [...selectedNumbers].sort((a, b) => a - b);
    const existingTicket = await Ticket.findOne({
      userId: req.user._id,
      lotteryId,
      selectedNumbers: sortedNumbers
    });
    if (existingTicket) {
      return res.status(400).json({
        success: false,
        message: 'You have already purchased a ticket with these numbers for this lottery.'
      });
    }

    // Check wallet balance
    const user = await User.findById(req.user._id);
    const refBal = user.referralBalance || 0;
    const winBal = user.winningBalance || 0;
    const depBal = user.walletBalance || 0;
    const totalBalance = refBal + winBal + depBal;

    if (totalBalance < lottery.ticketPrice) {
      return res.status(400).json({
        success: false,
        message: `Insufficient balance. Ticket costs ₹${lottery.ticketPrice}. Your balance: ₹${totalBalance}`
      });
    }

    // Deduct from wallet: referral balance first, then winning balance, then deposit balance
    let remainingToPay = lottery.ticketPrice;
    
    // 1. Referral balance first
    if ((user.referralBalance || 0) >= remainingToPay) {
      user.referralBalance = (user.referralBalance || 0) - remainingToPay;
      remainingToPay = 0;
    } else {
      remainingToPay -= (user.referralBalance || 0);
      user.referralBalance = 0;
    }

    // 2. Winning balance second
    if (remainingToPay > 0) {
      if ((user.winningBalance || 0) >= remainingToPay) {
        user.winningBalance = (user.winningBalance || 0) - remainingToPay;
        remainingToPay = 0;
      } else {
        remainingToPay -= (user.winningBalance || 0);
        user.winningBalance = 0;
      }
    }

    // 3. Deposit balance (walletBalance) third
    if (remainingToPay > 0) {
      user.walletBalance = (user.walletBalance || 0) - remainingToPay;
      remainingToPay = 0;
    }

    await user.save();

    // Create ticket
    const ticket = await Ticket.create({
      userId: req.user._id,
      lotteryId,
      selectedNumbers: selectedNumbers.sort((a, b) => a - b)
    });

    // Update lottery stats
    lottery.totalTicketsSold += 1;
    lottery.totalRevenue += lottery.ticketPrice;
    if (lottery.status === 'upcoming') {
      lottery.status = 'active';
    }
    await lottery.save();

    // Create transaction record
    await Transaction.create({
      userId: req.user._id,
      type: 'ticket_purchase',
      amount: lottery.ticketPrice,
      status: 'approved',
      description: `Ticket for ${lottery.name} - Numbers: ${ticket.selectedNumbers.join(', ')}`
    });

    res.status(201).json({
      success: true,
      message: 'Ticket purchased successfully!',
      data: {
        ticket: {
          id: ticket._id,
          lotteryId: ticket.lotteryId,
          selectedNumbers: ticket.selectedNumbers,
          status: ticket.status,
          purchasedAt: ticket.purchasedAt
        },
        newBalance: user.walletBalance
      }
    });
  } catch (error) {
    console.error('Buy ticket error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

/**
 * @desc    Get user's tickets for a specific lottery
 * @route   GET /api/lotteries/:id/my-tickets
 * @access  Private
 */
exports.getMyTickets = async (req, res) => {
  try {
    const tickets = await Ticket.find({
      userId: req.user._id,
      lotteryId: req.params.id
    }).populate('lotteryId', 'name drawDate status winningNumbers');

    res.json({
      success: true,
      data: { tickets }
    });
  } catch (error) {
    console.error('Get my tickets error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

/**
 * @desc    Get all user's tickets
 * @route   GET /api/tickets/my-tickets
 * @access  Private
 */
exports.getAllMyTickets = async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const skip = (page - 1) * limit;

    const filter = { userId: req.user._id };

    if (req.query.status) {
      filter.status = req.query.status;
    }

    const [tickets, total] = await Promise.all([
      Ticket.find(filter)
        .populate('lotteryId', 'name drawDate status winningNumbers ticketPrice')
        .sort({ purchasedAt: -1 })
        .skip(skip)
        .limit(limit),
      Ticket.countDocuments(filter)
    ]);

    res.json({
      success: true,
      data: {
        tickets,
        pagination: {
          page,
          limit,
          total,
          pages: Math.ceil(total / limit)
        }
      }
    });
  } catch (error) {
    console.error('Get all my tickets error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

/**
 * @desc    Get completed lotteries with results
 * @route   GET /api/lotteries/results
 * @access  Private
 */
exports.getResults = async (req, res) => {
  try {
    const lotteries = await Lottery.find({ status: 'completed' })
      .sort({ drawDate: -1 })
      .limit(20)
      .lean();

    const results = [];
    for (const lottery of lotteries) {
      const rank1Tickets = await Ticket.find({
        lotteryId: lottery._id,
        status: 'won',
        rank: 1
      }).populate('userId', 'name');

      let rank1WinnerName = 'No Winner';
      if (rank1Tickets.length > 0) {
        rank1WinnerName = rank1Tickets
          .map(t => t.userId ? t.userId.name : 'Unknown User')
          .join(', ');
      }

      results.push({
        ...lottery,
        rank1WinnerName
      });
    }

    res.json({
      success: true,
      data: { lotteries: results }
    });
  } catch (error) {
    console.error('Get results error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

/**
 * @desc    Get all winning and losing participants of a completed lottery
 * @route   GET /api/lotteries/:id/winners-lost
 * @access  Private
 */
exports.getLotteryWinnersAndLost = async (req, res) => {
  try {
    const lottery = await Lottery.findById(req.params.id);
    if (!lottery) {
      return res.status(404).json({ success: false, message: 'Lottery not found' });
    }

    const tickets = await Ticket.find({ lotteryId: req.params.id })
      .populate('userId', 'name phone email')
      .sort({ status: 1 }); // 'won' before 'lost'

    const winners = tickets.filter(t => t.status === 'won');
    const lost = tickets.filter(t => t.status === 'lost');

    res.json({
      success: true,
      data: {
        winningNumbers: lottery.winningNumbers,
        rankWinningNumbers: lottery.rankWinningNumbers || [],
        name: lottery.name,
        drawDate: lottery.drawDate,
        winners: winners.map(w => ({
          id: w._id,
          userName: w.userId ? w.userId.name : 'Unknown User',
          phone: w.userId ? w.userId.phone : '',
          selectedNumbers: w.selectedNumbers,
          matchedNumbers: w.matchedNumbers,
          prizeWon: w.prizeWon,
          status: w.status,
          rank: w.rank || 0
        })),
        lost: lost.map(l => ({
          id: l._id,
          userName: l.userId ? l.userId.name : 'Unknown User',
          phone: l.userId ? l.userId.phone : '',
          selectedNumbers: l.selectedNumbers,
          matchedNumbers: l.matchedNumbers,
          prizeWon: l.prizeWon,
          status: l.status,
          rank: l.rank || 0
        }))
      }
    });
  } catch (error) {
    console.error('Get lottery winners and lost users error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

/**
 * @desc    Get all recent winning tickets across all lotteries
 * @route   GET /api/lotteries/recent-winners
 * @access  Private
 */
exports.getRecentWinners = async (req, res) => {
  try {
    const sevenDaysAgo = new Date();
    sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);

    const winningTickets = await Ticket.find({
      status: 'won',
      updatedAt: { $gte: sevenDaysAgo }
    })
      .populate('userId', 'name')
      .populate('lotteryId', 'name drawDate')
      .sort({ updatedAt: -1 })
      .limit(100);

    const winners = winningTickets.map(t => ({
      ticketId: t._id,
      userName: t.userId ? t.userId.name : 'Unknown User',
      lotteryName: t.lotteryId ? t.lotteryId.name : 'Completed Lottery',
      drawDate: t.lotteryId ? t.lotteryId.drawDate : t.updatedAt,
      prizeWon: t.prizeWon,
      selectedNumbers: t.selectedNumbers,
      matchedNumbers: t.matchedNumbers,
      rank: t.rank || 0,
    }));

    res.json({
      success: true,
      data: { winners }
    });
  } catch (error) {
    console.error('Get recent winners error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

