const mongoose = require('mongoose');

const meterSchema = new mongoose.Schema({
  user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  name: { type: String, required: true },
  number: { type: String, required: true, unique: true },
  connectionStatus: { type: String, enum: ['disconnected', 'connecting', 'remote'], default: 'disconnected' },
  addedAt: { type: Date, default: Date.now }
});

meterSchema.index({ user: 1 });
meterSchema.index({ number: 1 });

module.exports = mongoose.model('Meter', meterSchema);
