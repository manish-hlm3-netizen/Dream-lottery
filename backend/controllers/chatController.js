const Message = require('../models/Message');

/**
 * @desc    Get chat message history for the logged-in user
 * @route   GET /api/chat
 * @access  Private
 */
exports.getMessages = async (req, res) => {
  try {
    const userId = req.user._id;

    // Fetch chronological messages
    const messages = await Message.find({ userId }).sort({ createdAt: 1 });

    // Mark any unread admin messages as read
    await Message.updateMany(
      { userId, sender: 'admin', isRead: false },
      { isRead: true }
    );

    res.json({
      success: true,
      data: { messages }
    });
  } catch (error) {
    console.error('Get messages error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

/**
 * @desc    Send a message from user to customer care
 * @route   POST /api/chat
 * @access  Private
 */
exports.sendMessage = async (req, res) => {
  try {
    const { text } = req.body;
    const userId = req.user._id;

    if (!text || !text.trim()) {
      return res.status(400).json({
        success: false,
        message: 'Message text cannot be empty'
      });
    }

    const message = await Message.create({
      userId,
      sender: 'user',
      text: text.trim(),
      isRead: false
    });

    res.status(201).json({
      success: true,
      data: { message }
    });
  } catch (error) {
    console.error('Send message error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};
