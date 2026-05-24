const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema({
  name: { type: String, required: true },
  phone: { type: String, required: true, unique: true },
  email: { type: String, unique: true, sparse: true },
  password: { type: String, required: true },
  balance: { type: Number, default: 0 },
  initialUnits: { type: Number, default: 0 },
  isInitialSetupDone: { type: Boolean, default: false },
  lastUnitSyncAt: { type: Date, default: Date.now },
  consumptionRate: { type: Number, default: 0.02 }, // Units per hour (default simulation)
  emergencyDebt: { type: Number, default: 0 },
  loyaltyPoints: { type: Number, default: 0 },
  role: { type: String, enum: ['user', 'admin'], default: 'user' },
  createdAt: { type: Date, default: Date.now },
  lastLoginAt: { type: Date },
  resetPasswordToken: { type: String },
  resetPasswordExpires: { type: Date }
});

// Optimization Indexes for High Scale
userSchema.index({ phone: 1 });
userSchema.index({ email: 1 });
userSchema.index({ createdAt: -1 });

// Hash password before saving
userSchema.pre('save', async function(next) {
  if (!this.isModified('password')) return next();
  const salt = await bcrypt.genSalt(10);
  this.password = await bcrypt.hash(this.password, salt);
  next();
});

// Compare password
userSchema.methods.matchPassword = async function(enteredPassword) {
  return await bcrypt.compare(enteredPassword, this.password);
};

module.exports = mongoose.model('User', userSchema);
