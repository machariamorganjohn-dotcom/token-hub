const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const morgan = require('morgan');
const { apiLimiter, authLimiter, transactionLimiter } = require('./middleware/rateLimit');
require('dotenv').config();

const app = express();

// Middleware
app.use(cors());
app.use(express.json());
app.use(morgan('dev'));

// Manual Security Headers (Helmet alternative)
app.use((req, res, next) => {
  res.setHeader('X-Frame-Options', 'DENY');
  res.setHeader('X-Content-Type-Options', 'nosniff');
  res.setHeader('X-XSS-Protection', '1; mode=block');
  res.setHeader('Content-Security-Policy', "default-src 'self'");
  res.setHeader('Strict-Transport-Security', 'max-age=31536000; includeSubDomains');
  next();
});

// Request Integrity Verification (Anti-Theft/Anti-Tamper)
const verifyRequestSignature = (req, res, next) => {
  if (req.method === 'POST' && req.path.includes('transaction')) {
    const signature = req.headers['x-hub-signature'];
    if (!signature && process.env.NODE_ENV === 'production') {
      return res.status(403).json({ message: 'Request integrity check failed. Potential tampering detected.' });
    }
    // In production, we would verify the HMAC of the body using a shared secret
  }
  next();
};
app.use(verifyRequestSignature);

// Database connection check middleware
app.use((req, res, next) => {
  if (mongoose.connection.readyState !== 1 && req.path.startsWith('/api')) {
    return res.status(503).json({ 
      message: 'Database is currently offline. Please check your internet connection and MongoDB Atlas IP whitelist.' 
    });
  }
  next();
});

app.use('/api/', apiLimiter); // Apply general rate limit to all /api routes

// Routes
app.use('/api/auth', authLimiter, require('./routes/auth'));
app.use('/api/meters', require('./routes/meter'));
app.use('/api/transactions', transactionLimiter, require('./routes/transaction'));
app.use('/api/admin', require('./routes/admin'));
app.use('/api/rent', require('./routes/rent'));

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ 
    message: 'Internal Server Error', 
    error: process.env.NODE_ENV === 'development' ? err.message : undefined 
  });
});

// Basic health check & Version Control
app.get('/', (req, res) => {
  res.json({ 
    status: 'Online', 
    message: 'Token Hub API is running',
    version: '1.2.0',
    minRequiredVersion: '1.0.0'
  });
});

const cluster = require('cluster');
const os = require('os');

// Database Connection
const PORT = process.env.PORT || 5000;
const MONGO_URI = process.env.MONGO_URI || 'mongodb://localhost:27017/token_hub';

if (cluster.isMaster && process.env.NODE_ENV === 'production') {
  const numCPUs = os.cpus().length;
  console.log(`Master process ${process.pid} is running`);
  console.log(`Spawning ${numCPUs} workers for high-scale performance...`);

  for (let i = 0; i < numCPUs; i++) {
    cluster.fork();
  }

  cluster.on('exit', (worker, code, signal) => {
    console.log(`Worker ${worker.process.pid} died. Spawning replacement...`);
    cluster.fork();
  });
} else {
  console.log('Connecting to MongoDB...');
  mongoose.connect(MONGO_URI, {
    serverSelectionTimeoutMS: 5000,
    maxPoolSize: 100 // Increased pool size for high concurrency
  })
    .then(() => {
      console.log(`✅ Worker ${process.pid} connected to MongoDB`);
    })
    .catch((err) => {
      console.error('❌ MongoDB connection error:', err.message);
    });

  app.listen(PORT, '0.0.0.0', () => {
    console.log(`🚀 Worker ${process.pid} running on port ${PORT}`);
  });
}
