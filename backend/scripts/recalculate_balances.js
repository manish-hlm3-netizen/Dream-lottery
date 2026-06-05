const mongoose = require('mongoose');
const dotenv = require('dotenv');
const path = require('path');

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

    console.log('🔌 Connecting to MongoDB...');
    await mongoose.connect(mongoUri);
    console.log('🔌 Connected!');

    const users = await User.find({});
    console.log(`🔍 Found ${users.length} users to process.`);

    for (const user of users) {
      console.log(`\n👤 Processing user: ${user.name} (${user.email || user.phone}) - ID: ${user._id}`);
      
      let walletBalance = 0;
      let winningBalance = 0;
      let referralBalance = 0;

      // 1. Get all approved transactions (except withdraw, which we handle via Withdrawal collection)
      const transactions = await Transaction.find({
        userId: user._id,
        status: 'approved',
        type: { $ne: 'withdraw' }
      }).sort({ createdAt: 1 });

      console.log(`   Fetched ${transactions.length} approved non-withdrawal transactions.`);

      for (const tx of transactions) {
        if (tx.type === 'deposit' || tx.type === 'refund') {
          walletBalance += tx.amount;
        } else if (tx.type === 'winnings') {
          winningBalance += tx.amount;
        } else if (tx.type === 'referral') {
          referralBalance += tx.amount;
        } else if (tx.type === 'ticket_purchase') {
          let remaining = tx.amount;
          // 1. Referral balance first
          if (referralBalance >= remaining) {
            referralBalance -= remaining;
            remaining = 0;
          } else {
            remaining -= referralBalance;
            referralBalance = 0;
          }
          // 2. Winning balance second
          if (remaining > 0) {
            if (winningBalance >= remaining) {
              winningBalance -= remaining;
              remaining = 0;
            } else {
              remaining -= winningBalance;
              winningBalance = 0;
            }
          }
          // 3. Deposit balance (walletBalance) third
          if (remaining > 0) {
            walletBalance -= remaining;
          }
        }
      }

      // 2. Get all pending or approved withdrawals
      const withdrawals = await Withdrawal.find({
        userId: user._id,
        status: { $in: ['pending', 'approved'] }
      });

      console.log(`   Fetched ${withdrawals.length} pending/approved withdrawals.`);

      for (const w of withdrawals) {
        if (w.isWinnings) {
          winningBalance -= w.amount; // gross amount is deducted from winningBalance
        } else {
          walletBalance -= w.amount;
        }
      }

      // Ensure balances don't fall below zero due to rounding/adjustments
      walletBalance = Math.max(0, Math.round(walletBalance * 100) / 100);
      winningBalance = Math.max(0, Math.round(winningBalance * 100) / 100);
      referralBalance = Math.max(0, Math.round(referralBalance * 100) / 100);

      const oldWallet = user.walletBalance;
      const oldWinning = user.winningBalance || 0;
      const oldReferral = user.referralBalance || 0;

      console.log(`   Old Balances -> Dep: ₹${oldWallet}, Win: ₹${oldWinning}, Ref: ₹${oldReferral}`);
      console.log(`   New Balances -> Dep: ₹${walletBalance}, Win: ₹${winningBalance}, Ref: ₹${referralBalance}`);

      if (oldWallet !== walletBalance || oldWinning !== winningBalance || oldReferral !== referralBalance) {
        user.walletBalance = walletBalance;
        user.winningBalance = winningBalance;
        user.referralBalance = referralBalance;
        await user.save();
        console.log(`   ✅ Balances updated!`);
      } else {
        console.log(`   ℹ️ Balances already correct.`);
      }
    }

    console.log('\n🎉 Recalculation complete!');
    await mongoose.disconnect();
    console.log('🔌 Disconnected.');
    process.exit(0);
  } catch (error) {
    console.error('❌ Error during recalculation:', error);
    process.exit(1);
  }
}

run();
