#!/bin/bash
# Get Supabase Credentials Script
# This script helps retrieve Supabase credentials using the Supabase CLI

PROJECT_ID="${1:-rodzemxwopecqpazkjyk}"

echo "🔍 Retrieving Supabase Credentials..."
echo ""

# Check if Supabase CLI is installed
if ! command -v supabase &> /dev/null; then
    echo "❌ Supabase CLI not found. Please install it first:"
    echo "   npm install -g supabase"
    exit 1
fi

# Check if logged in
echo "Checking Supabase CLI login status..."
if supabase projects list &> /dev/null; then
    echo "✅ Logged in to Supabase CLI"
else
    echo "⚠️  Not logged in to Supabase CLI"
    echo ""
    echo "Please login first:"
    echo "   supabase login"
    echo ""
    echo "Then link your project:"
    echo "   supabase link --project-ref $PROJECT_ID"
    exit 1
fi

echo ""
echo "Project Information:"
echo "   Project ID: $PROJECT_ID"
echo "   Project URL: https://$PROJECT_ID.supabase.co"
echo ""

# Get API keys from Supabase Dashboard
echo "📋 To get your API keys:"
echo "   1. Go to: https://supabase.com/dashboard/project/$PROJECT_ID/settings/api"
echo "   2. Copy the following keys:"
echo "      - anon public (for client-side)"
echo "      - service_role (for server-side, keep secret!)"
echo ""

# Try to get project status
echo "Checking project status..."
if supabase projects api-keys --project-ref "$PROJECT_ID" &> /dev/null; then
    echo "✅ Project API keys retrieved:"
    supabase projects api-keys --project-ref "$PROJECT_ID"
else
    echo "⚠️  Could not retrieve API keys via CLI"
    echo "   Please get them from the Supabase Dashboard (link above)"
fi

echo ""
echo "💡 Tip: You can also use the complete_setup.sh script to automatically"
echo "   configure your Flutter app with these credentials."
echo ""

