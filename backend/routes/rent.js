const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/authMiddleware');
const Property = require('../models/Property');
const Unit = require('../models/Unit');
const Tenant = require('../models/Tenant');
const RentPayment = require('../models/RentPayment');
const User = require('../models/User');

// --- Properties ---

// Create a Property
router.post('/properties', protect, async (req, res) => {
  try {
    const { name, location } = req.body;
    
    // Auto-assign landlord role if they are creating a property
    if (req.user.role === 'user') {
      req.user.role = 'landlord';
      await req.user.save();
    }

    const property = new Property({
      landlordId: req.user._id,
      name,
      location
    });

    const savedProperty = await property.save();
    res.status(201).json(savedProperty);
  } catch (err) {
    res.status(500).json({ message: 'Error creating property', error: err.message });
  }
});

// Get My Properties
router.get('/properties', protect, async (req, res) => {
  try {
    const properties = await Property.find({ landlordId: req.user._id });
    res.json(properties);
  } catch (err) {
    res.status(500).json({ message: 'Error fetching properties', error: err.message });
  }
});

// --- Units ---

// Add a Unit
router.post('/units', protect, async (req, res) => {
  try {
    const { propertyId, unitNumber, type, rentAmount, depositAmount } = req.body;

    const property = await Property.findOne({ _id: propertyId, landlordId: req.user._id });
    if (!property) return res.status(404).json({ message: 'Property not found' });

    const unit = new Unit({
      propertyId,
      unitNumber,
      type,
      rentAmount,
      depositAmount
    });

    const savedUnit = await unit.save();
    res.status(201).json(savedUnit);
  } catch (err) {
    res.status(500).json({ message: 'Error adding unit', error: err.message });
  }
});

// Get Units for a Property
router.get('/units/:propertyId', protect, async (req, res) => {
  try {
    const property = await Property.findOne({ _id: req.params.propertyId, landlordId: req.user._id });
    if (!property) return res.status(404).json({ message: 'Property not found' });

    const units = await Unit.find({ propertyId: req.params.propertyId });
    res.json(units);
  } catch (err) {
    res.status(500).json({ message: 'Error fetching units', error: err.message });
  }
});

// --- Tenants ---

// Add a Tenant
router.post('/tenants', protect, async (req, res) => {
  try {
    const { name, phone, idNumber, unitId, moveInDate } = req.body;

    const unit = await Unit.findById(unitId);
    if (!unit) return res.status(404).json({ message: 'Unit not found' });

    const property = await Property.findOne({ _id: unit.propertyId, landlordId: req.user._id });
    if (!property) return res.status(403).json({ message: 'Unauthorized' });

    const tenant = new Tenant({
      landlordId: req.user._id,
      unitId,
      name,
      phone,
      idNumber,
      moveInDate
    });

    const savedTenant = await tenant.save();

    // Mark unit as occupied
    unit.status = 'Occupied';
    await unit.save();

    res.status(201).json(savedTenant);
  } catch (err) {
    res.status(500).json({ message: 'Error adding tenant', error: err.message });
  }
});

// Get My Tenants
router.get('/tenants', protect, async (req, res) => {
  try {
    const tenants = await Tenant.find({ landlordId: req.user._id }).populate('unitId');
    res.json(tenants);
  } catch (err) {
    res.status(500).json({ message: 'Error fetching tenants', error: err.message });
  }
});

// --- Payments ---

// Record Payment
router.post('/payments', protect, async (req, res) => {
  try {
    const { tenantId, amount, paymentMethod } = req.body;

    const tenant = await Tenant.findOne({ _id: tenantId, landlordId: req.user._id });
    if (!tenant) return res.status(404).json({ message: 'Tenant not found' });

    const receiptNumber = 'RCT-' + Math.random().toString(36).substr(2, 9).toUpperCase();

    const payment = new RentPayment({
      landlordId: req.user._id,
      tenantId: tenant._id,
      unitId: tenant.unitId,
      amount,
      receiptNumber,
      paymentMethod
    });

    const savedPayment = await payment.save();
    
    // Update tenant balance (reduce debt or increase overpayment)
    tenant.balance -= amount;
    await tenant.save();

    res.status(201).json(savedPayment);
  } catch (err) {
    res.status(500).json({ message: 'Error recording payment', error: err.message });
  }
});

// Get Payments
router.get('/payments', protect, async (req, res) => {
  try {
    const payments = await RentPayment.find({ landlordId: req.user._id })
      .populate('tenantId', 'name')
      .populate('unitId', 'unitNumber type')
      .sort({ date: -1 });
    res.json(payments);
  } catch (err) {
    res.status(500).json({ message: 'Error fetching payments', error: err.message });
  }
});

// --- Dashboard ---
router.get('/dashboard', protect, async (req, res) => {
  try {
    const landlordId = req.user._id;

    const properties = await Property.find({ landlordId });
    const propertyIds = properties.map(p => p._id);

    const units = await Unit.find({ propertyId: { $in: propertyIds } });
    const occupiedUnits = units.filter(u => u.status === 'Occupied').length;
    
    const tenants = await Tenant.find({ landlordId });
    const outstandingBalances = tenants.reduce((sum, t) => sum + (t.balance > 0 ? t.balance : 0), 0);

    const now = new Date();
    const firstDayOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
    
    const monthlyPayments = await RentPayment.find({
      landlordId,
      date: { $gte: firstDayOfMonth }
    });
    
    const monthlyRentCollected = monthlyPayments.reduce((sum, p) => sum + p.amount, 0);

    res.json({
      totalProperties: properties.length,
      totalUnits: units.length,
      occupiedUnits,
      vacantUnits: units.length - occupiedUnits,
      monthlyRentCollected,
      outstandingBalances
    });
  } catch (err) {
    res.status(500).json({ message: 'Error fetching dashboard data', error: err.message });
  }
});

module.exports = router;
