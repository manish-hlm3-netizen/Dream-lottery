const express = require('express');
const router = express.Router();
const adminController = require('../controllers/adminController');
const auth = require('../middleware/auth');
const adminAuth = require('../middleware/adminAuth');

// All admin routes require auth + admin role
router.use(auth, adminAuth);

// Dashboard
router.get('/dashboard', adminController.getDashboard);

// Users
router.get('/users', adminController.getUsers);
router.put('/users/:id/toggle', adminController.toggleUserStatus);
router.put('/users/:id/wallet', adminController.updateUserWallet);
router.put('/users/:id/password', adminController.changeUserPassword);

// Deposits
router.get('/deposits', adminController.getDeposits);
router.put('/deposits/:id', adminController.processDeposit);

// Withdrawals
router.get('/withdrawals', adminController.getWithdrawals);
router.put('/withdrawals/:id', adminController.processWithdrawal);

// Lotteries
router.get('/lotteries', adminController.getAllLotteries);
router.get('/lotteries/:id', adminController.getLotteryDetail);
router.post('/lotteries', adminController.createLottery);
router.put('/lotteries/:id', adminController.updateLottery);
router.post('/lotteries/:id/draw', adminController.drawLottery);

// Announcements
router.get('/announcements', adminController.getAdminAnnouncements);
router.post('/announcements', adminController.createAnnouncement);
router.delete('/announcements/:id', adminController.deleteAnnouncement);

module.exports = router;

