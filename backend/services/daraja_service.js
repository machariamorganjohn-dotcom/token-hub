const axios = require('axios');
require('dotenv').config();

class DarajaService {
  constructor() {
    this.consumerKey = process.env.DARAJA_CONSUMER_KEY;
    this.consumerSecret = process.env.DARAJA_CONSUMER_SECRET;
    this.shortCode = process.env.DARAJA_SHORTCODE;
    this.passkey = process.env.DARAJA_LNM_PASSKEY;
    this.callbackUrl = process.env.DARAJA_CALLBACK_URL;
    
    // Environment detection
    this.isProduction = process.env.NODE_ENV === 'production';
    this.baseUrl = this.isProduction 
      ? 'https://api.safaricom.co.ke' 
      : 'https://sandbox.safaricom.co.ke';
      
    this.authUrl = `${this.baseUrl}/oauth/v1/generate?grant_type=client_credentials`;
    this.stkPushUrl = `${this.baseUrl}/mpesa/stkpush/v1/processrequest`;
  }

  async getAccessToken() {
    const auth = Buffer.from(`${this.consumerKey}:${this.consumerSecret}`).toString('base64');
    try {
      const response = await axios.get(this.authUrl, {
        headers: {
          Authorization: `Basic ${auth}`,
        },
      });
      return response.data.access_token;
    } catch (error) {
      console.error('Error fetching Daraja access token:', error.response ? error.response.data : error.message);
      throw new Error('Failed to authenticate with Daraja. Check your consumer keys.');
    }
  }

  async initiateStkPush(amount, phoneNumber, checkoutRequestId) {
    const token = await this.getAccessToken();
    const timestamp = new Date().toISOString().replace(/[^0-9]/g, '').slice(0, 14);
    
    // Password is Shortcode + Passkey + Timestamp (Base64 encoded)
    const password = Buffer.from(`${this.shortCode}${this.passkey}${timestamp}`).toString('base64');

    // M-Pesa expects phone numbers in format 2547XXXXXXXX
    let formattedPhone = phoneNumber.replace(/[^0-9]/g, '');
    if (formattedPhone.startsWith('0')) {
      formattedPhone = '254' + formattedPhone.slice(1);
    } else if (formattedPhone.startsWith('7') || formattedPhone.startsWith('1')) {
      formattedPhone = '254' + formattedPhone;
    }

    const payload = {
      BusinessShortCode: this.shortCode,
      Password: password,
      Timestamp: timestamp,
      TransactionType: 'CustomerPayBillOnline',
      Amount: Math.round(amount),
      PartyA: formattedPhone,
      PartyB: this.shortCode,
      PhoneNumber: formattedPhone,
      CallBackURL: this.callbackUrl,
      AccountReference: 'TokenHub',
      TransactionDesc: 'Token Purchase',
    };

    try {
      const response = await axios.post(this.stkPushUrl, payload, {
        headers: {
          Authorization: `Bearer ${token}`,
        },
      });
      return response.data;
    } catch (error) {
      console.error('Error initiating Daraja STK Push:', error.response ? error.response.data : error.message);
      throw new Error('Failed to initiate M-Pesa payment. Check shortcode and passkey.');
    }
  }
}

module.exports = new DarajaService();
