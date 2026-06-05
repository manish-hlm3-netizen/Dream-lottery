const mongoose = require('mongoose');
const dotenv = require('dotenv');
const path = require('path');

dotenv.config({ path: path.join(__dirname, '..', '.env') });

const User = require('../models/User');
const Ticket = require('../models/Ticket');
const Transaction = require('../models/Transaction');

async function run() {
  try {
    await mongoose.connect(process.env.MONGODB_URI || process.env.MONGO_URI);
    const users = await User.find({});
    
    console.log('--- Winnings & Balances Check ---');
    for (const u of users) {
      const ticketsSum = await Ticket.aggregate([
        { $match: { userId: u._id, status: 'won' } },
        { $group: { _id: null, total: { $sum: '$prizeWon' } } }
      ]);
      const txsSum = await Transaction.aggregate([
        { $match: { userId: u._id, type: 'winnings', status: 'approved' } },
        { $group: { _id: null, total: { $sum: '$amount' } } }
      ]);
      
      const tTotal = ticketsSum[0]?.total || 0;
      const txTotal = txsSum[0]?.total || 0;
      
      if (tTotal !== txTotal || u.winningBalance !== tTotal || u.walletBalance === 0) {
        console.log(`User: ${u.name} (${u.isBot ? 'Bot' : 'Real'})
   - Ticket Winnings: ₹${tTotal}
   - Tx Winnings:     ₹${txTotal}
   - Current WinBal:  ₹${u.winningBalance}
   - Current Wallet:  ₹${u.walletBalance}
   - Referral Bal:    ₹${u.referralBalance || 0}
`);
      }
    }
    await mongoose.disconnect();
  } catch (err) {
    console.error(err);
  }
}

run();
