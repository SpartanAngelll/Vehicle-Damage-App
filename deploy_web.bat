@echo off
REM Web Deployment Script for Multi-Service Professional Network
REM This script builds and deploys the Flutter web app to Firebase Hosting

echo.
echo 🚀 Starting web deployment process...
echo.

REM Step 1: Check Flutter installation
echo 📋 Step 1: Checking Flutter installation...
where flutter >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ❌ Flutter is not installed. Please install Flutter first.
    exit /b 1
)
echo ✅ Flutter is installed
flutter --version
echo.

REM Step 2: Check Firebase CLI
echo 📋 Step 2: Checking Firebase CLI...
where firebase >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ⚠️  Firebase CLI is not installed. Installing...
    npm install -g firebase-tools
)
echo ✅ Firebase CLI is installed
firebase --version
echo.

REM Step 3: Get Flutter dependencies
echo 📋 Step 3: Getting Flutter dependencies...
flutter pub get
if %ERRORLEVEL% NEQ 0 (
    echo ❌ Failed to get dependencies
    exit /b 1
)
echo ✅ Dependencies retrieved
echo.

REM Step 4: Clean previous build
echo 📋 Step 4: Cleaning previous build...
flutter clean
echo ✅ Clean complete
echo.

REM Step 5: Build web app
echo 📋 Step 5: Building Flutter web app for production...
echo This may take a few minutes...
flutter build web --release --no-tree-shake-icons
if %ERRORLEVEL% NEQ 0 (
    echo ❌ Build failed
    exit /b 1
)

if not exist "build\web\index.html" (
    echo ❌ Build failed. build\web\index.html not found.
    exit /b 1
)
echo ✅ Web build complete
echo.

REM Step 6: Deploy to Firebase
echo 📋 Step 6: Deploying to Firebase Hosting...
set /p DEPLOY="Do you want to deploy to Firebase? (y/n): "
if /i "%DEPLOY%"=="y" (
    firebase deploy --only hosting
    echo.
    echo ✅ Deployment complete!
    echo 🌐 Your app is live at the Firebase Hosting URL shown above
) else (
    echo ⚠️  Deployment skipped
)
echo.

REM Step 7: Optional - Deploy Functions
echo 📋 Step 7: Deploy Firebase Functions?
set /p DEPLOY_FUNCTIONS="Do you want to deploy Firebase Functions? (y/n): "
if /i "%DEPLOY_FUNCTIONS%"=="y" (
    echo Deploying functions...
    firebase deploy --only functions
    echo ✅ Functions deployed
) else (
    echo ⚠️  Functions deployment skipped
)
echo.

echo 🎉 Deployment process complete!

