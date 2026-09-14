const app = require('./app');

const PORT = process.env.PORT || 3000;

const server = app.listen(PORT, '0.0.0.0', () => {
  console.log('====================================================');
  console.log(`🚀 DevOps CI/CD Demo App running on port ${PORT}`);
  console.log(`🌐 Health check available at: http://localhost:${PORT}/health`);
  console.log(`📊 System info available at:   http://localhost:${PORT}/api/info`);
  console.log(`🌱 Environment:               ${process.env.NODE_ENV || 'production'}`);
  console.log(`🏷️  App Version:               ${process.env.APP_VERSION || '1.0.0'}`);
  console.log('====================================================');
});

// Graceful shutdown handling for Docker container stops (SIGTERM / SIGINT)
const gracefulShutdown = (signal) => {
  console.log(`Received ${signal}. Shutting down gracefully...`);
  server.close(() => {
    console.log('Closed out remaining connections.');
    process.exit(0);
  });

  // Force shutdown after 10 seconds if not closed
  setTimeout(() => {
    console.error('Could not close connections in time, forcefully shutting down');
    process.exit(1);
  }, 10000);
};

process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
process.on('SIGINT', () => gracefulShutdown('SIGINT'));
