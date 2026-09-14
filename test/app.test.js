const request = require('supertest');
const app = require('../src/app');

describe('DevOps CI/CD Application Smoke & Integration Tests', () => {
  test('GET / should serve the dashboard HTML with HTTP 200', async () => {
    const response = await request(app).get('/');
    expect(response.statusCode).toBe(200);
    expect(response.headers['content-type']).toMatch(/html/);
  });

  test('GET /health should return status UP and uptime', async () => {
    const response = await request(app).get('/health');
    expect(response.statusCode).toBe(200);
    expect(response.body).toHaveProperty('status', 'UP');
    expect(response.body).toHaveProperty('timestamp');
    expect(response.body).toHaveProperty('uptimeSeconds');
  });

  test('GET /api/info should return system metadata and version info', async () => {
    const response = await request(app).get('/api/info');
    expect(response.statusCode).toBe(200);
    expect(response.body).toHaveProperty('appName');
    expect(response.body).toHaveProperty('version');
    expect(response.body).toHaveProperty('memory');
    expect(response.body).toHaveProperty('platform');
  });

  test('GET /non-existent-route should return 404', async () => {
    const response = await request(app).get('/random-path-404');
    expect(response.statusCode).toBe(404);
    expect(response.body).toHaveProperty('error', 'Endpoint not found');
  });
});
