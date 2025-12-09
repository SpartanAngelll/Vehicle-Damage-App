# Environment Variables Setup

This project uses `.env` files to securely store sensitive configuration like API keys and credentials.

## Setup Instructions

### 1. Create `.env` File

Copy the example file and fill in your values:

```bash
# On Windows (PowerShell)
Copy-Item .env.example .env

# On Linux/macOS
cp .env.example .env
```

### 2. Fill in Your Values

Edit `.env` and replace the placeholder values:

```env
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your_actual_anon_key_here
```

### 3. Get Your Supabase Credentials

1. Go to [Supabase Dashboard](https://supabase.com/dashboard)
2. Select your project
3. Go to **Settings** → **API**
4. Copy:
   - **Project URL** → `SUPABASE_URL`
   - **anon public** key → `SUPABASE_ANON_KEY`

### 4. Verify Setup

After creating `.env`, run:

```bash
flutter pub get
flutter run
```

The app should load the credentials from `.env` automatically.

## Security Notes

✅ **DO:**
- Keep `.env` in `.gitignore` (already configured)
- Use `.env.example` as a template for team members
- Never commit `.env` to version control
- Use different `.env` files for different environments (dev, staging, production)

❌ **DON'T:**
- Commit `.env` files
- Share `.env` files in chat/email
- Hardcode secrets in source code
- Use production keys in development

## File Structure

```
vehicle_damage_app/
├── .env                    # Your actual credentials (NOT in git)
├── .env.example            # Template file (safe to commit)
└── lib/
    └── main.dart           # Loads from .env
```

## Troubleshooting

### Error: "Failed to load .env file"

- Make sure `.env` exists in the project root (same level as `pubspec.yaml`)
- Check that `flutter_dotenv` is in `pubspec.yaml` dependencies
- Verify `.env` is listed in `pubspec.yaml` assets section

### Error: "SUPABASE_ANON_KEY not found"

- Check that `SUPABASE_ANON_KEY=` line exists in `.env`
- Make sure there are no spaces around the `=` sign
- Verify the key value is on the same line (no line breaks)

### Environment Variables Not Loading

- Run `flutter clean` and `flutter pub get`
- Restart your IDE/editor
- Check file encoding (should be UTF-8)

## Adding More Environment Variables

To add more environment variables:

1. Add to `.env`:
   ```env
   MY_NEW_KEY=my_value
   ```

2. Add to `.env.example`:
   ```env
   MY_NEW_KEY=your_value_here
   ```

3. Use in code:
   ```dart
   final myValue = dotenv.env['MY_NEW_KEY'] ?? 'default_value';
   ```

## Production Deployment

For production builds, you may want to:

1. Use build-time environment variables
2. Use a secrets management service (AWS Secrets Manager, etc.)
3. Use CI/CD environment variables
4. Never commit production `.env` files

See your deployment platform's documentation for best practices.

