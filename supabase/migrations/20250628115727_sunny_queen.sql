-- Ajouter la colonne updated_at si elle n'existe pas
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'videos' AND column_name = 'updated_at'
  ) THEN
    ALTER TABLE videos ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
  END IF;
END $$;

-- Mettre à jour les enregistrements existants
UPDATE videos SET updated_at = created_at WHERE updated_at IS NULL;

-- Créer ou remplacer les fonctions pour incrémenter les vues et likes
CREATE OR REPLACE FUNCTION increment_video_views(video_id UUID)
RETURNS void AS $$
BEGIN
  UPDATE videos 
  SET views = COALESCE(views, 0) + 1,
      updated_at = NOW()
  WHERE id = video_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION increment_video_likes(video_id UUID)
RETURNS void AS $$
BEGIN
  UPDATE videos 
  SET likes = COALESCE(likes, 0) + 1,
      updated_at = NOW()
  WHERE id = video_id;
END;
$$ LANGUAGE plpgsql;

-- Ajouter des index pour améliorer les performances
CREATE INDEX IF NOT EXISTS idx_videos_views ON videos(views DESC);
CREATE INDEX IF NOT EXISTS idx_videos_likes ON videos(likes DESC);
CREATE INDEX IF NOT EXISTS idx_videos_updated_at ON videos(updated_at DESC);

-- Insérer des vidéos d'exemple si la table est vide
INSERT INTO videos (title, description, category, duration, views, likes, video_url, thumbnail, created_at, updated_at) 
SELECT * FROM (VALUES
  ('Pasta Carbonara Authentique', 'Apprenez à faire une vraie carbonara italienne avec seulement 5 ingrédients !', 'Plats principaux', 180, 15420, 892, 'https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_1mb.mp4', 'https://images.pexels.com/photos/1279330/pexels-photo-1279330.jpeg', NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days'),
  ('Technique de découpe des légumes', 'Maîtrisez les techniques de découpe comme un chef professionnel', 'Techniques', 240, 8930, 567, 'https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_2mb.mp4', 'https://images.pexels.com/photos/1640777/pexels-photo-1640777.jpeg', NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day'),
  ('Tiramisu Express', 'Un tiramisu délicieux en seulement 15 minutes !', 'Desserts', 120, 23450, 1234, 'https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_1mb.mp4', 'https://images.pexels.com/photos/6880219/pexels-photo-6880219.jpeg', NOW() - INTERVAL '12 hours', NOW() - INTERVAL '12 hours'),
  ('Smoothie Bowl Tropical', 'Un petit-déjeuner coloré et nutritif pour bien commencer la journée', 'Petit-déjeuner', 90, 12340, 678, 'https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_2mb.mp4', 'https://images.pexels.com/photos/1092730/pexels-photo-1092730.jpeg', NOW() - INTERVAL '6 hours', NOW() - INTERVAL '6 hours'),
  ('Ratatouille Traditionnelle', 'La recette authentique de la ratatouille provençale', 'Plats principaux', 300, 18760, 945, 'https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_1mb.mp4', 'https://images.pexels.com/photos/8629141/pexels-photo-8629141.jpeg', NOW() - INTERVAL '3 hours', NOW() - INTERVAL '3 hours'),
  ('Salade César Parfaite', 'Les secrets d''une salade César comme au restaurant', 'Entrées', 150, 9876, 543, 'https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_1mb.mp4', 'https://images.pexels.com/photos/2097090/pexels-photo-2097090.jpeg', NOW() - INTERVAL '1 hour', NOW() - INTERVAL '1 hour'),
  ('Croissants Maison', 'Réalisez de vrais croissants français chez vous', 'Boulangerie', 420, 31250, 1876, 'https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_2mb.mp4', 'https://images.pexels.com/photos/2067396/pexels-photo-2067396.jpeg', NOW() - INTERVAL '30 minutes', NOW() - INTERVAL '30 minutes'),
  ('Soupe de Légumes d''Hiver', 'Une soupe réconfortante pour les jours froids', 'Soupes', 200, 7654, 432, 'https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_1mb.mp4', 'https://images.pexels.com/photos/539451/pexels-photo-539451.jpeg', NOW() - INTERVAL '15 minutes', NOW() - INTERVAL '15 minutes')
) AS v(title, description, category, duration, views, likes, video_url, thumbnail, created_at, updated_at)
WHERE NOT EXISTS (SELECT 1 FROM videos LIMIT 1);