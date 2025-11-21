#!/usr/bin/env node
/**
 * Generate firebase-config.js for service worker
 * This script reads Firebase config from environment variables or firebase_options.dart
 * and generates the web/firebase-config.js file
 */

const fs = require('fs');
const path = require('path');

// Read config from environment variables or use defaults
const config = {
  apiKey: process.env.FIREBASE_API_KEY || '',
  appId: process.env.FIREBASE_APP_ID || '',
  messagingSenderId: process.env.FIREBASE_MESSAGING_SENDER_ID || '',
  projectId: process.env.FIREBASE_PROJECT_ID || 'vehicle-damage-app',
  authDomain: process.env.FIREBASE_AUTH_DOMAIN || 'vehicle-damage-app.firebaseapp.com',
  storageBucket: process.env.FIREBASE_STORAGE_BUCKET || 'vehicle-damage-app.firebasestorage.app',
  measurementId: process.env.FIREBASE_MEASUREMENT_ID || '',
};

// Generate the config file content
const configFileContent = `// Firebase Configuration for Service Worker
// This file is auto-generated - DO NOT edit manually
// Generated at: ${new Date().toISOString()}

self.firebaseConfig = ${JSON.stringify(config, null, 2)};
`;

// Write to web/firebase-config.js
const outputPath = path.join(__dirname, '..', 'web', 'firebase-config.js');
fs.writeFileSync(outputPath, configFileContent, 'utf8');

console.log('✅ Generated firebase-config.js');
console.log(`📁 Location: ${outputPath}`);

