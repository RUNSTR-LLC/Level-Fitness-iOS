# Lightning Wallet Setup Guide

## CoinOS Integration Setup

### Prerequisites
1. CoinOS API integration - no manual account creation needed
2. The app automatically creates CoinOS accounts for each user
3. Uses CoinOS REST API for wallet operations

### Setup Steps

#### 1. Understanding CoinOS Integration
- The app creates individual CoinOS accounts for each Level Fitness user
- Uses CoinOS REST API: `https://coinos.io/api`
- Automatic wallet creation with secure credential storage

#### 2. How It Works
The integration automatically:
- Generates unique CoinOS credentials for each user (`levelfitness_[userID]`)
- Registers the user with CoinOS via `/register` endpoint
- Stores credentials securely in iOS Keychain
- Authenticates via `/login` endpoint to get JWT tokens

#### 3. Test Integration
The app will automatically:
- Create wallets for new users
- Load real Lightning balances
- Enable send/receive functionality
- Distribute workout rewards

### Features Implemented

#### ✅ Core Lightning Operations
- **Wallet Creation**: Automatic setup for new users
- **Balance Retrieval**: Real-time satoshi balances
- **Invoice Generation**: Create Lightning invoices for receiving
- **Payment Processing**: Send Lightning payments
- **Reward Distribution**: Automated workout reward payouts

#### ✅ User Experience
- **Send/Receive UI**: Native iOS dialogs for Lightning operations
- **Balance Display**: Real satoshi balances in earnings page
- **Transaction History**: Track payments and rewards
- **Error Handling**: Graceful fallbacks when wallet not configured

#### ✅ Integration Points
- **Authentication**: Automatic wallet setup on user registration
- **Earnings Page**: Real Lightning balance display
- **Workout Rewards**: Automatic reward distribution based on activity

### API Endpoints Used

```swift
// User registration
POST /register
{
  "user": {
    "username": "levelfitness_12345678",
    "password": "secureGeneratedPassword"
  }
}

// User login
POST /login
{
  "username": "levelfitness_12345678", 
  "password": "secureGeneratedPassword"
}

// Get user info and balance
GET /me
Authorization: Bearer JWT_TOKEN

// Create Lightning invoice
POST /invoice
{
  "invoice": {
    "amount": 1000,
    "type": "lightning"
  }
}

// Send Lightning payment
POST /payments
{
  "payreq": "lnbc1000n1..."
}

// List payments
GET /payments?limit=20
```

### Error Handling

The implementation includes comprehensive error handling:

- **Authentication Errors**: Missing or invalid API token
- **Network Errors**: Connection issues with CoinOS API
- **Payment Errors**: Failed Lightning transactions
- **Balance Errors**: Issues retrieving wallet balance

Fallback behavior: App continues to work with mock data if Lightning integration fails.

### Security Considerations

- ✅ API tokens stored securely in iOS Keychain
- ✅ All network requests use HTTPS
- ✅ Error messages don't expose sensitive information
- ✅ Authentication required for all wallet operations

### Testing

#### Manual Testing Steps
1. Configure valid CoinOS API token
2. Sign up new user - wallet should be created automatically
3. Navigate to Earnings page - real balance should load
4. Test "Receive" - should generate valid Lightning invoice
5. Test "Send" - should process Lightning payment (use testnet)

#### Automated Tests (TODO)
- Unit tests for CoinOS service methods
- Integration tests for wallet operations
- UI tests for send/receive flows

### Production Deployment

#### Before TestFlight:
- [ ] Configure production CoinOS credentials
- [ ] Test with real Bitcoin amounts (small values)
- [ ] Verify reward distribution calculations
- [ ] Test error scenarios and fallbacks
- [ ] Add proper logging/monitoring

#### Security Audit:
- [ ] Review API token storage
- [ ] Validate input sanitization
- [ ] Check for potential vulnerabilities
- [ ] Test rate limiting behavior

### Next Steps

1. **Configure Production Token**: Replace test token with production CoinOS credentials
2. **Test with Real Bitcoin**: Verify operations with actual satoshis
3. **Monitor Performance**: Add logging for Lightning operations
4. **User Onboarding**: Create setup flow for users to verify their wallet
5. **Advanced Features**: Add more Lightning Network features as needed

---

**Note**: This Lightning integration provides a complete Bitcoin rewards system for Level Fitness, enabling real value distribution based on workout achievements.