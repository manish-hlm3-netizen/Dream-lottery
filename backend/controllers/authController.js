const jwt = require('jsonwebtoken');
const { validationResult } = require('express-validator');
const User = require('../models/User');
const Announcement = require('../models/Announcement');
const Settings = require('../models/Settings');
const Transaction = require('../models/Transaction');


// Generate JWT token
const generateToken = (userId) => {
  return jwt.sign({ id: userId }, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRE || '7d'
  });
};

/**
 * @desc    Register a new user
 * @route   POST /api/auth/register
 * @access  Public
 */
exports.register = async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Validation failed',
        errors: errors.array()
      });
    }

    const { name, email, phone, password, referralCode } = req.body;

    // Check if user already exists
    const existingUser = await User.findOne({
      $or: [{ email }, { phone }]
    });

    if (existingUser) {
      const field = existingUser.email === email ? 'email' : 'phone';
      return res.status(400).json({
        success: false,
        message: `User with this ${field} already exists`
      });
    }

    // Resolve referredBy using referralCode
    let referredBy = null;
    let referrer = null;
    if (referralCode) {
      referrer = await User.findOne({ referralCode: referralCode.toUpperCase().trim() });
      if (referrer) {
        referredBy = referrer._id;
      }
    }

    // Create user
    const user = await User.create({
      name,
      email,
      phone,
      password,
      referredBy,
      walletBalance: 0,
      referralBalance: referredBy ? 20 : 0
    });

    // Reward referrer if found
    if (referrer) {
      referrer.referralBalance += 50;
      referrer.referralEarnings += 50;
      referrer.referredUsersCount += 1;
      await referrer.save();

      // Create referrer transaction
      await Transaction.create({
        userId: referrer._id,
        type: 'referral',
        amount: 50,
        status: 'approved',
        description: `Referral Bonus for inviting ${user.name}`
      });

      // Create referred user transaction
      await Transaction.create({
        userId: user._id,
        type: 'referral',
        amount: 20,
        status: 'approved',
        description: `Signup Referral Bonus (Referred by ${referrer.name})`
      });
    }

    // Generate token
    const token = generateToken(user._id);

    res.status(201).json({
      success: true,
      message: 'Registration successful',
      data: {
        token,
        user: {
          id: user._id,
          uid: user.uid,
          name: user.name,
          email: user.email,
          phone: user.phone,
          role: user.role,
          walletBalance: user.walletBalance,
          referralBalance: user.referralBalance || 0,
          winningBalance: user.winningBalance || 0,
          referralCode: user.referralCode
        }
      }
    });
  } catch (error) {
    console.error('Register error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error during registration'
    });
  }
};

/**
 * @desc    Login user
 * @route   POST /api/auth/login
 * @access  Public
 */
exports.login = async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Validation failed',
        errors: errors.array()
      });
    }

    const { email, password } = req.body;
    const loginId = email.toLowerCase().trim();

    // Find user with password matching email OR phone
    const user = await User.findOne({
      $or: [
        { email: loginId },
        { phone: loginId }
      ]
    }).select('+password');
    if (!user) {
      return res.status(401).json({
        success: false,
        message: 'Invalid email or password'
      });
    }

    if (!user.isActive) {
      return res.status(403).json({
        success: false,
        message: 'Account has been deactivated. Contact admin.'
      });
    }

    // Check password
    const isMatch = await user.comparePassword(password);
    if (!isMatch) {
      return res.status(401).json({
        success: false,
        message: 'Invalid email or password'
      });
    }

    // Generate token
    const token = generateToken(user._id);

    res.json({
      success: true,
      message: 'Login successful',
      data: {
        token,
        user: {
          id: user._id,
          uid: user.uid,
          name: user.name,
          email: user.email,
          phone: user.phone,
          role: user.role,
          walletBalance: user.walletBalance,
          referralBalance: user.referralBalance || 0,
          winningBalance: user.winningBalance || 0
        }
      }
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error during login'
    });
  }
};

/**
 * @desc    Get current user profile
 * @route   GET /api/auth/me
 * @access  Private
 */
exports.getMe = async (req, res) => {
  try {
    const user = await User.findById(req.user._id);
    res.json({
      success: true,
      data: {
        id: user._id,
        uid: user.uid,
        name: user.name,
        email: user.email,
        phone: user.phone,
        role: user.role,
        walletBalance: user.walletBalance,
        referralBalance: user.referralBalance || 0,
        winningBalance: user.winningBalance || 0,
        createdAt: user.createdAt
      }
    });
  } catch (error) {
    console.error('GetMe error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
};

/**
 * @desc    Update user profile
 * @route   PUT /api/auth/profile
 * @access  Private
 */
exports.updateProfile = async (req, res) => {
  try {
    const { name, phone } = req.body;
    const updateData = {};
    if (name) updateData.name = name;
    if (phone) updateData.phone = phone;

    const user = await User.findByIdAndUpdate(
      req.user._id,
      updateData,
      { new: true, runValidators: true }
    );

    res.json({
      success: true,
      message: 'Profile updated successfully',
      data: {
        id: user._id,
        uid: user.uid,
        name: user.name,
        email: user.email,
        phone: user.phone,
        role: user.role,
        walletBalance: user.walletBalance,
        referralBalance: user.referralBalance || 0,
        winningBalance: user.winningBalance || 0
      }
    });
  } catch (error) {
    console.error('Update profile error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
};

/**
 * @desc    Get active public announcements
 * @route   GET /api/auth/announcements
 * @access  Private
 */
exports.getAnnouncements = async (req, res) => {
  try {
    const announcements = await Announcement.find({ isActive: true }).sort({ createdAt: -1 });
    res.json({
      success: true,
      data: announcements
    });
  } catch (error) {
    console.error('Get announcements error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
};

/**
 * @desc    Get current UPI payment settings for mobile users
 * @route   GET /api/auth/settings/upi
 * @access  Private
 */
exports.getUPISettings = async (req, res) => {
  try {
    let settings = await Settings.findOne({ key: 'upi_settings' });
    if (!settings) {
      settings = await Settings.create({
        key: 'upi_settings',
        upiId: 'pay@upi',
        qrCodeUrl: ''
      });
    }
    res.json({
      success: true,
      data: settings
    });
  } catch (error) {
    console.error('Get mobile UPI settings error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

/**
 * @desc    Get referral stats and referred users list
 * @route   GET /api/auth/referrals
 * @access  Private
 */
exports.getReferralStats = async (req, res) => {
  try {
    const user = await User.findById(req.user.id);
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    const referredFriends = await User.find(
      { referredBy: user._id },
      'name email phone createdAt'
    ).sort({ createdAt: -1 });

    res.json({
      success: true,
      data: {
        referralCode: user.referralCode,
        referralEarnings: user.referralEarnings || 0,
        referredUsersCount: user.referredUsersCount || 0,
        referredFriends
      }
    });
  } catch (error) {
    console.error('Get referral stats error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

/**
 * @desc    Get latest app version and download URL
 * @route   GET /api/auth/app-version
 * @access  Public
 */
exports.getAppVersion = async (req, res) => {
  try {
    const Settings = require('../models/Settings');
    let settings = await Settings.findOne({ key: 'upi_settings' });
    if (!settings) {
      settings = await Settings.create({
        key: 'upi_settings',
        upiId: 'pay@upi',
        qrCodeUrl: '',
        appVersion: '1.0.0',
        appDownloadUrl: 'https://lottery-api-vgk0.onrender.com/api/app/download'
      });
    }

    const baseDownloadUrl = settings.appDownloadUrl || 'https://lottery-api-vgk0.onrender.com/api/app/download';
    const separator = baseDownloadUrl.includes('?') ? '&' : '?';
    const appDownloadUrl = `${baseDownloadUrl}${separator}v=${settings.appVersion || '1.0.0'}`;

    res.json({
      success: true,
      data: {
        appVersion: settings.appVersion || '1.0.0',
        appDownloadUrl: appDownloadUrl
      }
    });
  } catch (error) {
    console.error('Get app version error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error retrieving app version'
    });
  }
};

/**
 * @desc    Change user password
 * @route   PUT /api/auth/change-password
 * @access  Private
 */
exports.changePassword = async (req, res) => {
  try {
    const { oldPassword, newPassword } = req.body;

    if (!oldPassword || !newPassword) {
      return res.status(400).json({
        success: false,
        message: 'Please provide old password and new password'
      });
    }

    if (newPassword.length < 6) {
      return res.status(400).json({
        success: false,
        message: 'New password must be at least 6 characters long'
      });
    }

    // Get user with password selected
    const user = await User.findById(req.user._id).select('+password');

    // Check old password
    const isMatch = await user.comparePassword(oldPassword);
    if (!isMatch) {
      return res.status(400).json({
        success: false,
        message: 'Incorrect old password'
      });
    }

    // Update password
    user.password = newPassword;
    await user.save();

    res.json({
      success: true,
      message: 'Password changed successfully'
    });
  } catch (error) {
    console.error('Change password error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error during password update'
    });
  }
};


