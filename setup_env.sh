#!/bin/bash
# Bash script to create .env file with Supabase credentials
# Run this script: chmod +x setup_env.sh && ./setup_env.sh

cat > .env << 'EOF'
# API Keys Configuration
# DO NOT commit this file to version control

# Google Maps API Key
GOOGLE_MAPS_API_KEY=your_google_maps_api_key_here

# OpenAI API Key
OPENAI_API_KEY=your_openai_api_key_here

# Firebase Configuration (if needed)
FIREBASE_PROJECT_ID=your_project_id
FIREBASE_API_KEY=your_firebase_api_key

# Database Configuration
# For local PostgreSQL:
# POSTGRES_HOST=localhost
# POSTGRES_PORT=5432
# POSTGRES_USER=postgres
# POSTGRES_PASSWORD=your_postgres_password
# POSTGRES_DB=vehicle_damage_payments
# POSTGRES_SSL=false

# For Supabase (Cloud PostgreSQL):
POSTGRES_HOST=db.xxxxx.supabase.co
POSTGRES_PORT=5432
POSTGRES_USER=postgres
POSTGRES_PASSWORD=your_supabase_password_here
POSTGRES_DB=postgres
POSTGRES_SSL=true
# POSTGRES_SSL_REJECT_UNAUTHORIZED=true  # Set to false if you have SSL certificate issues

# Supabase Configuration (for Flutter app)
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your_supabase_anon_key_here
EOF

echo "✅ .env file created successfully!"
echo ""
echo "Supabase credentials configured:"
echo "  SUPABASE_URL: [configured]"
echo "  SUPABASE_ANON_KEY: [configured]"
echo ""
echo "⚠️  IMPORTANT: Replace placeholder values with your actual Supabase credentials"
echo ""
echo "⚠️  Remember: .env is in .gitignore and will NOT be committed to git"

