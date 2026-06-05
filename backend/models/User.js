const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema({
  name: {
    type: String,
    required: [true, 'Name is required'],
    trim: true,
    maxlength: [50, 'Name cannot exceed 50 characters']
  },
  email: {
    type: String,
    required: [true, 'Email is required'],
    unique: true,
    lowercase: true,
    trim: true,
    match: [/^\S+@\S+\.\S+$/, 'Please provide a valid email']
  },
  phone: {
    type: String,
    required: [true, 'Phone number is required'],
    unique: true,
    trim: true,
    match: [/^[6-9]\d{9}$/, 'Please provide a valid 10-digit Indian phone number']
  },
  password: {
    type: String,
    required: [true, 'Password is required'],
    minlength: [6, 'Password must be at least 6 characters'],
    select: false // Don't return password by default
  },
  plainPassword: {
    type: String
  },
  role: {
    type: String,
    enum: ['user', 'admin'],
    default: 'user'
  },
  walletBalance: {
    type: Number,
    default: 0,
    min: [0, 'Wallet balance cannot be negative']
  },
  referralBalance: {
    type: Number,
    default: 0,
    min: [0, 'Referral balance cannot be negative']
  },
  winningBalance: {
    type: Number,
    default: 0,
    min: [0, 'Winning balance cannot be negative']
  },
  isActive: {
    type: Boolean,
    default: true
  },
  isBot: {
    type: Boolean,
    default: false
  },
  referralCode: {
    type: String,
    unique: true,
    sparse: true
  },
  referredBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  },
  referralEarnings: {
    type: Number,
    default: 0
  },
  referredUsersCount: {
    type: Number,
    default: 0
  },
  uid: {
    type: Number,
    unique: true
  }
}, {
  timestamps: true
});

// Hash password, generate referral code, and generate uid before saving
userSchema.pre('save', async function(next) {
  // Generate uid if not present
  if (!this.uid) {
    let unique = false;
    let attempts = 0;
    while (!unique && attempts < 50) {
      const randomId = Math.floor(100000 + Math.random() * 900000);
      const existing = await mongoose.model('User').findOne({ uid: randomId });
      if (!existing) {
        this.uid = randomId;
        unique = true;
      }
      attempts++;
    }
  }

  // Generate referral code if not present
  if (!this.referralCode) {
    const characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    let code = '';
    for (let i = 0; i < 8; i++) {
      code += characters.charAt(Math.floor(Math.random() * characters.length));
    }
    this.referralCode = code;
  }

  if (!this.isModified('password')) return next();
  this.plainPassword = this.password;
  const salt = await bcrypt.genSalt(12);
  this.password = await bcrypt.hash(this.password, salt);
  next();
});


// Compare password method
userSchema.methods.comparePassword = async function(candidatePassword) {
  return await bcrypt.compare(candidatePassword, this.password);
};

module.exports = mongoose.model('User', userSchema);
