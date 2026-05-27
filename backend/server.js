const express = require('express');
const cors = require('cors');
const rateLimit = require('express-rate-limit');
require('dotenv').config();

const connectDB = require('./config/db');
const { startScheduler } = require('./utils/scheduler');

// Import routes
const authRoutes = require('./routes/auth');
const walletRoutes = require('./routes/wallet');
const lotteryRoutes = require('./routes/lottery');
const adminRoutes = require('./routes/admin');

// Import for ticket route
const auth = require('./middleware/auth');
const lotteryController = require('./controllers/lotteryController');

const app = express();

// ──────────────────────────────────────────
// Middleware
// ──────────────────────────────────────────

// Body parsing
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// CORS
app.use(cors({
  origin: '*', // Allow all origins for development
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));

// Rate limiting on auth routes
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 20,
  message: {
    success: false,
    message: 'Too many attempts. Please try again after 15 minutes.'
  }
});

// ──────────────────────────────────────────
// Routes
// ──────────────────────────────────────────

// Health check
app.get('/api/health', (req, res) => {
  res.json({
    success: true,
    message: 'Lottery API is running',
    timestamp: new Date().toISOString()
  });
});

// Auth routes (with rate limiting)
app.use('/api/auth', authLimiter, authRoutes);

// Wallet routes
app.use('/api/wallet', walletRoutes);

// Lottery routes
app.use('/api/lotteries', lotteryRoutes);

// Tickets route
app.get('/api/tickets/my-tickets', auth, lotteryController.getAllMyTickets);

// Admin routes
app.use('/api/admin', adminRoutes);

// ──────────────────────────────────────────
// Error handling
// ──────────────────────────────────────────

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: `Route ${req.method} ${req.originalUrl} not found`
  });
});

// Global error handler
app.use((err, req, res, next) => {
  console.error('Unhandled error:', err);
  res.status(500).json({
    success: false,
    message: 'Internal server error'
  });
});

// ──────────────────────────────────────────
// Start server
// ──────────────────────────────────────────

const PORT = process.env.PORT || 5000;

const startServer = async () => {
  // Connect to MongoDB
  await connectDB();

  // Seed admin user if not exists
  const User = require('./models/User');
  const adminExists = await User.findOne({ role: 'admin' });
  if (!adminExists) {
    await User.create({
      name: 'Admin',
      email: process.env.ADMIN_EMAIL || 'admin@lottery.com',
      phone: '9999999999',
      password: process.env.ADMIN_PASSWORD || 'admin123456',
      role: 'admin'
    });
    console.log('👤 Default admin created:', process.env.ADMIN_EMAIL);
  }

  // Start scheduled draws
  startScheduler();

  // Start Express
  app.listen(PORT, () => {
    console.log(`\n🚀 Lottery API Server running on port ${PORT}`);
    console.log(`📡 Health check: http://localhost:${PORT}/api/health`);
    console.log(`🔐 Admin email: ${process.env.ADMIN_EMAIL || 'admin@lottery.com'}\n`);
  });
};

startServer().catch(err => {
  console.error('Failed to start server:', err);
  process.exit(1);
});
