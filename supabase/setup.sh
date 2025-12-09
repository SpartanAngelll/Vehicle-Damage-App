#!/bin/bash
# Supabase CLI Setup Script

set -e

echo "🚀 Setting up Supabase with CLI..."

# Check if Supabase CLI is installed
if command -v supabase &> /dev/null; then
    echo "✅ Supabase CLI found (global)"
    SUPABASE_CMD="supabase"
elif [ -f "node_modules/.bin/supabase" ]; then
    echo "✅ Supabase CLI found (local)"
    SUPABASE_CMD="npx supabase"
else
    echo "❌ Supabase CLI not found. Installing locally..."
    npm install supabase --save-dev
    SUPABASE_CMD="npx supabase"
fi

# Link to existing project or create new
echo "📋 Linking to Supabase project..."
read -p "Enter your Supabase project reference ID (or press Enter to skip): " PROJECT_REF

if [ -n "$PROJECT_REF" ]; then
    $SUPABASE_CMD link --project-ref "$PROJECT_REF"
    echo "✅ Linked to project: $PROJECT_REF"
else
    echo "⚠️  Skipping project link. Run '$SUPABASE_CMD link' manually later."
fi

# Push migrations
echo "📤 Pushing database migrations..."
$SUPABASE_CMD db push

echo "✅ Setup complete!"
echo ""
echo "Next steps:"
echo "1. Configure JWT secret in Supabase Dashboard → Settings → API"
echo "2. Deploy Firestore rules: firebase deploy --only firestore:rules"
echo "3. Initialize Supabase in your Flutter app (see QUICK_START.md)"

