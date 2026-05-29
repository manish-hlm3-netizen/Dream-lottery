const express = require('express');
const { body } = require('express-validator');
const router = express.Router();
const lotteryController = require('../controllers/lotteryController');
const auth = require('../middleware/auth');

// All lottery routes require authentication
router.use(auth);

// @route   GET /api/lotteries/results
// Note: This must come before /:id to avoid 'results' being treated as an ID
router.get('/results', lotteryController.getResults);

// @route   GET /api/lotteries/recent-winners
router.get('/recent-winners', lotteryController.getRecentWinners);

// @route   GET /api/lotteries
router.get('/', lotteryController.getLotteries);

// @route   GET /api/lotteries/:id
router.get('/:id', lotteryController.getLotteryById);

// @route   POST /api/lotteries/:id/buy
router.post('/:id/buy', [
  body('selectedNumbers')
    .isArray({ min: 1 }).withMessage('Selected numbers are required')
], lotteryController.buyTicket);

// @route   GET /api/lotteries/:id/my-tickets
router.get('/:id/my-tickets', lotteryController.getMyTickets);

// @route   GET /api/lotteries/:id/winners-lost
router.get('/:id/winners-lost', lotteryController.getLotteryWinnersAndLost);

// @route   GET /api/tickets/my-tickets (all tickets across lotteries)
// Mounted separately in server.js as /api/tickets/my-tickets

module.exports = router;
