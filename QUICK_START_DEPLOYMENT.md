# Quick Start: Deploy Your Web App in 5 Minutes

This is a condensed guide to get your app live quickly. For detailed instructions, see [WEB_DEPLOYMENT_GUIDE.md](./WEB_DEPLOYMENT_GUIDE.md).

## Prerequisites Checklist

- [ ] Flutter SDK installed (`flutter --version`)
- [ ] Firebase CLI installed (`npm install -g firebase-tools`)
- [ ] Logged into Firebase (`firebase login`)
- [ ] Firebase project created and selected (`firebase use <project-id>`)

## Quick Deploy Steps

### Option 1: Automated Script (Recommended)

**Windows:**
```bash
deploy_web.bat
```

**Linux/Mac:**
```bash
chmod +x deploy_web.sh
./deploy_web.sh
```

### Option 2: Manual Commands

```bash
# 1. Get dependencies
flutter pub get

# 2. Build web app
flutter build web --release --no-tree-shake-icons

# 3. Deploy to Firebase
firebase deploy --only hosting
```

## Your App is Live! 🎉

After deployment, your app will be available at:
- `https://<your-project-id>.web.app`
- `https://<your-project-id>.firebaseapp.com`

## What's Configured

✅ **Payment workflow**: Disabled (as requested)
✅ **PIN verification**: Active and working
✅ **Job reviews**: Enabled and functional
✅ **Firebase Hosting**: Configured in `firebase.json`
✅ **Web metadata**: Updated in `web/index.html`

## Next Steps

1. **Set up custom domain** (optional):
   - Firebase Console → Hosting → Add custom domain

2. **Configure API keys**:
   - See [PRODUCTION_ENV_SETUP.md](./PRODUCTION_ENV_SETUP.md)

3. **Set up CI/CD** (optional):
   - Push to `main` branch will auto-deploy (if GitHub Actions configured)

## Troubleshooting

**Build fails?**
```bash
flutter clean
flutter pub get
flutter build web --release
```

**Deploy fails?**
```bash
firebase login --reauth
firebase use <your-project-id>
```

**Need help?** See [WEB_DEPLOYMENT_GUIDE.md](./WEB_DEPLOYMENT_GUIDE.md) for detailed troubleshooting.

---

**Ready to deploy?** Run the deployment script and your app will be live in minutes! 🚀

