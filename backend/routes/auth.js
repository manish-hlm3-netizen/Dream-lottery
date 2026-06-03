const express = require('express');
const { body } = require('express-validator');
const router = express.Router();
const authController = require('../controllers/authController');
const auth = require('../middleware/auth');

// @route   POST /api/auth/register
router.post('/register', [
  body('name')
    .trim()
    .notEmpty().withMessage('Name is required')
    .isLength({ max: 50 }).withMessage('Name cannot exceed 50 characters'),
  body('email')
    .trim()
    .isEmail().withMessage('Please provide a valid email')
    .normalizeEmail(),
  body('phone')
    .trim()
    .matches(/^[6-9]\d{9}$/).withMessage('Please provide a valid 10-digit Indian phone number'),
  body('password')
    .isLength({ min: 6 }).withMessage('Password must be at least 6 characters')
], authController.register);

// @route   POST /api/auth/login
router.post('/login', [
  body('email')
    .trim()
    .custom((value) => {
      if (!value) {
        throw new Error('Email or Phone number is required');
      }
      const isEmail = /^\S+@\S+\.\S+$/.test(value);
      const isPhone = /^[6-9]\d{9}$/.test(value);
      if (!isEmail && !isPhone) {
        throw new Error('Please provide a valid email or 10-digit Indian phone number');
      }
      return true;
    }),
  body('password')
    .notEmpty().withMessage('Password is required')
], authController.login);

// @route   GET /api/auth/me
router.get('/me', auth, authController.getMe);

// @route   PUT /api/auth/profile
router.put('/profile', auth, authController.updateProfile);

// @route   GET /api/auth/announcements
router.get('/announcements', auth, authController.getAnnouncements);

// @route   GET /api/auth/settings/upi
router.get('/settings/upi', auth, authController.getUPISettings);

// @route   GET /api/auth/referrals
router.get('/referrals', auth, authController.getReferralStats);

// @route   PUT /api/auth/change-password
router.put('/change-password', auth, authController.changePassword);

// @route   GET /api/auth/app-version
router.get('/app-version', authController.getAppVersion);

module.exports = router;

