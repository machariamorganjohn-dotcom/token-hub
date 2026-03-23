const express = require('express');
const jwt = require('jsonwebtoken');
const User = require('../models/User');
const Meter = require('../models/Meter');

const router = express.Router();

// Simple JWT protection middleware (mocking full auth middleware for speed)
const protect = async (req, res, next) => {
  let token;
  if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
    try {
      token = req.headers.authorization.split(' ')[1];
      const decoded = jwt.verify(token, process.env.JWT_SECRET || 'secret123');
      req.user = await User.findById(decoded.id).select('-password');
      next();
    } catch (error) {
      return res.status(401).json({ message: 'Not authorized, token failed' });
    }
  } else {
    return res.status(401).json({ message: 'Not authorized, no token' });
  }
};

// @desc    Get all meters for logged in user
// @route   GET /api/meters
// @access  Private
router.get('/', protect, async (req, res) => {
  try {
    const meters = await Meter.find({ user: req.user._id });
    res.json(meters);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// @desc    Add a new meter
// @route   POST /api/meters
// @access  Private
router.post('/', protect, async (req, res) => {
  const { name, number } = req.body;

  try {
    const meterExists = await Meter.findOne({ number });

    if (meterExists) {
      return res.status(400).json({ message: 'Meter number already registered to a user' });
    }

    const meter = await Meter.create({
      user: req.user._id,
      name,
      number,
    });

    res.status(201).json(meter);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

module.exports = router;
