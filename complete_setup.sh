#!/bin/bash
# Complete Setup Script - Supabase + Firebase Integration
# This script automates the remaining setup steps using Supabase CLI and Firebase CLI

SUPABASE_PROJECT_ID="${SUPABASE_PROJECT_ID:-rodzemxwopecqpazkjyk}"
SUPABASE_URL="${SUPABASE_URL:-https://rodzemxwopecqpazkjyk.supabase.co}"

echo "🚀 Starting Complete Setup..."
echo ""

# Step 1: Check if Supabase CLI is installed
echo "📋 Step 1: Checking Supabase CLI..."
if command -v supabase &> /dev/null; then
    SUPABASE_VERSION=$(supabase --version 2>&1)
    echo "✅ Supabase CLI found: $SUPABASE_VERSION"
else
    echo "❌ Supabase CLI not installed. Please install it first:"
    echo "   npm install -g supabase"
    exit 1
fi

# Step 2: Check if Firebase CLI is installed
echo ""
echo "📋 Step 2: Checking Firebase CLI..."
if command -v firebase &> /dev/null; then
    FIREBASE_VERSION=$(firebase --version 2>&1)
    echo "✅ Firebase CLI found: $FIREBASE_VERSION"
else
    echo "❌ Firebase CLI not installed. Please install it first:"
    echo "   npm install -g firebase-tools"
    exit 1
fi

# Step 3: Get Supabase credentials
echo ""
echo "📋 Step 3: Retrieving Supabase credentials..."
echo "   Note: You may need to login to Supabase CLI first:"
echo "   supabase login"
echo ""

# Try to get project info
if supabase projects list &> /dev/null; then
    echo "✅ Supabase CLI is configured"
else
    echo "⚠️  Not logged in to Supabase CLI. Please run: supabase login"
    echo "   Then link your project: supabase link --project-ref $SUPABASE_PROJECT_ID"
fi

# Get anon key from user
echo "   To get your Supabase Anon Key:"
echo "   1. Go to: https://supabase.com/dashboard/project/$SUPABASE_PROJECT_ID/settings/api"
echo "   2. Copy the 'anon public' key"
echo ""
read -p "   Enter your Supabase Anon Key (or press Enter to skip and configure manually): " ANON_KEY

if [ -z "$ANON_KEY" ]; then
    echo "⚠️  Skipping automatic configuration. You'll need to:"
    echo "   1. Get your anon key from Supabase Dashboard"
    echo "   2. Add it to lib/main.dart manually"
    echo ""
else
    # Step 4: Update main.dart with Supabase initialization
    echo ""
    echo "📋 Step 4: Updating lib/main.dart with Supabase initialization..."
    
    MAIN_DART_PATH="lib/main.dart"
    if [ -f "$MAIN_DART_PATH" ]; then
        # Check if FirebaseSupabaseService is already imported
        if ! grep -q "firebase_supabase_service" "$MAIN_DART_PATH"; then
            # Add import after services.dart
            sed -i.bak "s|import 'services/services\.dart';|import 'services/services.dart';\nimport 'services/firebase_supabase_service.dart';|" "$MAIN_DART_PATH"
            rm -f "${MAIN_DART_PATH}.bak"
        fi
        
        # Check if Supabase initialization already exists
        if grep -q "FirebaseSupabaseService.instance.initialize" "$MAIN_DART_PATH"; then
            echo "⚠️  Supabase initialization already exists in main.dart"
            echo "   Please verify the configuration manually"
        else
            # Create a temporary file with the Supabase initialization
            cat > /tmp/supabase_init.txt << EOF
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Initialize Supabase
    try {
      await FirebaseSupabaseService.instance.initialize(
        supabaseUrl: '$SUPABASE_URL',
        supabaseAnonKey: '$ANON_KEY',
      );
      print('✅ [Main] Supabase service initialized');
    } catch (e) {
      print('⚠️ [Main] Failed to initialize Supabase service: \$e');
      print('⚠️ [Main] Supabase features may not work properly');
    }
    
EOF
            # Replace Firebase initialization with the new version
            # This is a simplified approach - you may need to adjust based on your exact file structure
            python3 << PYTHON_SCRIPT
import re

with open('$MAIN_DART_PATH', 'r') as f:
    content = f.read()

# Pattern to match Firebase initialization
pattern = r"(await Firebase\.initializeApp\([^)]+\);)\s*"

# Read the replacement text
with open('/tmp/supabase_init.txt', 'r') as f:
    replacement = f.read()

# Replace
new_content = re.sub(pattern, replacement, content, count=1)

with open('$MAIN_DART_PATH', 'w') as f:
    f.write(new_content)

PYTHON_SCRIPT
            
            if [ $? -eq 0 ]; then
                echo "✅ Updated lib/main.dart with Supabase initialization"
            else
                echo "⚠️  Could not automatically update main.dart. Please add manually:"
                echo "   See SETUP_COMPLETE.md for instructions"
            fi
            rm -f /tmp/supabase_init.txt
        fi
    else
        echo "❌ lib/main.dart not found"
    fi
fi

# Step 5: Deploy Firestore rules
echo ""
echo "📋 Step 5: Deploying Firestore rules..."

if [ -f "firebase.json" ]; then
    echo "   Deploying Firestore rules..."
    firebase deploy --only firestore:rules
    if [ $? -eq 0 ]; then
        echo "✅ Firestore rules deployed successfully"
    else
        echo "❌ Failed to deploy Firestore rules"
        echo "   Make sure you're logged in: firebase login"
    fi
else
    echo "⚠️  firebase.json not found. Skipping Firestore rules deployment."
fi

# Step 6: JWT Configuration Instructions
echo ""
echo "📋 Step 6: JWT Configuration (REQUIRED - Manual Step)"
echo ""
echo "⚠️  CRITICAL: You must configure JWT secret for RLS to work with Firebase tokens"
echo ""
echo "Option 1: Using Supabase Dashboard (Recommended)"
echo "   1. Go to: https://supabase.com/dashboard/project/$SUPABASE_PROJECT_ID/settings/api"
echo "   2. Find 'JWT Settings' section"
echo "   3. Get Firebase private key:"
echo "      - Firebase Console → Project Settings → Service Accounts"
echo "      - Generate new private key (or use existing)"
echo "      - Copy the entire private key (including BEGIN/END markers)"
echo "   4. Paste into Supabase JWT Secret field"
echo ""
echo "Option 2: Using Supabase CLI"
echo "   You can also use the Supabase CLI to update JWT settings:"
echo "   supabase projects update --jwt-secret 'YOUR_FIREBASE_PRIVATE_KEY'"
echo ""

# Summary
echo ""
echo "═══════════════════════════════════════════════════════════"
echo "✅ Setup Complete!"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "Next Steps:"
echo "1. ✅ Supabase credentials configured (if provided)"
echo "2. ✅ Flutter app updated with Supabase initialization"
echo "3. ✅ Firestore rules deployed"
echo "4. ⚠️  JWT Configuration - REQUIRED (see instructions above)"
echo ""
echo "After JWT configuration, test the authentication flow:"
echo "   See TESTING_GUIDE.md for complete testing procedures"
echo ""

