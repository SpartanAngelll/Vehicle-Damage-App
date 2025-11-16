#!/bin/bash
# Bash script to configure CORS for Firebase Storage
# This script uses gsutil (Google Cloud SDK) to set CORS configuration

echo "🔧 Setting up CORS for Firebase Storage..."

# Check if gsutil is installed
if ! command -v gsutil &> /dev/null; then
    echo "❌ gsutil is not installed or not in PATH"
    echo "📦 Please install Google Cloud SDK:"
    echo "   https://cloud.google.com/sdk/docs/install"
    echo ""
    echo "After installation, run:"
    echo "  gcloud auth login"
    echo "  gcloud config set project YOUR_PROJECT_ID"
    exit 1
fi

# Get Firebase project ID
echo "📋 Checking Firebase project configuration..."
if [ ! -f ".firebaserc" ]; then
    echo "❌ .firebaserc not found!"
    exit 1
fi

PROJECT_ID=$(grep -o '"default": "[^"]*"' .firebaserc | cut -d'"' -f4)

if [ -z "$PROJECT_ID" ]; then
    echo "❌ Could not find project ID in .firebaserc"
    echo "💡 Please set your project ID manually:"
    echo "   gsutil cors set cors.json gs://YOUR_PROJECT_ID.appspot.com"
    exit 1
fi

echo "✅ Found project ID: $PROJECT_ID"

# Check if cors.json exists
if [ ! -f "cors.json" ]; then
    echo "❌ cors.json not found!"
    echo "💡 Creating cors.json..."
    
    cat > cors.json << 'EOF'
[
  {
    "origin": ["*"],
    "method": ["GET", "HEAD", "OPTIONS"],
    "responseHeader": [
      "Content-Type",
      "Access-Control-Allow-Origin",
      "Access-Control-Allow-Methods",
      "Access-Control-Allow-Headers"
    ],
    "maxAgeSeconds": 3600
  }
]
EOF
    echo "✅ Created cors.json"
fi

# Apply CORS configuration
echo ""
echo "🚀 Applying CORS configuration to Firebase Storage..."
echo "   Bucket: gs://${PROJECT_ID}.appspot.com"

BUCKET="gs://${PROJECT_ID}.appspot.com"

if gsutil cors set cors.json "$BUCKET"; then
    echo ""
    echo "✅ CORS configuration applied successfully!"
    echo ""
    echo "📝 Verifying CORS configuration..."
    gsutil cors get "$BUCKET"
    echo ""
    echo "🎉 Done! Images should now load properly on web."
else
    echo ""
    echo "❌ Failed to apply CORS configuration"
    echo "💡 Make sure you're authenticated:"
    echo "   gcloud auth login"
    echo "   gcloud config set project $PROJECT_ID"
    exit 1
fi

