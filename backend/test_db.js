const mongoose = require('mongoose');
require('dotenv').config();

const testConnection = async () => {
    console.log('Attempting to connect to MongoDB...');
    try {
        await mongoose.connect(process.env.MONGO_URI);
        console.log('SUCCESS: MongoDB connected successfully!');
        process.exit(0);
    } catch (err) {
        console.error('FAILURE: MongoDB connection error:');
        console.error(err);
        process.exit(1);
    }
};

testConnection();
