const mongoose = require('mongoose');

const unitSchema = new mongoose.Schema({
  propertyId: { type: mongoose.Schema.Types.ObjectId, ref: 'Property', required: true },
  unitNumber: { type: String, required: true },
  type: { 
    type: String, 
    enum: ['Bedsitter', 'Single Room', '1 Bedroom', '2 Bedroom', '3 Bedroom', 'Custom'],
    required: true
  },
  rentAmount: { type: Number, required: true },
  depositAmount: { type: Number, default: 0 },
  status: { type: String, enum: ['Occupied', 'Vacant'], default: 'Vacant' },
  createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('Unit', unitSchema);
