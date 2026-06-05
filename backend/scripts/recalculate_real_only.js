const mongoose = require('mongoose');
const dotenv = require('dotenv');
const path = require('path');
const fs = require('fs');

// Load environment variables
dotenv.config({ path: path.join(__dirname, '..', '.env') });

const User = require('../models/User');
const Transaction = require('../models/Transaction');
const Withdrawal = require('../models/Withdrawal');

async function run() {
  try {
    const mongoUri = process.env.MONGODB_URI || process.env.MONGO_URI;
    if (!mongoUri) {
      throw new Error('MONGODB_URI not found in env variables');
    }

    // Parse the log file to get original bot user balances
    const logPath = 'C:/Users/painl/.gemini/antigravity-ide/brain/019ae0bd-a969-48cf-9d3f-c4bbbe1d0c25/.system_generated/tasks/task-226.log';
    if (!fs.existsSync(logPath)) {
      throw new Error(`Log file not found at ${logPath}`);
    }

    console.log('📖 Parsing old log to extract original bot balances...');
    const logContent = fs.readFileSync(logPath, 'utf8');
    const oldBalancesMap = {};
    const blocks = logContent.split('👤 Processing user:');
    
    for (let i = 1; i < blocks.length; i++) {
      const block = blocks[i];
      const firstLine = block.split('\n')[0].trim();
      const idMatch = firstLine.match(/- ID:\s*([a-f0-9]+)/i);
      if (!idMatch) continue;
      const id = idMatch[1];

      const oldBalMatch = block.match(/Old Balances -> Dep:\s*₹([\d\.]+),\s*Win:\s*₹([\d\.]+),\s*Ref:\s*₹([\d\.]+)/i);
      if (!oldBalMatch) continue;
      const dep = parseFloat(oldBalMatch[1]);
      const win = parseFloat(oldBalMatch[2]);
      const ref = parseFloat(oldBalMatch[3]);

      oldBalancesMap[id] = { dep, win, ref };
    }

    console.log(`✅ Parsed original balances for ${Object.keys(oldBalancesMap).length} users.`);

    console.log('🔌 Connecting to MongoDB...');
    await mongoose.connect(mongoUri);
    console.log('🔌 Connected!');

    const users = await User.find({});
    console.log(`🔍 Found ${users.length} users to process.`);

    for (const user of users) {
      const isBot = user.isBot === true;
      
      if (isBot) {
        // Restore bot user balance
        const original = oldBalancesMap[user._id.toString()];
        if (original) {
          const oldWallet = user.walletBalance;
          const oldWinning = user.winningBalance || 0;
          const oldReferral = user.referralBalance || 0;

          if (oldWallet !== original.dep || oldWinning !== original.win || oldReferral !== original.ref) {
            user.walletBalance = original.dep;
            user.winningBalance = original.win;
            user.referralBalance = original.ref;
            await user.save();
            console.log(`🤖 Bot [${user.name}]: Restored balances -> Dep: ₹${original.dep}, Win: ₹${original.win}, Ref: ₹${original.ref}`);
          } else {
            console.log(`🤖 Bot [${user.name}]: Balances already correct -> Dep: ₹${original.dep}, Win: ₹${original.win}`);
          }
        } else {
          console.log(`⚠️ Bot [${user.name}]: No original balances found in log! Leaving unchanged.`);
        }
      } else {
        // Recalculate real user balance
        console.log(`👤 Real User [${user.name}]: Recalculating balances...`);
        let walletBalance = 0;
        let winningBalance = 0;
        let referralBalance = 0;

        // 1. Get all approved transactions (except withdraw, which we handle via Withdrawal collection)
        const transactions = await Transaction.find({
          userId: user._id,
          status: 'approved',
          type: { $ne: 'withdraw' }
        }).sort({ createdAt: 1 });

        for (const tx of transactions) {
          if (tx.type === 'deposit' || tx.type === 'refund') {
            walletBalance += tx.amount;
          } else if (tx.type === 'winnings') {
            winningBalance += tx.amount;
          } else if (tx.type === 'referral') {
            referralBalance += tx.amount;
          } else if (tx.type === 'ticket_purchase') {
            let remaining = tx.amount;
            if (referralBalance >= remaining) {
              referralBalance -= remaining;
            } else {
              remaining -= referralBalance;
              referralBalance = 0;
              walletBalance -= remaining;
            }
          }
        }

        // 2. Get all pending or approved withdrawals
        const withdrawals = await Withdrawal.find({
          userId: user._id,
          status: { $in: ['pending', 'approved'] }
        });

        for (const w of withdrawals) {
          if (w.isWinnings) {
            winningBalance -= w.amount;
          } else {
            walletBalance -= w.amount;
          }
        }

        walletBalance = Math.max(0, Math.round(walletBalance * 100) / 100);
        winningBalance = Math.max(0, Math.round(winningBalance * 100) / 100);
        referralBalance = Math.max(0, Math.round(referralBalance * 100) / 100);

        const oldWallet = user.walletBalance;
        const oldWinning = user.winningBalance || 0;
        const oldReferral = user.referralBalance || 0;

        if (oldWallet !== walletBalance || oldWinning !== winningBalance || oldReferral !== referralBalance) {
          user.walletBalance = walletBalance;
          user.winningBalance = winningBalance;
          user.referralBalance = referralBalance;
          await user.save();
          console.log(`   ✅ Balances updated -> Dep: ₹${walletBalance}, Win: ₹${winningBalance}, Ref: ₹${referralBalance}`);
        } else {
          console.log(`   ℹ️ Balances already correct -> Dep: ₹${walletBalance}, Win: ₹${winningBalance}`);
        }
      }
    }

    console.log('\n🎉 Recalculation & Restoration complete!');
    await mongoose.disconnect();
    console.log('🔌 Disconnected.');
    process.exit(0);
  } catch (error) {
    console.error('❌ Error during recalculation:', error);
    process.exit(1);
  }
}

run();
