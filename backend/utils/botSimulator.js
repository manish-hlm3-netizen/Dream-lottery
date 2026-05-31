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
        // Baseline organic growth: keep listing active (up to 25 baseline tickets, 40% probability per tick)
        if (botTicketsCount < 25 && Math.random() < 0.40) {
          ticketsToBuy = Math.floor(1 + Math.random() * 3); // Buy 1 to 3 tickets randomly
        }
      }

      if (ticketsToBuy === 0) continue;

      console.log(`🤖 Bot Simulator: Lottery [${lottery.name}] currently has ${realTicketsCount} real, ${botTicketsCount} bot tickets. Buying ${ticketsToBuy} bot tickets to target ${targetBotTickets} (80% bot ratio).`);

      let purchased = 0;
      let attempts = 0;
      const maxAttempts = ticketsToBuy * 5; // Prevent lockups if bots are saturated

      while (purchased < ticketsToBuy && attempts < maxAttempts) {
        attempts++;
        
        // Pick a random bot
        const bot = bots[Math.floor(Math.random() * bots.length)];

        // Enforce the 3 tickets per user per lottery constraint for bots too
        const existingCount = await Ticket.countDocuments({ userId: bot._id, lotteryId: lottery._id });
        if (existingCount >= 3) continue;

        // Generate random unique combinations
        const selectedNumbers = generateWinningNumbers(lottery.pickCount, lottery.maxNumber);

        // Deduct ticket price from bot's virtual balance directly via atomic $inc
        // This is extremely fast and avoids slow mongoose pre-save validations and bcrypt triggers
        await User.updateOne(
          { _id: bot._id },
          { $inc: { walletBalance: -lottery.ticketPrice } }
        );

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

        // Update lottery sold statistics directly
        await Lottery.updateOne(
          { _id: lottery._id },
          {
            $inc: { totalTicketsSold: 1, totalRevenue: lottery.ticketPrice },
            $set: { status: 'active' }
          }
        );

        purchased++;
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
  // Run seeding asynchronously so it does NOT block the main Express server startup binding!
  // This allows the server to immediately report as healthy to Render/AWS.
  seedBotPlayers().then(() => {
    // Schedule cron loop to run every minute
    cron.schedule('* * * * *', async () => {
      await runSimulationTick();
    });
    console.log('🤖 Fictional Bot Player Simulator active (running every minute)');
  }).catch(err => {
    console.error('❌ Failed to initialize bot simulation pool:', err);
  });
};

module.exports = { startBotSimulator };
