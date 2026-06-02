const cron = require('node-cron');
const User = require('../models/User');
const Lottery = require('../models/Lottery');
const Ticket = require('../models/Ticket');
const Transaction = require('../models/Transaction');
const { generateWinningNumbers } = require('./drawEngine');

// Pre-defined Indian first and last name lists to programmatically generate 1,000 unique player names
const FIRST_NAMES = [
  'Rahul', 'Amit', 'Priya', 'Sandeep', 'Neha', 'Vijay', 'Rajesh', 'Sunita', 'Anil', 'Deepak',
  'Sanjay', 'Ritu', 'Vikram', 'Karan', 'Arjun', 'Aditya', 'Nisha', 'Manish', 'Siddharth', 'Shruti',
  'Rohit', 'Pooja', 'Varun', 'Kriti', 'Ranveer', 'Deepika', 'Ranbir', 'Alia', 'Ajay', 'Kajol',
  'Akshay', 'Twinkle', 'Sunil', 'Raveena', 'Bobby', 'Sunny', 'Karishma', 'Kareena', 'Saif', 'Amrita',
  'Sara', 'Janhvi', 'Ishan', 'Ananya', 'Tiger', 'Disha', 'Rajkummar', 'Patralekha', 'Ayushmann', 'Tahira',
  'Abhishek', 'Aishwarya', 'Hrithik', 'Sussanne', 'Vivek', 'Suresh', 'Ramesh', 'Ganesh', 'Dinesh', 'Mahesh',
  'Naresh', 'Harish', 'Kamlesh', 'Umesh', 'Rakesh', 'Mukesh', 'Yogesh', 'Jitendra', 'Dharmendra', 'Manoj'
];

const LAST_NAMES = [
  'Sharma', 'Patel', 'Singh', 'Kumar', 'Gupta', 'Yadav', 'Mishra', 'Rao', 'Mehta', 'Verma',
  'Dutt', 'Pandey', 'Malhotra', 'Hassan', 'Shetty', 'Hegde', 'Dhawan', 'Sanon', 'Bakshi', 'Kapoor',
  'Bhatt', 'Devgn', 'Mukherjee', 'Khanna', 'Tandon', 'Deol', 'Khan', 'Shroff', 'Patani', 'Khurrana',
  'Kashyap', 'Chopra', 'Johar', 'Joshi', 'Roy', 'Sen', 'Das', 'Banerjee', 'Chatterjee', 'Dutta',
  'Garg', 'Bansal', 'Goel', 'Jain', 'Agarwal', 'Aggarwal', 'Chawla', 'Sood', 'Gill', 'Sandhu'
];

// Generate exactly 1,000 unique, deterministic combinations
const generate1000BotNames = () => {
  const names = [];
  let count = 0;
  for (let i = 0; i < FIRST_NAMES.length; i++) {
    for (let j = 0; j < LAST_NAMES.length; j++) {
      names.push(`${FIRST_NAMES[i]} ${LAST_NAMES[j]}`);
      count++;
      if (count === 1000) return names;
    }
  }
  return names;
};

const BOT_NAMES = generate1000BotNames();

/**
 * Seed support bot accounts if not present (Lightning-fast Bulk Check & InsertMany)
 */
const seedBotPlayers = async () => {
  try {
    const existingBotsCount = await User.countDocuments({ isBot: true });
    if (existingBotsCount >= BOT_NAMES.length) {
      console.log(`🤖 Bot simulation pool verified (${existingBotsCount} bot players ready)`);
      return;
    }

    console.log(`🤖 Seeding missing bot player accounts in bulk (Target: ${BOT_NAMES.length})...`);
    
    // Fetch all existing bot emails in a single fast query
    const existingBots = await User.find({ isBot: true }, { email: 1 });
    const existingEmailsSet = new Set(existingBots.map(b => b.email.toLowerCase()));

    const newBotsToInsert = [];
    const botPasswordHash = '$2a$12$V.oZ1ZcEpxV31.Qnfe4WlOm1u.j1fFzU1GvQx6H04D6h61wQ/8cGy'; // Hashed password of 'botplayersecretpass123'
    
    const characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

    for (let i = 0; i < BOT_NAMES.length; i++) {
      const name = BOT_NAMES[i];
      const email = `bot_${name.toLowerCase().replace(/ /g, '_')}@lottery-bot.com`;
      
      if (!existingEmailsSet.has(email.toLowerCase())) {
        // Generate a unique 10-digit Indian phone number
        const phone = `9${Math.floor(100000000 + Math.random() * 900000000)}`;

        // Pre-generate unique 8-character referral code to avoid duplicate key errors
        let referralCode = '';
        for (let c = 0; c < 8; c++) {
          referralCode += characters.charAt(Math.floor(Math.random() * characters.length));
        }

        newBotsToInsert.push({
          name,
          email,
          phone,
          password: botPasswordHash, // Store pre-hashed password to avoid 3 minutes of sequential CPU crypting
          plainPassword: 'botplayersecretpass123',
          role: 'user',
          isBot: true,
          walletBalance: 1000000,
          isActive: true,
          referralCode
        });
      }
    }

    if (newBotsToInsert.length > 0) {
      console.log(`🤖 Bulk inserting ${newBotsToInsert.length} bot player profiles...`);
      await User.insertMany(newBotsToInsert);
      console.log(`🤖 Successfully bulk-seeded all missing bot player accounts!`);
    } else {
      console.log(`🤖 Bot simulation pool verified (All bots already seeded)`);
    }
  } catch (error) {
    console.error('❌ Error bulk-seeding bot players:', error);
  }
};

/**
 * Total ticket cap per lottery (shown in UI as 100,000)
 * Bots are capped at 99,500 — reserving 500 slots for real users.
 */
const MAX_TICKETS_PER_LOTTERY = 10000;
const BOT_TICKET_CAP = 9950;  // 9,950 for bots
const REAL_USER_RESERVED = 50; // 50 reserved for real players

const runSimulationTick = async () => {
  try {
    const now = new Date();

    // Find active lotteries that are accepting ticket purchases
    const activeLotteries = await Lottery.find({
      status: { $in: ['upcoming', 'active'] },
      drawDate: { $gt: now }
    });

    if (activeLotteries.length === 0) return;

    // Fetch all seeded bots
    const bots = await User.find({ isBot: true });
    if (bots.length === 0) return;

    const botIds = bots.map(b => b._id);

    for (const lottery of activeLotteries) {
      const [botTicketsCount, realTicketsCount] = await Promise.all([
        Ticket.countDocuments({ lotteryId: lottery._id, userId: { $in: botIds } }),
        Ticket.countDocuments({ lotteryId: lottery._id, userId: { $nin: botIds } })
      ]);

      const totalTicketsSold = realTicketsCount + botTicketsCount;

      // Hard cap: stop if total reached MAX_TICKETS_PER_LOTTERY
      if (totalTicketsSold >= MAX_TICKETS_PER_LOTTERY) {
        console.log(`🤖 Bot Simulator: Lottery [${lottery.name}] reached the ${MAX_TICKETS_PER_LOTTERY} ticket cap. Stopping.`);
        continue;
      }

      // Bot cap: bots cannot exceed BOT_TICKET_CAP tickets
      if (botTicketsCount >= BOT_TICKET_CAP) {
        console.log(`🤖 Bot Simulator: Lottery [${lottery.name}] bot cap (${BOT_TICKET_CAP}) reached. Reserving remaining for real users.`);
        continue;
      }

      let ticketsToBuy = 0;

      if (realTicketsCount > 0) {
        // Maintain ratio: 4 bot tickets per 1 real ticket (80% bots), but speed up catch up and drip
        const targetBotTickets = Math.min(realTicketsCount * 4, BOT_TICKET_CAP);
        if (botTicketsCount < targetBotTickets) {
          // Fast catch-up: max 500 per tick
          ticketsToBuy = Math.min(500, targetBotTickets - botTicketsCount);
        } else {
          // Ratio maintained — fast organic drip to look active
          ticketsToBuy = Math.floor(50 + Math.random() * 50); // 50–100 per tick
        }
      } else {
        // No real users yet — fast baseline growth (100–250 per tick)
        ticketsToBuy = Math.floor(100 + Math.random() * 150);
      }

      // Clamp: don't exceed bot cap or total cap
      const botSlotsLeft = BOT_TICKET_CAP - botTicketsCount;
      const totalSlotsLeft = MAX_TICKETS_PER_LOTTERY - REAL_USER_RESERVED - botTicketsCount;
      ticketsToBuy = Math.min(ticketsToBuy, botSlotsLeft, Math.max(0, totalSlotsLeft));

      if (ticketsToBuy === 0) continue;

      console.log(`🤖 Bot Simulator: [${lottery.name}] real=${realTicketsCount} bot=${botTicketsCount}/${BOT_TICKET_CAP} — buying ${ticketsToBuy} tickets (bulk).`);

      const ticketDocs = [];
      const transactionDocs = [];
      const userUpdates = [];

      for (let i = 0; i < ticketsToBuy; i++) {
        // Pick a random bot
        const bot = bots[Math.floor(Math.random() * bots.length)];
        // Generate random unique combinations
        const selectedNumbers = generateWinningNumbers(lottery.pickCount, lottery.maxNumber);

        ticketDocs.push({
          userId: bot._id,
          lotteryId: lottery._id,
          selectedNumbers,
          status: 'active'
        });

        transactionDocs.push({
          userId: bot._id,
          type: 'ticket_purchase',
          amount: lottery.ticketPrice,
          status: 'approved',
          description: `Ticket for ${lottery.name} - Numbers: ${selectedNumbers.join(', ')}`
        });

        userUpdates.push({
          updateOne: {
            filter: { _id: bot._id },
            update: { $inc: { walletBalance: -lottery.ticketPrice } }
          }
        });
      }

      try {
        // 1. Bulk insert and bulk update balances in parallel
        await Promise.all([
          Ticket.insertMany(ticketDocs),
          Transaction.insertMany(transactionDocs),
          User.bulkWrite(userUpdates)
        ]);

        // 2. Update lottery sold statistics in a single query
        await Lottery.updateOne(
          { _id: lottery._id },
          {
            $inc: { totalTicketsSold: ticketsToBuy, totalRevenue: ticketsToBuy * lottery.ticketPrice },
            $set: { status: 'active' }
          }
        );

        console.log(`   ✅ Successfully processed ${ticketsToBuy} bot ticket purchases in bulk.`);
      } catch (bulkError) {
        console.error(`❌ Bot Simulator: Bulk purchase failed for [${lottery.name}]:`, bulkError);
      }
    }
  } catch (error) {
    console.error('❌ Bot simulator tick error:', error);
  }
};

/**
 * Clean up bot tickets and transactions older than 3 days to protect database storage
 */
const runBotCleanup = async () => {
  try {
    console.log('🧹 Bot Simulator: Running cleanup of bot tickets and transactions older than 3 days...');
    const threeDaysAgo = new Date();
    threeDaysAgo.setDate(threeDaysAgo.getDate() - 3);

    const bots = await User.find({ isBot: true }, { _id: 1 });
    const botIds = bots.map(b => b._id);

    if (botIds.length > 0) {
      // Find completed lotteries older than 3 days
      const completedLotteries = await Lottery.find({ status: 'completed', drawDate: { $lte: threeDaysAgo } }, { _id: 1 });
      const completedLotteryIds = completedLotteries.map(l => l._id);

      let ticketsDeleted = 0;
      if (completedLotteryIds.length > 0) {
        const ticketDelResult = await Ticket.deleteMany({
          lotteryId: { $in: completedLotteryIds },
          userId: { $in: botIds }
        });
        ticketsDeleted = ticketDelResult.deletedCount;
      }

      const transDelResult = await Transaction.deleteMany({
        userId: { $in: botIds },
        createdAt: { $lte: threeDaysAgo }
      });

      console.log(`   ✅ Cleaned up ${ticketsDeleted} old bot tickets and ${transDelResult.deletedCount} old bot transactions.`);
    }
  } catch (cleanupError) {
    console.error('❌ Bot Simulator: Cleanup task error:', cleanupError);
  }
};

/**
 * Start bot simulation loop
 */
const startBotSimulator = async () => {
  // Run seeding asynchronously so it does NOT block the main Express server startup binding!
  // This allows the server to immediately report as healthy to Render/AWS.
  seedBotPlayers().then(async () => {
    // Run cleanup on startup
    await runBotCleanup();

    // Run immediately on startup
    runSimulationTick();
    
    // Set up periodic task execution every 5 seconds for fast bulk ticket buying
    setInterval(async () => {
      await runSimulationTick();
    }, 5000);

    // Run daily cleanup at midnight
    cron.schedule('0 0 * * *', async () => {
      await runBotCleanup();
    });

    console.log('🤖 Fictional Bot Player Simulator active (running every 5 seconds — fast bulk pace)');
  }).catch(err => {
    console.error('❌ Failed to initialize bot simulation pool:', err);
  });
};

module.exports = { startBotSimulator };
