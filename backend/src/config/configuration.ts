export default () => ({
  port: parseInt(process.env.PORT, 10) || 3000,
  nodeEnv: process.env.NODE_ENV || 'development',
  jwt: {
    accessSecret: process.env.JWT_ACCESS_SECRET,
    refreshSecret: process.env.JWT_REFRESH_SECRET,
    accessExpiry: process.env.JWT_ACCESS_EXPIRY || '15m',
    refreshExpiry: process.env.JWT_REFRESH_EXPIRY || '7d',
  },
  database: {
    host: process.env.POSTGRES_HOST || process.env.DATABASE_HOST || 'localhost',
    port: parseInt(process.env.POSTGRES_PORT || process.env.DATABASE_PORT || '5432', 10),
    name: process.env.POSTGRES_DB || process.env.DATABASE_NAME || 'postgres',
    user: process.env.POSTGRES_USER || process.env.DATABASE_USER || 'postgres',
    password: String(process.env.POSTGRES_PASSWORD || process.env.DATABASE_PASSWORD || ''),
    ssl: (process.env.POSTGRES_SSL || process.env.DATABASE_SSL) === 'true',
  },
  supabase: {
    url: process.env.SUPABASE_URL,
    serviceKey: process.env.SUPABASE_SERVICE_KEY,
  },
  livekit: {
    apiKey: process.env.LIVEKIT_API_KEY,
    apiSecret: process.env.LIVEKIT_API_SECRET,
    wsUrl: process.env.LIVEKIT_WS_URL,
  },
  aiService: {
    url: process.env.AI_SERVICE_URL,
  },
  firebase: {
    projectId: process.env.FIREBASE_PROJECT_ID,
    clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
    privateKey: process.env.FIREBASE_PRIVATE_KEY,
  },
  cors: {
    origin: process.env.CORS_ORIGIN || '*',
  },
  throttle: {
    ttl: parseInt(process.env.THROTTLE_TTL, 10) || 60,
    limit: parseInt(process.env.THROTTLE_LIMIT, 10) || 100,
  },
});
