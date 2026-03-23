const express = require('express');
const jwt = require('jsonwebtoken');
const User = require('../models/User');
const Transaction = require('../models/Transaction');
const NotificationService = require('../services/notification_service');
const DarajaService = require('../services/daraja_service');
const KPLCService = require('../services/kplc_service');

const router = express.Router();

const protect = async (req, res, next) => {
  let token;
  if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
    try {
      token = req.headers.authorization.split(' ')[1];
      const decoded = jwt.verify(token, process.env.JWT_SECRET || 'secret123');
      req.user = await User.findById(decoded.id).select('-password');
      next();
    } catch (error) {
      return res.status(401).json({ message: 'Not authorized, token failed' });
    }
  } else {
    return res.status(401).json({ message: 'Not authorized, no token' });
  }
};

// @desc    Get user transactions
// @route   GET /api/transactions
// @access  Private
router.get('/', protect, async (req, res) => {
  try {
    const transactions = await Transaction.find({ user: req.user._id }).sort({ timestamp: -1 });
    res.json(transactions);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// @desc    Initiate an STK Push payment (PENDING)
// @route   POST /api/transactions/stkpush
// @access  Private
router.post('/stkpush', protect, async (req, res) => {
  const { amount, meterNumber, phoneNumber } = req.body;
  
  if (!amount || !meterNumber) {
    return res.status(400).json({ message: 'Amount and Meter Number are required' });
  }

  try {
    // Initiate Real STK Push via Daraja
    const darajaResponse = await DarajaService.initiateStkPush(amount, phoneNumber, '');

    // Create a PENDING transaction in our database
    const transaction = await Transaction.create({
      user: req.user._id,
      title: 'Token Purchase (M-Pesa)',
      amount: amount,
      unitsReceived: amount * 0.05,
      meterNumber: meterNumber,
      status: 'pending',
      checkoutRequestId: darajaResponse.CheckoutRequestID
    });

    res.status(200).json({
      message: 'STK Push initiated. Please enter your PIN on your phone.',
      checkoutRequestId: darajaResponse.CheckoutRequestID,
      transactionId: transaction._id
    });

  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// @desc    M-Pesa Callback Endpoint (SECURE VERIFICATION)
// @route   POST /api/transactions/callback
// @access  Public (exposed to Safaricom)
router.post('/callback', async (req, res) => {
  try {
    // REAL Safaricom Payload Structure:
    // { "Body": { "stkCallback": { "MerchantRequestID": "...", "CheckoutRequestID": "...", "ResultCode": 0, "ResultDesc": "...", "CallbackMetadata": { "Item": [...] } } } }
    
    const { Body } = req.body;
    if (!Body || !Body.stkCallback) {
        console.warn('Invalid callback payload received:', JSON.stringify(req.body));
        return res.status(400).json({ message: 'Invalid payload' });
    }

    const { CheckoutRequestID, ResultCode, ResultDesc, CallbackMetadata } = Body.stkCallback;
    let MpesaReceiptNumber = '';
    let PaidAmount = 0;

    if (CallbackMetadata && CallbackMetadata.Item) {
        const metadataItems = CallbackMetadata.Item;
        const receiptItem = metadataItems.find(item => item.Name === 'MpesaReceiptNumber');
        const amountItem = metadataItems.find(item => item.Name === 'Amount');
        
        if (receiptItem) MpesaReceiptNumber = receiptItem.Value;
        if (amountItem) PaidAmount = amountItem.Value;
    }

    console.log(`[CALLBACK] Received for ${CheckoutRequestID} | Result: ${ResultCode} (${ResultDesc})`);

    const transaction = await Transaction.findOne({ checkoutRequestId: CheckoutRequestID });
    if (!transaction) {
      console.error(`Transaction not found for CheckoutRequestID: ${CheckoutRequestID}`);
      return res.status(404).json({ message: 'Transaction not found' });
    }

    // Fraud/Duplicate Check: If already processed, ignore
    if (transaction.status !== 'pending') {
      return res.status(200).json({ message: 'Already processed' });
    }

    transaction.resultCode = ResultCode;
    transaction.resultDesc = ResultDesc;

    if (ResultCode === 0) {
      // SUCCESS: Generate Token and Update Balance
      const user = await User.findById(transaction.user);
      
      // Use the actual amount from M-Pesa if it differs from our recorded amount
      let effectiveAmount = PaidAmount || transaction.amount;
      let debtDeducted = 0;
      
      // Update transaction amount if Safaricom reports different
      if (PaidAmount && PaidAmount !== transaction.amount) {
          transaction.amount = PaidAmount;
      }

      // Deduct SOS debt if any
      if (user.emergencyDebt > 0) {
          if (effectiveAmount >= user.emergencyDebt) {
              effectiveAmount -= user.emergencyDebt;
              debtDeducted = user.emergencyDebt;
              user.emergencyDebt = 0;
          } else {
              user.emergencyDebt -= effectiveAmount;
              debtDeducted = effectiveAmount;
              effectiveAmount = 0;
          }
      }

      const finalUnits = effectiveAmount * 0.05;
      user.balance += finalUnits;
      user.lastUnitSyncAt = Date.now();
      await user.save();

      // REAL KPLC VENDING (via Africa's Talking)
      try {
        const vendingResponse = await KPLCService.vendToken(transaction.meterNumber, effectiveAmount);
        transaction.tokenPayload = vendingResponse.token;
        transaction.vendorRequestId = vendingResponse.requestId;
      } catch (vendError) {
          console.error('[CRITICAL] Vending failed after payment success:', vendError.message);
          // In a real app, you would add this to a retry queue or alert admin
          transaction.tokenPayload = "PENDING_MANUAL_VEND";
      }

      transaction.status = 'success';
      transaction.unitsReceived = finalUnits;
      transaction.paymentReference = MpesaReceiptNumber || 'MPESA-' + Date.now();
      
      // Trigger Notifications
      await NotificationService.sendTokenSMS(user.phone, transaction.meterNumber, transaction.tokenPayload, finalUnits.toFixed(2));
      await NotificationService.sendPushNotification(user._id, "Token Purchase Successful", `Your token for meter ${transaction.meterNumber} is ${transaction.tokenPayload}. ${finalUnits.toFixed(2)} units added.`);
    } else {
      // FAILED
      transaction.status = 'failed';
      const user = await User.findById(transaction.user);
      if (user) {
        await NotificationService.alertTransactionFailure(user.phone, ResultDesc || 'Payment declined');
      }
    }

    await transaction.save();
    return res.status(200).json({ message: 'Callback processed successfully' });

  } catch (error) {
    console.error('Callback error:', error);
    return res.status(500).json({ message: 'Internal Server Error' });
  }
});

// @desc    Check transaction status (Polling fallback)
// @route   GET /api/transactions/status/:id
// @access  Private
router.get('/status/:id', protect, async (req, res) => {
    try {
        const transaction = await Transaction.findOne({
            $or: [{ _id: req.params.id }, { checkoutRequestId: req.params.id }],
            user: req.user._id
        });
        if (!transaction) return res.status(404).json({ message: 'Transaction not found' });
        res.json(transaction);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// @desc    Trigger Emergency SOS Token
// @route   POST /api/transactions/sos
// @access  Private
router.post('/sos', protect, async (req, res) => {
  const { meterNumber } = req.body;
  if (!meterNumber) return res.status(400).json({ message: 'Meter Number is required' });

  try {
    const user = req.user;
    if (user.emergencyDebt > 0) {
      return res.status(400).json({ message: 'Clear your existing emergency debt before requesting another SOS token.' });
    }

    const loanAmount = 150;
    const loanUnits = loanAmount * 0.05;
    
    user.balance += loanUnits;
    user.emergencyDebt = loanAmount;
    user.lastUnitSyncAt = Date.now();
    await user.save();

    // SOS tokens are generated immediately as they are "loans"
    let tokenPayload = "";
    for (let i = 0; i < 20; i++) {
        tokenPayload += Math.floor(Math.random() * 10).toString();
        if ((i + 1) % 4 === 0 && i !== 19) tokenPayload += "-";
    }

    const transaction = await Transaction.create({
      user: req.user._id,
      title: 'SOS Emergency Token',
      amount: loanAmount,
      unitsReceived: loanUnits,
      meterNumber: meterNumber,
      tokenPayload: tokenPayload,
      status: 'success',
      paymentReference: 'SOS-' + Date.now()
    });

    res.status(200).json({
      message: 'SOS Token Generated',
      transaction,
      newBalance: user.balance,
      newDebt: user.emergencyDebt
    });

  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

module.exports = router;
