// Node.js server for Daily Routine PWA
// Install with: npm install express
// Run with: node server.js

const express = require('express');
const path = require('path');
const app = express();
const PORT = process.env.PORT || 8000;

// Serve static files
app.use(express.static('.'));

// PWA-specific headers
app.use((req, res, next) => {
    // Set PWA headers
    res.setHeader('Service-Worker-Allowed', '/');
    
    // CORS headers for development
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
    
    // Cache control
    if (req.url.includes('sw.js') || req.url.includes('manifest.json')) {
        res.setHeader('Cache-Control', 'no-cache, no-store, must-revalidate');
    }
    
    next();
});

// Serve manifest with correct MIME type
app.get('/manifest.json', (req, res) => {
    res.setHeader('Content-Type', 'application/manifest+json');
    res.sendFile(path.join(__dirname, 'manifest.json'));
});

// Serve service worker
app.get('/sw.js', (req, res) => {
    res.setHeader('Content-Type', 'application/javascript');
    res.sendFile(path.join(__dirname, 'sw.js'));
});

// Serve index.html for all routes (SPA)
app.get('*', (req, res) => {
    res.sendFile(path.join(__dirname, 'index.html'));
});

app.listen(PORT, () => {
    console.log(`🚀 Daily Routine PWA Server`);
    console.log(`📱 Open in browser: http://localhost:${PORT}`);
    console.log(`📲 On mobile: http://[your-ip]:${PORT}`);
    console.log(`🛑 Press Ctrl+C to stop`);
    console.log(``);
    console.log(`📋 Features available:`);
    console.log(`   ✅ Box Breathing (4-7 seconds configurable)`);
    console.log(`   ✅ 4-7-8 Breathing`);
    console.log(`   ✅ Audio cues every X seconds`);
    console.log(`   ✅ Haptic feedback`);
    console.log(`   ✅ Offline functionality`);
    console.log(`   ✅ Install as PWA`);
    console.log(``);
});