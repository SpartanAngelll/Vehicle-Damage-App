#!/bin/bash
# Bash script to run Flutter app with Supabase environment variables
# Usage: ./run_flutter_supabase.sh

echo "🚀 Starting Flutter app with Supabase configuration..."

# Set Supabase environment variables
# IMPORTANT: Replace these with your actual Supabase credentials from .env file
export POSTGRES_HOST="${POSTGRES_HOST:-db.your-project-id.supabase.co}"
export POSTGRES_PORT="${POSTGRES_PORT:-5432}"
export POSTGRES_USER="${POSTGRES_USER:-postgres}"
export POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-your_supabase_password_here}"
export POSTGRES_DB="${POSTGRES_DB:-postgres}"
export POSTGRES_SSL="${POSTGRES_SSL:-true}"

if [ "$POSTGRES_PASSWORD" = "your_supabase_password_here" ]; then
    echo "⚠️  WARNING: Using placeholder password. Set POSTGRES_PASSWORD environment variable or update this script."
fi

echo "✅ Environment variables set:"
echo "   POSTGRES_HOST: $POSTGRES_HOST"
echo "   POSTGRES_DB: $POSTGRES_DB"
echo "   POSTGRES_SSL: $POSTGRES_SSL"
echo ""

# Run Flutter app
echo "📱 Starting Flutter app..."
flutter run

