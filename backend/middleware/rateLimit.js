const rateLimit = require('express-rate-limit');

// General limiter for all requests
const apiLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // Limit each IP to 100 requests per `window`
  standardHeaders: true, // Return rate limit info in the `RateLimit-*` headers
  legacyHeaders: false, // Disable the `X-RateLimit-*` headers
  message: {
    message: 'Too many requests from this IP, please try again after 15 minutes'
  }
});

// Stricter limiter for Auth (Registration/Login)
const authLimiter = rateLimit({
  windowMs: 60 * 60 * 1000, // 1 hour
  max: 10, // Limit each IP to 10 requests per hour
  message: {
    message: 'Too many authentication attempts, please try again in an hour'
  }
});

// Stricter limiter for Transactions
const transactionLimiter = rateLimit({
  windowMs: 1 * 60 * 1000, // 1 minute
  max: 3, // Limit each IP to 3 transaction attempts per minute
  message: {
    message: 'Transaction attempt limit exceeded, please wait a minute'
  }
});

module.exports = {
  apiLimiter,
  authLimiter,
  transactionLimiter
};
