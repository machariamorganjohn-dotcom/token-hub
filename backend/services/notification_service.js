/**
 * Notification Service Simulator
 * In production, you would use 'firebase-admin' for Push or 'africastalking-node' for SMS.
 */
class NotificationService {
  static async sendTokenSMS(phone, meterNumber, token, units) {
    console.log('--- [SMS OUTBOX] ---');
    console.log(`To: ${phone}`);
    console.log(`Message: Your Token Hub recharge for Meter ${meterNumber} was successful.`);
    console.log(`Token: ${token}`);
    console.log(`Units: ${units} Units awarded.`);
    console.log('--------------------');
    
    // Simulate API delay
    return new Promise(resolve => setTimeout(resolve, 500));
  }

  static async sendPushNotification(userId, title, body) {
    console.log('--- [PUSH NOTIFICATION] ---');
    console.log(`UserID: ${userId}`);
    console.log(`Title: ${title}`);
    console.log(`Body: ${body}`);
    console.log('----------------------------');
    
    return new Promise(resolve => setTimeout(resolve, 300));
  }

  static async alertTransactionFailure(phone, reason) {
    console.log('--- [ALERT OUTBOX] ---');
    console.log(`To: ${phone}`);
    console.log(`Message: ALERT - Your Token Hub purchase failed. Reason: ${reason}. Please contact support at 0705731400.`);
    console.log('----------------------');
  }
}

module.exports = NotificationService;
