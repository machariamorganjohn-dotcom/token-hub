const express = require('express');
const jwt = require('jsonwebtoken');
const User = require('../models/User');

const router = express.Router();

// Generate JWT
const generateToken = (id) => {
  return jwt.sign({ id }, process.env.JWT_SECRET || 'secret123', {
    expiresIn: '30d',
  });
};

// @desc    Register a new user
// @route   POST /api/auth/register
// @access  Public
router.post('/register', async (req, res) => {
  const { name, phone, email, password } = req.body;

  try {
    const userExists = await User.findOne({ phone });

    if (userExists) {
      return res.status(400).json({ message: 'User with this phone number already exists' });
    }

    const user = await User.create({
      name,
      phone,
      email,
      password,
    });

    if (user) {
      res.status(201).json({
        _id: user._id,
        name: user.name,
        phone: user.phone,
        email: user.email,
        isInitialSetupDone: user.isInitialSetupDone,
        token: generateToken(user._id),
      });
    } else {
      res.status(400).json({ message: 'Invalid user data' });
    }
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// @desc    Auth user & get token
// @route   POST /api/auth/login
// @access  Public
router.post('/login', async (req, res) => {
  const { phone, password } = req.body;

  try {
    const user = await User.findOne({ phone });

    if (user && (await user.matchPassword(password))) {
      user.lastLoginAt = Date.now();
      await user.save();
      
      res.json({
        _id: user._id,
        name: user.name,
        phone: user.phone,
        email: user.email,
        balance: user.balance,
        isInitialSetupDone: user.isInitialSetupDone,
        token: generateToken(user._id),
      });
    } else {
      res.status(401).json({ message: 'Invalid phone or password' });
    }
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// @desc    Setup initial meter units
// @route   POST /api/auth/setup-meter
// @access  Private (should be protected by middleware in production)
router.post('/setup-meter', async (req, res) => {
  const { userId, initialUnits } = req.body;

  try {
    const user = await User.findById(userId);
    if (!user) return res.status(404).json({ message: 'User not found' });

    user.initialUnits = initialUnits;
    user.balance = initialUnits;
    user.isInitialSetupDone = true;
    user.lastUnitSyncAt = Date.now();
    await user.save();

    res.json({ 
      message: 'Initial units saved', 
      balance: user.balance,
      isInitialSetupDone: true 
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// @desc    Sync and get current balance (accounting for consumption)
// @route   POST /api/auth/sync-balance
// @access  Private
router.post('/sync-balance', async (req, res) => {
  const { userId } = req.body;

  try {
    const user = await User.findById(userId);
    if (!user) return res.status(404).json({ message: 'User not found' });

    if (user.isInitialSetupDone) {
      const now = new Date();
      const lastSync = new Date(user.lastUnitSyncAt);
      const elapsedHours = (now - lastSync) / (1000 * 60 * 60);
      
      const consumed = elapsedHours * user.consumptionRate;
      if (consumed > 0) {
        user.balance = Math.max(0, user.balance - consumed);
        user.lastUnitSyncAt = now;
        await user.save();
      }
    }

    res.json({ 
      balance: user.balance,
      lastUnitSyncAt: user.lastUnitSyncAt
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

module.exports = router;
