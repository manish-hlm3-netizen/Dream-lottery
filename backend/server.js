const express = require('express');
const cors = require('cors');
const rateLimit = require('express-rate-limit');
const path = require('path');
require('dotenv').config();

const connectDB = require('./config/db');
const { startScheduler } = require('./utils/scheduler');
const { startBotSimulator } = require('./utils/botSimulator');

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
  max: 1000,
  message: {
    success: false,
    message: 'Too many attempts. Please try again after 15 minutes.'
  }
});

// ──────────────────────────────────────────
// Static Assets & Public App Update Downloads
// ──────────────────────────────────────────

// Serve static files from 'public' folder
app.use('/public', express.static(path.join(__dirname, 'public')));

// Serve landing page at root route
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'public/index.html'));
});

// Public direct APK download endpoint
app.get('/api/app/download', (req, res) => {
  const fs = require('fs');
  const publicDir = path.join(__dirname, 'public');
  let targetApk = 'app-release.apk';

  try {
    if (fs.existsSync(publicDir)) {
      const files = fs.readdirSync(publicDir);
      const apkFiles = files.filter(f => (f.startsWith('dream-lottery-') || f.startsWith('app-release-')) && f.endsWith('.apk'));
      if (apkFiles.length > 0) {
        // Sort files descending to pick the one with the latest version name
        apkFiles.sort((a, b) => b.localeCompare(a));
        targetApk = apkFiles[0];
      }
    }
  } catch (err) {
    console.error('Error scanning public folder for versioned APKs:', err);
  }

  const apkPath = path.join(publicDir, targetApk);
  
  // Set cache control headers to prevent any caching of the APK file download
  res.setHeader('Cache-Control', 'no-store, no-cache, must-revalidate, proxy-revalidate, max-age=0');
  res.setHeader('Pragma', 'no-cache');
  res.setHeader('Expires', '0');

  res.download(apkPath, 'dream-lottery.apk', (err) => {
    if (err) {
      console.error('Download error:', err);
      if (!res.headersSent) {
        res.status(404).json({ success: false, message: 'App update file not found on server' });
      }
    }
  });
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

// Chat routes
app.use('/api/chat', require('./routes/chat'));

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
const HOST = '0.0.0.0'; // Required for Render

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

  // Start bot player simulator
  await startBotSimulator();

  // Start Express
  app.listen(PORT, HOST, () => {
    console.log(`\n🚀 Lottery API Server running on port ${PORT}`);
    console.log(`📡 Health check: http://localhost:${PORT}/api/health`);
    console.log(`🔐 Admin email: ${process.env.ADMIN_EMAIL || 'admin@lottery.com'}\n`);
  });
};

startServer().catch(err => {
  console.error('Failed to start server:', err);
  process.exit(1);
});
