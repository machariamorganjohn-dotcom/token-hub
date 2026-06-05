const mongoose = require('mongoose');

const tenantSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' }, // Optional, if tenant signs up
  landlordId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  unitId: { type: mongoose.Schema.Types.ObjectId, ref: 'Unit', required: true },
  name: { type: String, required: true },
  phone: { type: String, required: true },
  idNumber: { type: String },
  moveInDate: { type: Date, default: Date.now },
  balance: { type: Number, default: 0 }, // Positive = owes rent, Negative = overpaid
  status: { type: String, enum: ['Active', 'Past'], default: 'Active' },
  createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('Tenant', tenantSchema);
