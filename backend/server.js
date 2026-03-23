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
app.use('/api/', apiLimiter); // Apply general rate limit to all /api routes

// Routes
app.use('/api/auth', authLimiter, require('./routes/auth'));
app.use('/api/meters', require('./routes/meter'));
app.use('/api/transactions', transactionLimiter, require('./routes/transaction'));

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ 
    message: 'Internal Server Error', 
    error: process.env.NODE_ENV === 'development' ? err.message : undefined 
  });
});

// Basic health check
app.get('/', (req, res) => {
  res.json({ status: 'Online', message: 'Token Hub API is running' });
});

// Database Connection
const PORT = process.env.PORT || 5000;
const MONGO_URI = process.env.MONGO_URI || 'mongodb://localhost:27017/token_hub';

mongoose.connect(MONGO_URI)
  .then(() => {
    console.log('MongoDB Connected successfully');
    app.listen(PORT, () => {
      console.log(`Server running on port ${PORT}`);
    });
  })
  .catch((err) => {
    console.error('MongoDB connection error:', err);
  });
