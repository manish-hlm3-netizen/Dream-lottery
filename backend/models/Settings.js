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
  }
}, {
  timestamps: true
});

module.exports = mongoose.model('Settings', settingsSchema);
