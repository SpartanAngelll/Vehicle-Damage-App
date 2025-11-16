@echo off
REM Deploy Cloud Functions for Vehicle Damage App
REM This script deploys the Cloud Functions with proper configuration

echo 🚀 Starting Cloud Functions deployment...

REM Check if Firebase CLI is installed
firebase --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Firebase CLI is not installed. Please install it first:
    echo npm install -g firebase-tools
    pause
    exit /b 1
)

REM Check if user is logged in
firebase projects:list >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Please login to Firebase first:
    echo firebase login
    pause
    exit /b 1
)

REM Navigate to functions directory
cd backend\functions

echo 📦 Installing dependencies...
call npm install

echo 🔧 Linting code...
call npm run lint

echo 🚀 Deploying Cloud Functions...
call firebase deploy --only functions

if %errorlevel% equ 0 (
    echo ✅ Cloud Functions deployed successfully!
    echo.
    echo 📋 Next steps:
    echo 1. Configure SendGrid API key:
    echo    firebase functions:config:set sendgrid.api_key="YOUR_SENDGRID_API_KEY"
    echo.
    echo 2. Set up the database schema:
    echo    psql -d vehicle_damage_payments -f ..\database\complete_schema.sql
    echo.
    echo 3. Update your Flutter app to use the new Cloud Functions
    echo.
    echo 🔗 Available Cloud Functions:
    echo    - sendNotification
    echo    - sendBulkNotifications
    echo    - sendEmailNotification
    echo    - sendNotificationWithFallback
    echo    - sendBookingReminders (scheduled)
    echo    - cleanupOldNotifications (scheduled)
) else (
    echo ❌ Deployment failed. Please check the errors above.
    pause
    exit /b 1
)

pause
