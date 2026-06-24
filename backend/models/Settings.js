const mongoose = require('mongoose');

const settingsSchema = new mongoose.Schema({
  key: {
    type: String,
    required: true,
    unique: true,
    default: 'upi_settings'
  },
  upiId: {
    type: String,
    required: true,
    default: 'pay@upi'
  },
  qrCodeUrl: {
    type: String, // Base64 or URL
    required: false,
    default: ''
  },
  appVersion: {
    type: String,
    required: false,
    default: '1.0.0'
  },
  appDownloadUrl: {
    type: String,
    required: false,
    default: 'https://dream-lottery.onrender.com/api/app/download'
  }
}, {
  timestamps: true
});

module.exports = mongoose.model('Settings', settingsSchema);
