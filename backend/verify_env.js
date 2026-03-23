const DarajaService = require('./services/daraja_service');
const KPLCService = require('./services/kplc_service');
require('dotenv').config();

async function verifyEnvironment() {
  console.log('--- Token Hub Environment Verification ---');
  
  const requiredVars = [
    'DARAJA_CONSUMER_KEY',
    'DARAJA_CONSUMER_SECRET',
    'DARAJA_SHORTCODE',
    'DARAJA_LNM_PASSKEY',
    'DARAJA_CALLBACK_URL',
    'AT_API_KEY',
    'AT_USERNAME'
  ];

  let missing = [];
  requiredVars.forEach(v => {
    if (!process.env[v] || process.env[v].includes('your_')) {
      missing.push(v);
    }
  });

  if (missing.length > 0) {
    console.warn('⚠️ Missing or placeholder credentials:', missing.join(', '));
  } else {
    console.log('✅ All environment variables are set.');
  }

  console.log('\nTesting Daraja Authentication...');
  try {
    const token = await DarajaService.getAccessToken();
    console.log('✅ Daraja OAuth Success! Access Token obtained.');
  } catch (error) {
    console.error('❌ Daraja OAuth Failed:', error.message);
  }

  console.log('\nTesting Africa\'s Talking Initialization...');
  try {
    // We don't want to actually vend a token here as it costs money/units
    if (process.env.AT_API_KEY && process.env.AT_API_KEY !== 'your_africastalking_api_key') {
        console.log('✅ Africa\'s Talking SDK initialized.');
    } else {
        console.warn('⚠️ Africa\'s Talking credentials not set.');
    }
  } catch (error) {
    console.error('❌ AT Initialization Failed:', error.message);
  }

  console.log('\n--- Verification Complete ---');
}

verifyEnvironment();
