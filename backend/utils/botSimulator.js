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
 * Seed support bot accounts if not present
 */
const seedBotPlayers = async () => {
  try {
    const existingBotsCount = await User.countDocuments({ isBot: true });
    if (existingBotsCount >= BOT_NAMES.length) {
      console.log(`🤖 Bot simulation pool verified (${existingBotsCount} bot players ready)`);
      return;
    }

    console.log(`🤖 Seeding bot player accounts (Target: ${BOT_NAMES.length})...`);
    let seededCount = 0;

    for (let i = 0; i < BOT_NAMES.length; i++) {
      const name = BOT_NAMES[i];
      const email = `bot_${name.toLowerCase().replace(/ /g, '_')}@lottery-bot.com`;
      
      const botExists = await User.findOne({ email });
      if (!botExists) {
        // Generate a valid-looking 10-digit Indian mobile number
        const phone = `9${Math.floor(100000000 + Math.random() * 900000000)}`;

        await User.create({
          name,
          email,
          phone,
          password: 'botplayersecretpass123',
          role: 'user',
          isBot: true,
          walletBalance: 1000000,
          isActive: true
        });
        seededCount++;
      }
    }

    console.log(`🤖 Successfully seeded ${seededCount} new bot player accounts!`);
  } catch (error) {
    console.error('❌ Error seeding bot players:', error);
  }
};

/**
 * Execute periodic simulated bot ticket purchases for active lotteries
 * Matches exact 80% bot tickets to 20% real tickets ratio dynamically.
 */
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

    // Create a fast lookup map of bot user IDs
    const botMap = {};
    bots.forEach(b => {
      botMap[b._id.toString()] = true;
    });

    for (const lottery of activeLotteries) {
      // Fetch all tickets for this lottery
      const tickets = await Ticket.find({ lotteryId: lottery._id });
      
      let realTicketsCount = 0;
      let botTicketsCount = 0;
      
      tickets.forEach(t => {
        if (botMap[t.userId.toString()]) {
          botTicketsCount++;
        } else {
          realTicketsCount++;
        }
      });

      // Target bot count to achieve exactly 80% ratio of bot tickets (N_bot = 4 * N_real)
      const targetBotTickets = realTicketsCount * 4;
      let ticketsToBuy = 0;

      if (realTicketsCount > 0) {
        if (botTicketsCount < targetBotTickets) {
          // Catch up to maintain the 80% bot / 20% real user ticket ratio
          ticketsToBuy = Math.min(15, targetBotTickets - botTicketsCount);
        }
      } else {
        // Baseline organic growth: keep listing active (up to 12 baseline tickets)
        if (botTicketsCount < 12 && Math.random() < 0.25) {
          ticketsToBuy = 1;
        }
      }

      if (ticketsToBuy === 0) continue;

      console.log(`🤖 Bot Simulator: Lottery [${lottery.name}] currently has ${realTicketsCount} real, ${botTicketsCount} bot tickets. Buying ${ticketsToBuy} bot tickets to target ${targetBotTickets} (80% bot ratio).`);

      for (let t = 0; t < ticketsToBuy; t++) {
        // Pick a random bot
        const bot = bots[Math.floor(Math.random() * bots.length)];

        // Enforce the 3 tickets per user per lottery constraint for bots too
        const existingCount = await Ticket.countDocuments({ userId: bot._id, lotteryId: lottery._id });
        if (existingCount >= 3) continue;

        // Generate random unique combinations
        const selectedNumbers = generateWinningNumbers(lottery.pickCount, lottery.maxNumber);

        // Deduct ticket price from bot's virtual balance
        if (bot.walletBalance >= lottery.ticketPrice) {
          bot.walletBalance -= lottery.ticketPrice;
          await bot.save();
        }

        // Create the ticket
        const ticket = await Ticket.create({
          userId: bot._id,
          lotteryId: lottery._id,
          selectedNumbers,
          status: 'active'
        });

        // Create a transaction record
        await Transaction.create({
          userId: bot._id,
          type: 'ticket_purchase',
          amount: lottery.ticketPrice,
          status: 'approved',
          description: `Ticket for ${lottery.name} - Numbers: ${ticket.selectedNumbers.join(', ')}`
        });

        // Update lottery sold statistics
        lottery.totalTicketsSold += 1;
        lottery.totalRevenue += lottery.ticketPrice;
        if (lottery.status === 'upcoming') {
          lottery.status = 'active';
        }
        await lottery.save();

        console.log(`   🎫 Bot [${bot.name}] purchased ticket: [${selectedNumbers.join(', ')}]`);
      }
    }
  } catch (error) {
    console.error('❌ Bot simulator tick error:', error);
  }
};

/**
 * Start bot simulation loop
 */
const startBotSimulator = async () => {
  // 1. Seed bots on startup
  await seedBotPlayers();

  // 2. Schedule cron loop to run every minute
  cron.schedule('* * * * *', async () => {
    await runSimulationTick();
  });

  console.log('🤖 Fictional Bot Player Simulator active (running every minute)');
};

module.exports = { startBotSimulator };
