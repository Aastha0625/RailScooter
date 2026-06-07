require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const http = require('http');
const WebSocket = require('ws');

const vehicleRoutes = require('./routes/vehicles');
const departmentRoutes = require('./routes/departments');
const userRoutes = require('./routes/users');
const assignmentRoutes = require('./routes/assignments');
const alertRoutes = require('./routes/alerts');
const trackingRoutes = require('./routes/tracking');
const statsRoutes = require('./routes/stats');
const { authenticate } = require('./middleware');

const app = express();
const server = http.createServer(app);

// WebSocket server for real-time tracking pushes
const wss = new WebSocket.Server({ server, path: '/ws' });

wss.on('connection', (ws) => {
  console.log('[WS] Client connected');
  ws.on('close', () => console.log('[WS] Client disconnected'));
});

// Broadcast tracking updates to all connected WebSocket clients
global.broadcastTracking = (data) => {
  const msg = JSON.stringify({ type: 'tracking_update', data });
  wss.clients.forEach((client) => {
    if (client.readyState === WebSocket.OPEN) {
      client.send(msg);
    }
  });
};

app.use(helmet());
app.use(cors({ origin: '*' }));
app.use(morgan('combined'));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

app.get('/health', (req, res) => res.json({ status: 'ok', service: 'PiScoot API', timestamp: new Date() }));

app.use('/api', authenticate);
app.use('/api/vehicles', vehicleRoutes);
app.use('/api/departments', departmentRoutes);
app.use('/api/users', userRoutes);
app.use('/api/assignments', assignmentRoutes);
app.use('/api/alerts', alertRoutes);
app.use('/api/tracking', trackingRoutes);
app.use('/api/stats', statsRoutes);

app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ error: 'Internal Server Error' });
});

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
  console.log(`[PiScoot API] Running on port ${PORT}`);
});

module.exports = { app, server };
