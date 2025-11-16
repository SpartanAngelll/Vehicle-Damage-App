#!/bin/bash
# Web Deployment Script for Multi-Service Professional Network
# This script builds and deploys the Flutter web app to Firebase Hosting

set -e  # Exit on error

echo "🚀 Starting web deployment process..."
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Step 1: Check Flutter installation
echo -e "${BLUE}📋 Step 1: Checking Flutter installation...${NC}"
if ! command -v flutter &> /dev/null; then
    echo -e "${YELLOW}❌ Flutter is not installed. Please install Flutter first.${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Flutter is installed${NC}"
flutter --version
echo ""

# Step 2: Check Firebase CLI
echo -e "${BLUE}📋 Step 2: Checking Firebase CLI...${NC}"
if ! command -v firebase &> /dev/null; then
    echo -e "${YELLOW}⚠️  Firebase CLI is not installed. Installing...${NC}"
    npm install -g firebase-tools
fi
echo -e "${GREEN}✅ Firebase CLI is installed${NC}"
firebase --version
echo ""

# Step 3: Check if logged in to Firebase
echo -e "${BLUE}📋 Step 3: Checking Firebase authentication...${NC}"
if ! firebase projects:list &> /dev/null; then
    echo -e "${YELLOW}⚠️  Not logged in to Firebase. Please log in...${NC}"
    firebase login
fi
echo -e "${GREEN}✅ Firebase authentication verified${NC}"
echo ""

# Step 4: Get Flutter dependencies
echo -e "${BLUE}📋 Step 4: Getting Flutter dependencies...${NC}"
flutter pub get
echo -e "${GREEN}✅ Dependencies retrieved${NC}"
echo ""

# Step 5: Clean previous build
echo -e "${BLUE}📋 Step 5: Cleaning previous build...${NC}"
flutter clean
echo -e "${GREEN}✅ Clean complete${NC}"
echo ""

# Step 6: Build web app
echo -e "${BLUE}📋 Step 6: Building Flutter web app for production...${NC}"
echo -e "${YELLOW}This may take a few minutes...${NC}"
flutter build web --release --no-tree-shake-icons

if [ ! -d "build/web" ]; then
    echo -e "${YELLOW}❌ Build failed. build/web directory not found.${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Web build complete${NC}"
echo ""

# Step 7: Verify build output
echo -e "${BLUE}📋 Step 7: Verifying build output...${NC}"
if [ -f "build/web/index.html" ]; then
    echo -e "${GREEN}✅ index.html found${NC}"
else
    echo -e "${YELLOW}❌ index.html not found in build/web${NC}"
    exit 1
fi
echo ""

# Step 8: Deploy to Firebase
echo -e "${BLUE}📋 Step 8: Deploying to Firebase Hosting...${NC}"
read -p "Do you want to deploy to Firebase? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    firebase deploy --only hosting
    
    # Get the project ID
    PROJECT_ID=$(firebase use 2>&1 | grep "Using" | awk '{print $2}')
    
    echo ""
    echo -e "${GREEN}✅ Deployment complete!${NC}"
    echo -e "${GREEN}🌐 Your app is live at:${NC}"
    echo -e "${GREEN}   https://${PROJECT_ID}.web.app${NC}"
    echo -e "${GREEN}   https://${PROJECT_ID}.firebaseapp.com${NC}"
else
    echo -e "${YELLOW}⚠️  Deployment skipped${NC}"
fi
echo ""

# Step 9: Optional - Deploy Functions
echo -e "${BLUE}📋 Step 9: Deploy Firebase Functions?${NC}"
read -p "Do you want to deploy Firebase Functions? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${BLUE}Deploying functions...${NC}"
    firebase deploy --only functions
    echo -e "${GREEN}✅ Functions deployed${NC}"
else
    echo -e "${YELLOW}⚠️  Functions deployment skipped${NC}"
fi
echo ""

echo -e "${GREEN}🎉 Deployment process complete!${NC}"

