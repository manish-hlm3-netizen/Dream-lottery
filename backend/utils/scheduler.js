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

    // Generate winning numbers
    const winningNumbers = generateWinningNumbers(lottery.pickCount, lottery.maxNumber);
    console.log(`🎲 Winning numbers: ${winningNumbers.join(', ')}`);

    // Update lottery
    lottery.winningNumbers = winningNumbers;
    lottery.status = 'completed';

    // Get all tickets
    const tickets = await Ticket.find({ lotteryId: lottery._id });
    let totalPrizesPaid = 0;
    let winnersCount = 0;

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
        // Credit winnings
        await User.findByIdAndUpdate(ticket.userId, {
          $inc: { walletBalance: prizeWon }
        });

        // Create transaction
        await Transaction.create({
          userId: ticket.userId,
          type: 'winnings',
          amount: prizeWon,
          status: 'approved',
          description: `Won ₹${prizeWon} in ${lottery.name} (matched ${matchCount})`
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
