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
    const users = await pool.query("SELECT id, username, email, avatar_url FROM users;");
    for (const u of users.rows) {
      console.log(u.username, u.avatar_url);
    }
  } catch (err) {
    console.error(err);
  } finally {
    await pool.end();
  }
}

run();

