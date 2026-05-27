const express = require('express');
const { body } = require('express-validator');
const router = express.Router();
const walletController = require('../controllers/walletController');
const auth = require('../middleware/auth');

// All wallet routes require authentication
router.use(auth);

// @route   GET /api/wallet/balance
router.get('/balance', walletController.getBalance);

// @route   POST /api/wallet/deposit
router.post('/deposit', [
  body('amount')
    .isFloat({ min: 10 }).withMessage('Minimum deposit is ₹10'),
  body('upiTransactionId')
    .trim()
    .notEmpty().withMessage('UPI transaction ID is required')
    .isLength({ min: 5 }).withMessage('Invalid UPI transaction ID')
], walletController.deposit);

// @route   POST /api/wallet/withdraw
router.post('/withdraw', [
  body('amount')
    .isFloat({ min: 10 }).withMessage('Minimum withdrawal is ₹10'),
  body('upiId')
    .trim()
    .notEmpty().withMessage('UPI ID is required')
], walletController.withdraw);

// @route   GET /api/wallet/transactions
router.get('/transactions', walletController.getTransactions);

// @route   GET /api/wallet/withdrawals
router.get('/withdrawals', walletController.getWithdrawals);

module.exports = router;
