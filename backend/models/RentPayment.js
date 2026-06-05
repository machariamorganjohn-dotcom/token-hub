const mongoose = require('mongoose');

const rentPaymentSchema = new mongoose.Schema({
  landlordId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  tenantId: { type: mongoose.Schema.Types.ObjectId, ref: 'Tenant', required: true },
  unitId: { type: mongoose.Schema.Types.ObjectId, ref: 'Unit', required: true },
  amount: { type: Number, required: true },
  date: { type: Date, default: Date.now },
  receiptNumber: { type: String, required: true, unique: true },
  paymentMethod: { type: String, enum: ['M-Pesa', 'Cash', 'Bank Transfer'], default: 'M-Pesa' },
  status: { type: String, enum: ['Completed', 'Pending', 'Failed'], default: 'Completed' },
  createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('RentPayment', rentPaymentSchema);
