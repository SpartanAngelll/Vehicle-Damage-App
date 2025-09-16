# Cash-Out Feature Implementation

## 🚀 Overview

This implementation provides a comprehensive cash-out feature for service professionals in the Flutter app with Postgres + Firebase backend. Service professionals can request payouts of their available earnings, with real-time updates and secure processing.

## ✨ Features

### **Core Functionality**
- **Cash-out Requests**: Service professionals can request payouts of their available balance
- **Balance Tracking**: Real-time tracking of available balance, total earned, and total paid out
- **Payout History**: Complete history of all payout requests with status tracking
- **Real-time Updates**: Firebase sync for instant UI updates
- **Security**: Backend-only payout processing with validation

### **User Experience**
- **Intuitive Dashboard**: Clean, modern UI for managing earnings and payouts
- **Quick Actions**: One-click cash-out with amount validation
- **Status Tracking**: Visual indicators for pending, successful, and failed payouts
- **Error Handling**: Comprehensive error messages and validation
- **Responsive Design**: Works on all screen sizes

## 🏗️ Architecture

### **Database Schema (Postgres)**
```sql
-- Payouts table
CREATE TABLE payouts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    professional_id VARCHAR(255) NOT NULL,
    amount DECIMAL(10,2) NOT NULL CHECK (amount > 0),
    currency VARCHAR(3) NOT NULL DEFAULT 'JMD',
    status VARCHAR(20) NOT NULL DEFAULT 'pending',
    payment_processor_transaction_id VARCHAR(255),
    payment_processor_response JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP WITH TIME ZONE,
    error_message TEXT,
    metadata JSONB
);

-- Professional balances table
CREATE TABLE professional_balances (
    professional_id VARCHAR(255) PRIMARY KEY,
    available_balance DECIMAL(10,2) NOT NULL DEFAULT 0.0,
    total_earned DECIMAL(10,2) NOT NULL DEFAULT 0.0,
    total_paid_out DECIMAL(10,2) NOT NULL DEFAULT 0.0,
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
```

### **Backend API Endpoints**
- `POST /api/cashout` - Process cash-out request
- `GET /api/professionals/:id/balance` - Get professional balance
- `GET /api/professionals/:id/payouts` - Get payout history
- `POST /api/cashout/validate` - Validate cash-out request
- `GET /api/professionals/:id/cashout-stats` - Get cash-out statistics

### **Firebase Collections**
- `payouts` - Payout records for real-time updates
- `professional_balances` - Professional balance data

## 📁 File Structure

```
lib/
├── models/
│   └── payout_models.dart              # Payout data models
├── services/
│   ├── payout_service.dart             # Core payout logic
│   ├── cashout_service.dart            # Flutter service layer
│   ├── api_service.dart                # Backend API client
│   └── firebase_sync_service.dart      # Firebase sync logic
├── widgets/
│   └── cashout_widgets.dart            # UI components
├── screens/
│   └── cashout_screen.dart             # Cash-out screens
└── database/
    └── cashout_migration.sql           # Database migration

backend/
├── server.js                           # Express.js API server
└── package.json                        # Node.js dependencies
```

## 🔧 Setup Instructions

### **1. Database Setup**
```bash
# Run the migration
psql -U postgres -d vehicle_damage_payments -f database/cashout_migration.sql
```

### **2. Backend Setup**
```bash
cd backend
npm install
npm start
```

### **3. Flutter Integration**
```dart
// Add to your existing professional dashboard
import 'screens/cashout_screen.dart';

// Navigate to cash-out screen
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => CashOutScreen(professionalId: professionalId),
  ),
);
```

## 💻 Usage Examples

### **Basic Cash-Out Request**
```dart
final cashOutService = CashOutService.instance;

// Request cash-out
final response = await cashOutService.requestCashOut(
  professionalId: 'professional_123',
  amount: 150.0,
);

if (response.success) {
  print('Cash-out successful: ${response.payout?.id}');
} else {
  print('Cash-out failed: ${response.error}');
}
```

### **Get Professional Balance**
```dart
final balance = await cashOutService.getProfessionalBalance('professional_123');
print('Available balance: \$${balance?.availableBalance}');
```

### **Real-time Balance Updates**
```dart
StreamBuilder<ProfessionalBalance?>(
  stream: cashOutService.getProfessionalBalanceStream('professional_123'),
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      return Text('Balance: \$${snapshot.data!.availableBalance}');
    }
    return CircularProgressIndicator();
  },
)
```

### **Payout History**
```dart
StreamBuilder<List<Payout>>(
  stream: cashOutService.getPayoutsStream('professional_123'),
  builder: (context, snapshot) {
    final payouts = snapshot.data ?? [];
    return ListView.builder(
      itemCount: payouts.length,
      itemBuilder: (context, index) {
        final payout = payouts[index];
        return ListTile(
          title: Text('\$${payout.amount}'),
          subtitle: Text(payout.status.name),
          trailing: Text(payout.createdAt.toString()),
        );
      },
    );
  },
)
```

## 🔒 Security Features

### **Backend Validation**
- Amount validation (minimum $10, maximum $10,000)
- Balance verification before processing
- Professional ownership validation
- Duplicate request prevention

### **Database Constraints**
- CHECK constraints on amount values
- Foreign key relationships
- Audit trail with status history

### **API Security**
- Professional ID validation
- Amount range validation
- Transaction rollback on errors

## 📊 Real-time Updates

### **Firebase Sync**
- Payout status changes sync to Firebase
- Professional balance updates in real-time
- UI automatically updates when data changes

### **Stream Listeners**
```dart
// Listen for payout updates
cashOutService.getPayoutsStream(professionalId).listen((payouts) {
  // Update UI with new payout data
});

// Listen for balance updates
cashOutService.getProfessionalBalanceStream(professionalId).listen((balance) {
  // Update UI with new balance
});
```

## 🎨 UI Components

### **CashOutDashboard**
- Available balance display
- Quick stats (total earned, paid out)
- Recent payouts list
- Quick action buttons

### **CashOutDialog**
- Amount input with validation
- Real-time balance display
- Processing status indicator

### **PayoutHistoryScreen**
- Complete payout history
- Status indicators
- Transaction details
- Search and filter options

## 🔄 Workflow

### **1. Professional Earns Money**
```dart
// When a payment is completed, update balance
await payoutService.updateProfessionalBalanceOnPayment(
  professionalId: 'professional_123',
  amount: 200.0,
);
```

### **2. Professional Requests Cash-Out**
```dart
// Validate request
final validation = await cashOutService.validateCashOutRequest(
  professionalId: 'professional_123',
  amount: 150.0,
);

if (validation.isValid) {
  // Process cash-out
  final response = await cashOutService.requestCashOut(
    professionalId: 'professional_123',
    amount: 150.0,
  );
}
```

### **3. Backend Processing**
1. Validate professional and amount
2. Check available balance
3. Create payout record
4. Process through payment processor
5. Update balance and status
6. Sync to Firebase

### **4. Real-time Updates**
- UI automatically updates with new balance
- Payout status changes reflected immediately
- Error messages displayed if processing fails

## 🧪 Testing

### **Unit Tests**
```dart
// Test cash-out validation
test('should validate cash-out request', () async {
  final validation = await cashOutService.validateCashOutRequest(
    professionalId: 'test_professional',
    amount: 100.0,
  );
  
  expect(validation.isValid, true);
});
```

### **Integration Tests**
```dart
// Test full cash-out flow
test('should process cash-out request', () async {
  final response = await cashOutService.requestCashOut(
    professionalId: 'test_professional',
    amount: 100.0,
  );
  
  expect(response.success, true);
  expect(response.payout, isNotNull);
});
```

## 🚀 Deployment

### **Backend Deployment**
1. Deploy Node.js server to your hosting platform
2. Set environment variables for database connection
3. Configure payment processor API keys
4. Set up SSL certificates

### **Flutter App**
1. Update API base URL for production
2. Configure Firebase project
3. Test on different devices
4. Deploy to app stores

## 📈 Monitoring

### **Logging**
- All payout requests are logged
- Error tracking for failed requests
- Performance monitoring

### **Analytics**
- Track cash-out frequency
- Monitor average payout amounts
- Identify popular payout times

## 🔧 Configuration

### **Environment Variables**
```bash
# Backend
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
POSTGRES_DB=vehicle_damage_payments
POSTGRES_USER=postgres
POSTGRES_PASSWORD=your_password

# Payment Processor (optional)
PAYMENT_PROCESSOR_API_KEY=your_api_key
PAYMENT_PROCESSOR_WEBHOOK_SECRET=your_webhook_secret
```

### **Flutter Configuration**
```dart
// Update API base URL
ApiService.instance.updateBaseUrl('https://your-api.com/api');
```

## 🐛 Troubleshooting

### **Common Issues**

1. **Database Connection Failed**
   - Check PostgreSQL is running
   - Verify connection credentials
   - Ensure database exists

2. **Payout Processing Failed**
   - Check payment processor configuration
   - Verify professional balance
   - Check for pending payouts

3. **Firebase Sync Issues**
   - Check Firebase project configuration
   - Verify collection permissions
   - Check network connectivity

### **Debug Mode**
```dart
// Enable debug logging
PayoutService.instance.initialize();
// Check console for detailed logs
```

## 📚 API Documentation

### **POST /api/cashout**
Request cash-out for a professional.

**Request Body:**
```json
{
  "professional_id": "professional_123",
  "amount": 150.0,
  "metadata": {
    "source": "mobile_app"
  }
}
```

**Response:**
```json
{
  "success": true,
  "message": "Cash-out processed successfully",
  "payout": {
    "id": "payout_456",
    "professional_id": "professional_123",
    "amount": 150.0,
    "status": "success",
    "created_at": "2024-01-01T12:00:00Z"
  }
}
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

For support and questions:
- Create an issue in the repository
- Check the troubleshooting section
- Review the API documentation

---

**Note**: This implementation provides a solid foundation for the cash-out feature. You may need to customize it based on your specific requirements, payment processor integration, and business rules.
