const { Client } = require('pg');

async function seedPosts() {
  const client = new Client({
    host: 'aws-1-eu-central-1.pooler.supabase.com',
    port: 5432,
    database: 'postgres',
    user: 'postgres.sdzzzikdophekbzuzdwx',
    password: 'Expendadeur@Janvier@',
    ssl: { rejectUnauthorized: false },
  });

  try {
    await client.connect();
    console.log('Connecté à Supabase PostgreSQL avec succès !');

    // 1. Récupérer tous les utilisateurs
    const usersRes = await client.query('SELECT id, username, first_name, last_name, preferred_language FROM users ORDER BY created_at ASC');
    console.log(`Nombre d'utilisateurs trouvés : ${usersRes.rows.length}`);

    if (usersRes.rows.length === 0) {
      console.log('Aucun utilisateur trouvé en base.');
      return;
    }

    // 2. Mettre tous les utilisateurs en ligne (is_online = true)
    await client.query('UPDATE users SET is_online = true');
    console.log('Tous les utilisateurs ont été marqués comme EN LIGNE (cercle vert).');

    // 3. Modèles de posts multimédias réalistes pour le Burundi
    const postTemplates = [
      {
        postType: 'text',
        content: 'Amahoro amahanga yose ! Twishimiye kubana namwe kuri InterConnect Burundi, umuyoboro wacu mushya wo gusangira amakuru adusanganya. 🇧🇮✨',
        originalLanguage: 'rn',
        mediaUrls: [],
      },
      {
        postType: 'photo',
        content: 'Coucher de soleil magnifique sur les rives du Lac Tanganyika à Bujumbura. Une vraie bénédiction de notre cher pays ! 🌅🇧🇮',
        originalLanguage: 'fr',
        mediaUrls: ['https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=1200&q=80'],
      },
      {
        postType: 'video',
        content: 'Performance majestueuse des Tambourinaires de Gishora au Burundi ! Le rythme sacré inscrit au patrimoine immatériel mondial de l\'UNESCO. 🥁🔥',
        originalLanguage: 'fr',
        mediaUrls: ['https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4'],
      },
      {
        postType: 'audio',
        content: 'Écoutez cet extrait de musique acoustique traditionnelle du Burundi : inanga et mélodies de paix. Un pur moment d\'évasion ! 🎵🎶',
        originalLanguage: 'rn',
        mediaUrls: ['https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3'],
      },
    ];

    // 4. Pour chaque utilisateur, créer les 4 types de publications s'il n'en a pas déjà
    for (const user of usersRes.rows) {
      console.log(`Insertion des publications pour ${user.first_name || user.username} (${user.id})...`);
      for (const tpl of postTemplates) {
        await client.query(
          `INSERT INTO posts (
            id, author_id, content, original_language, media_urls, post_type, visibility, likes_count, views_count, comments_count, shares_count, created_at, updated_at
          ) VALUES (
            gen_random_uuid(), $1, $2, $3, $4::jsonb, $5, 'public', FLOOR(RANDOM() * 25 + 5), FLOOR(RANDOM() * 200 + 40), FLOOR(RANDOM() * 8 + 1), FLOOR(RANDOM() * 4), NOW() - (RANDOM() * INTERVAL '5 days'), NOW()
          )`,
          [user.id, tpl.content, tpl.originalLanguage, JSON.stringify(tpl.mediaUrls), tpl.postType]
        );
      }
    }

    console.log('Toutes les publications multimédias (texte, photo, vidéo, musique) ont été créées avec succès !');

    // Vérification du total
    const totalPosts = await client.query('SELECT COUNT(*) FROM posts');
    console.log(`Nombre total actuel de posts en base : ${totalPosts.rows[0].count}`);

  } catch (err) {
    console.error('Erreur lors du seeding :', err);
  } finally {
    await client.end();
  }
}

seedPosts();

