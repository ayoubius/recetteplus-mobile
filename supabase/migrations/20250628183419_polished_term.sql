/*
  # Configuration du stockage pour les profils

  1. Storage
    - Créer le bucket 'avatars' pour les photos de profil
    - Configurer les politiques de sécurité
    
  2. Functions
    - Fonction pour gérer l'upload d'avatar
    - Fonction pour supprimer l'ancien avatar
    
  3. Policies
    - Permettre aux utilisateurs de gérer leurs propres avatars
*/

-- Créer le bucket avatars s'il n'existe pas
INSERT INTO storage.buckets (id, name, public)
VALUES ('avatars', 'avatars', true)
ON CONFLICT (id) DO NOTHING;

-- Politique pour permettre aux utilisateurs de voir tous les avatars publics
CREATE POLICY "Avatar images are publicly accessible" ON storage.objects
FOR SELECT USING (bucket_id = 'avatars');

-- Politique pour permettre aux utilisateurs d'uploader leur propre avatar
CREATE POLICY "Users can upload their own avatar" ON storage.objects
FOR INSERT WITH CHECK (
  bucket_id = 'avatars' AND 
  auth.uid()::text = (storage.foldername(name))[1]
);

-- Politique pour permettre aux utilisateurs de mettre à jour leur propre avatar
CREATE POLICY "Users can update their own avatar" ON storage.objects
FOR UPDATE USING (
  bucket_id = 'avatars' AND 
  auth.uid()::text = (storage.foldername(name))[1]
);

-- Politique pour permettre aux utilisateurs de supprimer leur propre avatar
CREATE POLICY "Users can delete their own avatar" ON storage.objects
FOR DELETE USING (
  bucket_id = 'avatars' AND 
  auth.uid()::text = (storage.foldername(name))[1]
);

-- Fonction pour mettre à jour l'URL de l'avatar dans le profil
CREATE OR REPLACE FUNCTION update_profile_avatar(user_id UUID, avatar_url TEXT)
RETURNS void AS $$
BEGIN
  UPDATE profiles 
  SET 
    photo_url = avatar_url,
    updated_at = NOW()
  WHERE id = user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Fonction pour supprimer l'ancien avatar
CREATE OR REPLACE FUNCTION delete_old_avatar(user_id UUID)
RETURNS void AS $$
DECLARE
  old_avatar_path TEXT;
BEGIN
  -- Récupérer l'ancien chemin de l'avatar
  SELECT photo_url INTO old_avatar_path
  FROM profiles 
  WHERE id = user_id;
  
  -- Si un avatar existe, le supprimer du storage
  IF old_avatar_path IS NOT NULL AND old_avatar_path LIKE '%/storage/v1/object/public/avatars/%' THEN
    -- Extraire le nom du fichier de l'URL
    old_avatar_path := substring(old_avatar_path from '/avatars/(.*)');
    
    -- Supprimer le fichier du storage
    DELETE FROM storage.objects 
    WHERE bucket_id = 'avatars' AND name = old_avatar_path;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Ajouter des colonnes manquantes à la table profiles si elles n'existent pas
DO $$
BEGIN
  -- Ajouter la colonne bio si elle n'existe pas
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'profiles' AND column_name = 'bio'
  ) THEN
    ALTER TABLE profiles ADD COLUMN bio TEXT;
  END IF;
  
  -- Ajouter la colonne date_of_birth si elle n'existe pas
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'profiles' AND column_name = 'date_of_birth'
  ) THEN
    ALTER TABLE profiles ADD COLUMN date_of_birth DATE;
  END IF;
  
  -- Ajouter la colonne location si elle n'existe pas
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'profiles' AND column_name = 'location'
  ) THEN
    ALTER TABLE profiles ADD COLUMN location TEXT;
  END IF;
  
  -- Ajouter la colonne privacy_settings si elle n'existe pas
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'profiles' AND column_name = 'privacy_settings'
  ) THEN
    ALTER TABLE profiles ADD COLUMN privacy_settings JSONB DEFAULT '{
      "profile_visibility": "public",
      "email_visibility": "private",
      "phone_visibility": "private",
      "location_visibility": "public",
      "activity_visibility": "public",
      "allow_friend_requests": true,
      "allow_messages": true,
      "show_online_status": true
    }'::jsonb;
  END IF;
  
  -- Ajouter la colonne notification_settings si elle n'existe pas
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'profiles' AND column_name = 'notification_settings'
  ) THEN
    ALTER TABLE profiles ADD COLUMN notification_settings JSONB DEFAULT '{
      "email_notifications": true,
      "push_notifications": true,
      "recipe_updates": true,
      "product_updates": true,
      "marketing_emails": false,
      "weekly_digest": true
    }'::jsonb;
  END IF;
END $$;

-- Mettre à jour les profils existants avec les paramètres par défaut
UPDATE profiles 
SET 
  privacy_settings = COALESCE(privacy_settings, '{
    "profile_visibility": "public",
    "email_visibility": "private", 
    "phone_visibility": "private",
    "location_visibility": "public",
    "activity_visibility": "public",
    "allow_friend_requests": true,
    "allow_messages": true,
    "show_online_status": true
  }'::jsonb),
  notification_settings = COALESCE(notification_settings, '{
    "email_notifications": true,
    "push_notifications": true,
    "recipe_updates": true,
    "product_updates": true,
    "marketing_emails": false,
    "weekly_digest": true
  }'::jsonb)
WHERE privacy_settings IS NULL OR notification_settings IS NULL;