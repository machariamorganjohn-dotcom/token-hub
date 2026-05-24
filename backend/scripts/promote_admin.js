const mongoose = require('mongoose');
const User = require('../models/User');
require('dotenv').config({ path: '../.env' });

const phone = process.argv[2];

if (!phone) {
  console.log('Usage: node promote_admin.js <phone_number>');
  process.exit(1);
}

const promote = async () => {
  try {
    const MONGO_URI = process.env.MONGO_URI || 'mongodb://localhost:27017/token_hub';
    await mongoose.connect(MONGO_URI);
    
    const user = await User.findOne({ phone });
    if (!user) {
      console.log(`User with phone ${phone} not found.`);
      process.exit(1);
    }

    user.role = 'admin';
    await user.save();

    console.log(`✅ SUCCESS: ${user.name} (${phone}) has been promoted to FOUNDER/ADMIN.`);
    process.exit(0);
  } catch (err) {
    console.error(err);
    process.exit(1);
  }
};

promote();
