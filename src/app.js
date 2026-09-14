const express = require('express');
const path = require('path');
const os = require('os');

const app = express();

// Application start time for uptime calculation
const startTime = Date.now();

// Middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(express.static(path.join(__dirname, 'public')));

// API: Health Check Endpoint (essential for CI/CD smoke tests & AWS Load Balancers)
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'UP',
    timestamp: new Date().toISOString(),
    uptimeSeconds: Math.floor((Date.now() - startTime) / 1000)
  });
});

// API: System & Environment Info
app.get('/api/info', (req, res) => {
  const totalMemMb = Math.round(os.totalmem() / (1024 * 1024));
  const freeMemMb = Math.round(os.freemem() / (1024 * 1024));
  const usedMemMb = totalMemMb - freeMemMb;

  res.status(200).json({
    appName: 'DevOps CI/CD Demo Application',
    version: process.env.APP_VERSION || '1.0.0',
    environment: process.env.NODE_ENV || 'production',
    hostname: os.hostname(),
    platform: `${os.platform()} (${os.arch()})`,
    nodeVersion: process.version,
    memory: {
      total: `${totalMemMb} MB`,
      used: `${usedMemMb} MB`,
      free: `${freeMemMb} MB`
    },
    uptimeSeconds: Math.floor((Date.now() - startTime) / 1000),
    deployedVia: 'Jenkins CI/CD Pipeline on AWS EC2'
  });
});

// Serve frontend dashboard on root
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({ error: 'Endpoint not found' });
});

module.exports = app;
