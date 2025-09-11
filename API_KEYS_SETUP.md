# API Keys Setup Guide

This document explains how to securely configure API keys for the Vehicle Damage App.

## 🔐 Security Features

- ✅ API keys are stored in `local.properties` (excluded from git)
- ✅ Keys are loaded at runtime through native Android code
- ✅ No hardcoded keys in source code
- ✅ Template file provided for team members

## 🚀 Quick Setup

### 1. Copy the Template
```bash
cp android/local.properties.template android/local.properties
```

### 2. Add Your API Keys
Edit `android/local.properties` and replace the placeholder values:

```properties
# Google Maps API Key
GOOGLE_MAPS_API_KEY=your_actual_google_maps_key

# OpenAI API Key  
OPENAI_API_KEY=your_actual_openai_key
```

### 3. Get Your API Keys

#### Google Maps API Key
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing one
3. Enable Maps SDK for Android
4. Create credentials → API Key
5. Restrict the key to your app's package name

#### OpenAI API Key
1. Go to [OpenAI Platform](https://platform.openai.com/)
2. Sign up or log in
3. Navigate to [API Keys](https://platform.openai.com/api-keys)
4. Create new secret key
5. Add credits to your account

## 🔒 Security Best Practices

- **Never commit** `local.properties` to version control
- **Use different keys** for development and production
- **Restrict API keys** to specific apps/domains when possible
- **Monitor usage** regularly in your API provider dashboards
- **Rotate keys** periodically for security

## 🛠️ Development Workflow

1. **New team member joins**: Copy `local.properties.template` to `local.properties`
2. **Add their API keys**: They add their own keys to `local.properties`
3. **Build and run**: The app automatically loads keys at startup

## 📱 How It Works

1. **Build time**: Gradle reads keys from `local.properties`
2. **Runtime**: Native Android code exposes keys to Flutter
3. **Flutter**: `ApiKeyService` loads keys and initializes services
4. **Services**: OpenAI and other services use the loaded keys

## 🚨 Troubleshooting

### "No API key found" error
- Check that `local.properties` exists
- Verify the key name matches exactly: `OPENAI_API_KEY`
- Ensure no extra spaces or quotes around the key

### Build errors
- Run `flutter clean` and `flutter pub get`
- Check that `local.properties` is in the correct location
- Verify the key format is correct

### API calls failing
- Check your OpenAI account has credits
- Verify the API key is valid and active
- Check network connectivity

## 📋 Environment Variables (Alternative)

For production deployments, you can also use environment variables:

```bash
export OPENAI_API_KEY="your_key_here"
export GOOGLE_MAPS_API_KEY="your_key_here"
```

The app will automatically detect and use these if available.
