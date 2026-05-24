const express = require('express');
const { protect, admin } = require('../middleware/authMiddleware');
const User = require('../models/User');
const Transaction = require('../models/Transaction');

const router = express.Router();

// @desc    Get system-wide stats
// @route   GET /api/admin/stats
// @access  Private/Admin
router.get('/stats', protect, admin, async (req, res) => {
  try {
    const totalUsers = await User.countDocuments();
    const totalTransactions = await Transaction.countDocuments();
    const totalVolume = await Transaction.aggregate([
      { $match: { status: 'success' } },
      { $group: { _id: null, total: { $sum: "$amount" } } }
    ]);
    const totalSosDebt = await User.aggregate([
      { $group: { _id: null, total: { $sum: "$emergencyDebt" } } }
    ]);

    res.json({
      users: totalUsers,
      transactions: totalTransactions,
      revenue: (totalVolume[0]?.total || 0),
      outstandingDebt: (totalSosDebt[0]?.total || 0),
      platformFees: totalTransactions * 5 // 5 KES per transaction
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// @desc    Get all users
// @route   GET /api/admin/users
// @access  Private/Admin
router.get('/users', protect, admin, async (req, res) => {
  try {
    const users = await User.find({}).select('-password');
    res.json(users);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// @desc    Promote a user to admin (Secure - only founders can do this)
// @route   PUT /api/admin/promote/:id
// @access  Private/Admin
router.put('/promote/:id', protect, admin, async (req, res) => {
    try {
        const user = await User.findById(req.params.id);
        if (!user) return res.status(404).json({ message: 'User not found' });
        
        user.role = 'admin';
        await user.save();
        res.json({ message: `${user.name} promoted to Admin.` });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

module.exports = router;
