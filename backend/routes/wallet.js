const express = require('express');
const { body } = require('express-validator');
const router = express.Router();
const walletController = require('../controllers/walletController');
const auth = require('../middleware/auth');

// Public Webhook route (does NOT require authentication)
router.post('/webhook/upi', walletController.handleUPIWebhook);

// All other wallet routes require authentication
router.use(auth);

// @route   POST /api/wallet/deposit/initiate
router.post('/deposit/initiate', [
  body('amount')
    .isFloat({ min: 10 }).withMessage('Minimum deposit is ₹10')
], walletController.initiateDeposit);

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
    .isFloat({ min: 100 }).withMessage('Minimum withdrawal is ₹100'),
  body('method')
    .optional()
    .isIn(['upi', 'bank']).withMessage('Invalid withdrawal method'),
  body('upiId')
    .custom((value, { req }) => {
      const method = req.body.method || 'upi';
      if (method === 'upi' && (!value || !value.trim())) {
        throw new Error('UPI ID is required');
      }
      return true;
    }),
  body('bankName')
    .custom((value, { req }) => {
      const method = req.body.method || 'upi';
      if (method === 'bank' && (!value || !value.trim())) {
        throw new Error('Bank name is required');
      }
      return true;
    }),
  body('accountNumber')
    .custom((value, { req }) => {
      const method = req.body.method || 'upi';
      if (method === 'bank' && (!value || !value.trim())) {
        throw new Error('Account number is required');
      }
      return true;
    }),
  body('ifscCode')
    .custom((value, { req }) => {
      const method = req.body.method || 'upi';
      if (method === 'bank' && (!value || !value.trim())) {
        throw new Error('IFSC code is required');
      }
      return true;
    }),
  body('accountHolderName')
    .custom((value, { req }) => {
      const method = req.body.method || 'upi';
      if (method === 'bank' && (!value || !value.trim())) {
        throw new Error('Account holder name is required');
      }
      return true;
    })
], walletController.withdraw);

// @route   GET /api/wallet/transactions
router.get('/transactions', walletController.getTransactions);

// @route   GET /api/wallet/withdrawals
router.get('/withdrawals', walletController.getWithdrawals);

module.exports = router;
