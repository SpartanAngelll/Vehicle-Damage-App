# Mobile Device Connection Guide

## Problem
When running the app on a physical Android/iOS device, it can't connect to `localhost:3000` because `localhost` on the device refers to the device itself, not your development machine.

## Solution

### Step 1: Find Your Computer's IP Address

**On Windows:**
1. Open Command Prompt or PowerShell
2. Run: `ipconfig`
3. Look for "IPv4 Address" under your active network adapter (usually Wi-Fi or Ethernet)
4. It will look like: `192.168.x.x` or `10.x.x.x`

**On Mac/Linux:**
1. Open Terminal
2. Run: `ifconfig` or `ip addr`
3. Look for your network interface (usually `en0` for Wi-Fi or `eth0` for Ethernet)
4. Find the `inet` address (e.g., `192.168.x.x`)

### Step 2: Update the IP Address in Code

The code currently uses `192.168.0.53` as a default. You need to update it to match your computer's IP address.

**Files to update:**
- `lib/services/service_package_service.dart` (line ~28)
- `lib/services/api_service.dart` (line ~28)
- `lib/services/postgres_booking_service.dart` (line ~28)

Replace `192.168.0.53` with your actual IP address in all three files.

### Step 3: Ensure Backend Server is Running

Make sure your backend server is running and accessible:

```bash
cd backend
node server.js
```

The server should start on port 3000.

### Step 4: Check Firewall Settings

**On Windows:**
1. Open Windows Defender Firewall
2. Allow Node.js through the firewall if prompted
3. Or temporarily disable firewall for testing

**On Mac:**
1. System Preferences → Security & Privacy → Firewall
2. Allow Node.js if prompted

### Step 5: Verify Connection

1. Make sure your phone and computer are on the same Wi-Fi network
2. Test the connection by opening a browser on your phone and navigating to:
   ```
   http://YOUR_IP_ADDRESS:3000/api/health
   ```
   You should see: `{"status":"OK","timestamp":"..."}`

### Alternative: Use Android Emulator

If you're using an Android emulator, the code automatically uses `10.0.2.2` which maps to `localhost` on your development machine. No IP address changes needed!

### Quick Test

After updating the IP address, try creating a service package again. The connection should work now.

## Troubleshooting

**Still getting connection refused?**
1. Double-check the IP address is correct
2. Make sure both devices are on the same network
3. Verify the backend server is running
4. Check if port 3000 is blocked by firewall
5. Try pinging your computer's IP from the phone

**Connection works but slow?**
- This is normal for development. In production, use a proper backend URL.

## Production Setup

For production, update the base URL in:
- `lib/services/service_package_service.dart`
- `lib/services/api_service.dart`

Change from:
```dart
return 'https://your-backend-api.com/api';
```

To your actual production API URL.


