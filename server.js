const express = require('express');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;

// Expose API configuration (environment variables)
app.get('/api/config', (req, res) => {
  res.json({
    GEMINI_API_KEY: process.env.GEMINI_API_KEY || '',
    ELEVENLABS_API_KEY: process.env.ELEVENLABS_API_KEY || '',
  });
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
