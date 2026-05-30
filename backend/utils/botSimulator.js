const cron = require('node-cron');
const User = require('../models/User');
const Lottery = require('../models/Lottery');
const Ticket = require('../models/Ticket');
const Transaction = require('../models/Transaction');
const { generateWinningNumbers } = require('./drawEngine');

// 50 realistic Indian names for bot player accounts
const BOT_NAMES = [
  'Rahul Sharma', 'Amit Patel', 'Priya Singh', 'Sandeep Kumar', 'Neha Gupta',
  'Vijay Yadav', 'Rajesh Mishra', 'Sunita Rao', 'Anil Mehta', 'Deepak Verma',
  'Sanjay Dutt', 'Ritu Sharma', 'Vikram Singh', 'Karan Johar', 'Arjun Kapoor',
  'Aditya Roy', 'Nisha Joshi', 'Manish Pandey', 'Siddharth Malhotra', 'Shruti Hassan',
  'Rohit Shetty', 'Pooja Hegde', 'Varun Dhawan', 'Kriti Sanon', 'Ranveer Singh',
  'Deepika Padukone', 'Ranbir Kapoor', 'Alia Bhatt', 'Ajay Devgn', 'Kajol Mukherjee',
  'Akshay Kumar', 'Twinkle Khanna', 'Sunil Shetty', 'Raveena Tandon', 'Bobby Deol',
  'Sunny Deol', 'Karishma Kapoor', 'Kareena Kapoor', 'Saif Ali Khan', 'Amrita Singh',
  'Sara Ali Khan', 'Janhvi Kapoor', 'Ishan Khatter', 'Ananya Panday', 'Tiger Shroff',
  'Disha Patani', 'Rajkummar Rao', 'Patralekha Paul', 'Ayushmann Khurrana', 'Tahira Kashyap'
];

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

    console.log('🤖 Seeding bot player accounts...');
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

    for (const lottery of activeLotteries) {
      // Determine how many tickets to buy this minute (simulating a Poisson-like flow)
      // 40% chance of 0 tickets, 30% chance of 1, 20% chance of 2, 10% chance of 3
      const roll = Math.random();
      let ticketsToBuy = 0;
      if (roll > 0.90) ticketsToBuy = 3;
      else if (roll > 0.70) ticketsToBuy = 2;
      else if (roll > 0.40) ticketsToBuy = 1;

      if (ticketsToBuy === 0) continue;

      console.log(`🤖 Simulating ${ticketsToBuy} ticket purchases for lottery: ${lottery.name}`);

      for (let t = 0; t < ticketsToBuy; t++) {
        // Pick a random bot
        const bot = bots[Math.floor(Math.random() * bots.length)];

        // Enforce the 3 tickets per user per lottery constraint for bots too!
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
