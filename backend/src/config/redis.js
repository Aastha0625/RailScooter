const Redis = require('ioredis');

let redis;

function getRedis() {
  if (!redis) {
    redis = new Redis(process.env.REDIS_URL || 'redis://localhost:6379', {
      lazyConnect: true,
      maxRetriesPerRequest: 3,
      enableOfflineQueue: false,
      retryStrategy: (times) => {
        // Reconnect every 3 seconds indefinitely
        return 3000;
      },
    });

    redis.on('error', (err) => {
      // Log but don't crash — Redis is used for caching, not core data
      console.warn('[Redis] Connection error:', err.message);
    });

    redis.on('connect', () => {
      console.log('[Redis] Connected');
    });
  }
  return redis;
}

const CACHE_TTL = {
  VEHICLES: 30,        // 30 seconds for vehicle list
  TRACKING: 5,         // 5 seconds for real-time tracking
  DEPARTMENTS: 300,    // 5 minutes for departments
  STATS: 60,           // 1 minute for dashboard stats
};

module.exports = { getRedis, CACHE_TTL };
