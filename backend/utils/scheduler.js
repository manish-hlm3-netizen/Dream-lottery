const cron = require('node-cron');
const Lottery = require('../models/Lottery');
const Ticket = require('../models/Ticket');
const User = require('../models/User');
const Transaction = require('../models/Transaction');
const { generateWinningNumbers, calculateMatches, determinePrize } = require('./drawEngine');

/**
 * Process automatic lottery draw
 */
const processAutomaticDraw = async (lottery) => {
  try {
    console.log(`🎰 Processing automatic draw for: ${lottery.name}`);

    // Get all tickets
    const tickets = await Ticket.find({ lotteryId: lottery._id });

    // Shuffle tickets randomly for raffle
    const shuffledTickets = [...tickets];
    for (let i = shuffledTickets.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [shuffledTickets[i], shuffledTickets[j]] = [shuffledTickets[j], shuffledTickets[i]];
    }

    // Determine winning numbers
    let winningNumbers;
    if (shuffledTickets.length > 0) {
      winningNumbers = shuffledTickets[0].selectedNumbers;
    } else {
      winningNumbers = generateWinningNumbers(lottery.pickCount, lottery.maxNumber);
    }
    console.log(`🎲 Winning numbers: ${winningNumbers.join(', ')}`);

    // Update lottery
    lottery.winningNumbers = winningNumbers;
    lottery.status = 'completed';

    let totalPrizesPaid = 0;
    let winnersCount = 0;

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
      const shuffledIndex = shuffledTickets.findIndex(t => t._id.toString() === ticket._id.toString());
      
      let rank = 0;
      if (shuffledIndex >= 0 && shuffledIndex < 10) {
        rank = shuffledIndex + 1;
      } else {
        // Check if it shares identical selected numbers with any of the primary winners
        const ticketNumsStr = ticket.selectedNumbers.join(',');
        for (let idx = 0; idx < Math.min(10, shuffledTickets.length); idx++) {
          if (shuffledTickets[idx].selectedNumbers.join(',') === ticketNumsStr) {
            rank = idx + 1;
            break;
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
      await ticket.save();

      if (prizeWon > 0) {
        // Credit winnings
        await User.findByIdAndUpdate(ticket.userId, {
          $inc: { walletBalance: prizeWon }
        });

        // Create transaction
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
        winnersCount++;
      }
    }

    lottery.totalPrizesPaid = totalPrizesPaid;
    await lottery.save();

    console.log(`✅ Draw complete: ${tickets.length} tickets, ${winnersCount} winners, ₹${totalPrizesPaid} paid`);
  } catch (error) {
    console.error(`❌ Error processing draw for ${lottery.name}:`, error);
  }
};

/**
 * Start the scheduler - runs every minute to check for lotteries due for draw
 */
const startScheduler = () => {
  // Run every minute
  cron.schedule('* * * * *', async () => {
    try {
      const now = new Date();

      // Find lotteries that are past their draw date and set to automatic
      const dueDraws = await Lottery.find({
        status: { $in: ['upcoming', 'active'] },
        isAutomatic: true,
        drawDate: { $lte: now }
      });

      for (const lottery of dueDraws) {
        await processAutomaticDraw(lottery);
      }
    } catch (error) {
      console.error('Scheduler error:', error);
    }
  });

  console.log('⏰ Lottery draw scheduler started (checking every minute)');
};

module.exports = { startScheduler };
