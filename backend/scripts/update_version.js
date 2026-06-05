require('dotenv').config({ path: require('path').join(__dirname, '..', '.env') });
const mongoose = require('mongoose');
const Settings = require('../models/Settings');

mongoose.connect(process.env.MONGODB_URI || process.env.MONGO_URI)
  .then(async () => {
    const version = process.argv[2] || '1.4.13';
    const s = await Settings.findOneAndUpdate(
      { key: 'upi_settings' },
      { appVersion: version },
      { new: true, upsert: false }
    );
    if (s) {
      console.log('✅ Settings DB updated — appVersion:', s.appVersion);
    } else {
      console.log('⚠️  No Settings doc found with key=upi_settings');
    }
    process.exit(0);
  })
  .catch(e => {
    console.error('❌ DB error:', e.message);
    process.exit(1);
  });
