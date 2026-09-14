# ==========================================
# Stage 1: Build & Dependencies
# ==========================================
FROM node:20-alpine AS dependencies

WORKDIR /usr/src/app

# Copy package descriptors first to leverage Docker layer caching
COPY package*.json ./

# Install only production dependencies
RUN npm ci --only=production

# ==========================================
# Stage 2: Production Final Image
# ==========================================
FROM node:20-alpine AS release

WORKDIR /usr/src/app

# Security best practice: Add non-root user or use existing 'node' user
USER node

# Copy dependencies from previous stage with proper ownership
COPY --chown=node:node --from=dependencies /usr/src/app/node_modules ./node_modules
COPY --chown=node:node package*.json ./
COPY --chown=node:node src/ ./src/

# Set production environment variables
ENV NODE_ENV=production
ENV PORT=3000

# Expose container application port
EXPOSE 3000

# Docker Healthcheck to let Docker daemon and orchestration monitor health
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:3000/health || exit 1

# Start the application
CMD ["node", "src/server.js"]
