const { Pool } = require('pg');

const pool = new Pool({
  host: 'aws-1-eu-central-1.pooler.supabase.com',
  port: 6543,
  database: 'postgres',
  user: 'postgres.sdzzzikdophekbzuzdwx',
  password: 'Expendadeur@Janvier@',
  ssl: { rejectUnauthorized: false }
});

async function run() {
  try {
    const res = await pool.query(
      "SELECT column_name, data_type, character_maximum_length FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'avatar_url';"
    );
    console.log('COLUMN:', res.rows);

    await pool.query("ALTER TABLE users ALTER COLUMN avatar_url TYPE text;");
    console.log('ALTER COLUMN avatar_url TYPE text SUCCESS');

    const users = await pool.query("SELECT id, username, email, is_online, LENGTH(avatar_url) as avatar_len FROM users LIMIT 10;");
    console.log('USERS:', users.rows);
  } catch (err) {
    console.error('ERROR:', err);
  } finally {
    await pool.end();
  }
}

run();
