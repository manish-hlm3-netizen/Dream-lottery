const express = require('express');
const router = express.Router();
const chatController = require('../controllers/chatController');
const auth = require('../middleware/auth');

// All chat routes require user authentication
router.use(auth);

router.get('/', chatController.getMessages);
router.post('/', chatController.sendMessage);

module.exports = router;
