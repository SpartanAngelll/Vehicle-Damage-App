#!/bin/bash

# Deploy Cloud Functions for Vehicle Damage App
# This script deploys the Cloud Functions with proper configuration

echo "🚀 Starting Cloud Functions deployment..."

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI is not installed. Please install it first:"
    echo "npm install -g firebase-tools"
    exit 1
fi

# Check if user is logged in
if ! firebase projects:list &> /dev/null; then
    echo "❌ Please login to Firebase first:"
    echo "firebase login"
    exit 1
fi

# Navigate to functions directory
cd backend/functions

echo "📦 Installing dependencies..."
npm install

echo "🔧 Linting code..."
npm run lint

echo "🚀 Deploying Cloud Functions..."
firebase deploy --only functions

if [ $? -eq 0 ]; then
    echo "✅ Cloud Functions deployed successfully!"
    echo ""
    echo "📋 Next steps:"
    echo "1. Configure SendGrid API key:"
    echo "   firebase functions:config:set sendgrid.api_key=\"YOUR_SENDGRID_API_KEY\""
    echo ""
    echo "2. Set up the database schema:"
    echo "   psql -d vehicle_damage_payments -f ../database/complete_schema.sql"
    echo ""
    echo "3. Update your Flutter app to use the new Cloud Functions"
    echo ""
    echo "🔗 Available Cloud Functions:"
    echo "   - sendNotification"
    echo "   - sendBulkNotifications"
    echo "   - sendEmailNotification"
    echo "   - sendNotificationWithFallback"
    echo "   - sendBookingReminders (scheduled)"
    echo "   - cleanupOldNotifications (scheduled)"
else
    echo "❌ Deployment failed. Please check the errors above."
    exit 1
fi
