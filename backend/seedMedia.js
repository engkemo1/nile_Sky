const { Client } = require('pg');

const client = new Client({
  host: 'localhost',
  port: 5432,
  user: 'postgres',
  password: 'postgres',
  database: 'nilesky',
});

async function seed() {
  await client.connect();

  const realPhotos = JSON.stringify([
    'https://images.unsplash.com/photo-1507608616759-54f48f0af0ee?ixlib=rb-4.0.3&auto=format&fit=crop&w=1080&q=80',
    'https://images.unsplash.com/photo-1549449830-5847493a3af2?ixlib=rb-4.0.3&auto=format&fit=crop&w=1080&q=80',
    'https://images.unsplash.com/photo-1557088927-4a0b5f134914?ixlib=rb-4.0.3&auto=format&fit=crop&w=1080&q=80'
  ]);
  
  const coverPhoto = 'https://images.unsplash.com/photo-1498642289437-564ec5d72f88?ixlib=rb-4.0.3&auto=format&fit=crop&w=1080&q=80';
  const videoUrl = 'https://www.youtube.com/watch?v=dQw4w9WgXcQ'; // Replace with a real luxor video if available, using a placeholder for now

  console.log('Updating packages...');
  await client.query(`
    UPDATE packages 
    SET cover_photo_url = $1, photos = $2, video_url = $3
  `, [coverPhoto, realPhotos, videoUrl]);

  console.log('Updating flights...');
  await client.query(`
    UPDATE flights 
    SET photos = $1, video_url = $2
  `, [realPhotos, videoUrl]);

  console.log('Database media seeding complete!');
  await client.end();
}

seed().catch(console.error);
