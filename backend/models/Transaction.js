const mongoose = require('mongoose');

const transactionSchema = new mongoose.Schema({
  user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  title: { type: String, required: true },
  amount: { type: Number, required: true },
  unitsReceived: { type: Number, required: true },
  meterNumber: { type: String, required: true },
  tokenPayload: { type: String }, // Generated only on success
  status: { 
    type: String, 
    enum: ['pending', 'success', 'failed'], 
    default: 'pending' 
  },
  checkoutRequestId: { type: String, unique: true, sparse: true },
  paymentReference: { type: String }, // M-pesa receipt number 
  resultCode: { type: Number },
  resultDesc: { type: String },
  vendorRequestId: { type: String },
  timestamp: { type: Date, default: Date.now }
});

module.exports = mongoose.model('Transaction', transactionSchema);
