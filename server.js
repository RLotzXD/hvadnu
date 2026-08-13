const express = require('express');
const path = require('path');
const fs = require('fs');

const app = express();
const PORT = process.env.PORT || 3000;

// Expose API configuration (environment variables)
app.get('/api/config', (req, res) => {
  res.json({
    GEMINI_API_KEY: process.env.GEMINI_API_KEY || '',
    ELEVENLABS_API_KEY: process.env.ELEVENLABS_API_KEY || '',
  });
});

// Middleware to inject API keys into HTML
app.use((req, res, next) => {
  const originalSend = res.send;
  res.send = function (data) {
    if (typeof data === 'string' && data.includes('<!DOCTYPE html>')) {
      // JSON.stringify rather than quoted interpolation: a key containing a
      // quote would otherwise emit broken JavaScript.
      const config = JSON.stringify({
        GEMINI_API_KEY: process.env.GEMINI_API_KEY || '',
        ELEVENLABS_API_KEY: process.env.ELEVENLABS_API_KEY || '',
      });
      const injected = data.replace(
        '</head>',
        `<script>window.apiConfig = ${config};</script></head>`
      );
      return originalSend.call(this, injected);
    }
    return originalSend.apply(this, arguments);
  };
  next();
});

// Serve static files from public directory
app.use(express.static(path.join(__dirname, 'public')));

// SPA fallback - serve index.html for all routes
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
