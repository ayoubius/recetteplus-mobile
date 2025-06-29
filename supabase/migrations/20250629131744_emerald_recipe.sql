/*
  # Ajout des services de localisation et amélioration des paniers

  1. Nouvelles tables
    - `delivery_zones` pour les zones de livraison
    - `user_locations` pour les adresses des utilisateurs
  
  2. Fonctions
    - Fonctions pour gérer les paniers et les produits
    - Fonctions pour calculer les distances de livraison
  
  3. Améliorations des paniers
    - Ajout de fonctions pour récupérer les détails des paniers
    - Optimisation des requêtes pour les paniers
*/

-- Créer la table des zones de livraison si elle n'existe pas
CREATE TABLE IF NOT EXISTS delivery_zones (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  is_active BOOLEAN DEFAULT true,
  delivery_fee NUMERIC NOT NULL DEFAULT 2000,
  min_delivery_time INTEGER,
  max_delivery_time INTEGER,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Créer la table des adresses utilisateurs si elle n'existe pas
CREATE TABLE IF NOT EXISTS user_locations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  address TEXT NOT NULL,
  latitude NUMERIC(10,8),
  longitude NUMERIC(11,8),
  is_default BOOLEAN DEFAULT false,
  label TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Activer RLS sur les nouvelles tables
ALTER TABLE delivery_zones ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_locations ENABLE ROW LEVEL SECURITY;

-- Politiques pour les zones de livraison
CREATE POLICY "Anyone can view active delivery zones" 
  ON delivery_zones
  FOR SELECT
  USING (is_active = true);

CREATE POLICY "Admins can manage delivery zones" 
  ON delivery_zones
  FOR ALL
  USING (is_admin());

-- Politiques pour les adresses utilisateurs
CREATE POLICY "Users can manage their own locations" 
  ON user_locations
  FOR ALL
  USING (auth.uid() = user_id);

CREATE POLICY "Admins can view all user locations" 
  ON user_locations
  FOR SELECT
  USING (is_admin());

-- Fonction pour calculer la distance entre deux points (Haversine)
CREATE OR REPLACE FUNCTION calculate_distance(
  lat1 NUMERIC, 
  lon1 NUMERIC, 
  lat2 NUMERIC, 
  lon2 NUMERIC
) RETURNS NUMERIC AS $$
DECLARE
  R NUMERIC := 6371; -- Rayon de la Terre en km
  dLat NUMERIC;
  dLon NUMERIC;
  a NUMERIC;
  c NUMERIC;
  d NUMERIC;
BEGIN
  dLat := radians(lat2 - lat1);
  dLon := radians(lon2 - lon1);
  
  a := sin(dLat/2) * sin(dLat/2) + 
       cos(radians(lat1)) * cos(radians(lat2)) * 
       sin(dLon/2) * sin(dLon/2);
  c := 2 * atan2(sqrt(a), sqrt(1-a));
  d := R * c;
  
  RETURN d;
END;
$$ LANGUAGE plpgsql;

-- Fonction pour trouver la zone de livraison la plus proche
CREATE OR REPLACE FUNCTION find_nearest_delivery_zone(
  lat NUMERIC, 
  lon NUMERIC
) RETURNS UUID AS $$
DECLARE
  nearest_zone_id UUID;
BEGIN
  -- Pour l'instant, retourner simplement la première zone active
  -- Dans une vraie implémentation, on calculerait la distance avec chaque zone
  SELECT id INTO nearest_zone_id
  FROM delivery_zones
  WHERE is_active = true
  LIMIT 1;
  
  RETURN nearest_zone_id;
END;
$$ LANGUAGE plpgsql;

-- Insérer des zones de livraison par défaut si la table est vide
INSERT INTO delivery_zones (name, description, delivery_fee, min_delivery_time, max_delivery_time)
SELECT * FROM (VALUES
  ('Centre-ville', 'Zone du centre-ville et quartiers adjacents', 1500, 20, 40),
  ('Périphérie', 'Zones résidentielles en périphérie', 2000, 30, 60),
  ('Banlieue', 'Zones de banlieue et villages proches', 3000, 45, 90)
) AS v(name, description, delivery_fee, min_delivery_time, max_delivery_time)
WHERE NOT EXISTS (SELECT 1 FROM delivery_zones LIMIT 1);

-- Fonction pour obtenir les détails d'un panier personnel
CREATE OR REPLACE FUNCTION get_personal_cart_details(cart_id UUID)
RETURNS JSONB AS $$
DECLARE
  cart_details JSONB;
BEGIN
  SELECT jsonb_build_object(
    'cart_info', (SELECT row_to_json(pc) FROM personal_carts pc WHERE pc.id = cart_id),
    'items', (
      SELECT jsonb_agg(
        jsonb_build_object(
          'id', pci.id,
          'product_id', pci.product_id,
          'quantity', pci.quantity,
          'product', (SELECT row_to_json(p) FROM products p WHERE p.id = pci.product_id)
        )
      )
      FROM personal_cart_items pci
      WHERE pci.personal_cart_id = cart_id
    )
  ) INTO cart_details;
  
  RETURN cart_details;
END;
$$ LANGUAGE plpgsql;

-- Fonction pour obtenir les détails d'un panier recette
CREATE OR REPLACE FUNCTION get_recipe_cart_details(cart_id UUID)
RETURNS JSONB AS $$
DECLARE
  cart_details JSONB;
BEGIN
  SELECT jsonb_build_object(
    'cart_info', (SELECT row_to_json(rc) FROM recipe_user_carts rc WHERE rc.id = cart_id),
    'recipe', (
      SELECT row_to_json(r) 
      FROM recipe_user_carts ruc
      JOIN recipes r ON r.id = ruc.recipe_id
      WHERE ruc.id = cart_id
    ),
    'items', (
      SELECT jsonb_agg(
        jsonb_build_object(
          'id', rci.id,
          'product_id', rci.product_id,
          'quantity', rci.quantity,
          'product', (SELECT row_to_json(p) FROM products p WHERE p.id = rci.product_id)
        )
      )
      FROM recipe_cart_items rci
      WHERE rci.recipe_cart_id = cart_id
    )
  ) INTO cart_details;
  
  RETURN cart_details;
END;
$$ LANGUAGE plpgsql;

-- Fonction pour obtenir les détails d'un panier préconfiguré
CREATE OR REPLACE FUNCTION get_preconfigured_cart_details(cart_id UUID)
RETURNS JSONB AS $$
DECLARE
  cart_details JSONB;
BEGIN
  SELECT jsonb_build_object(
    'cart_info', (SELECT row_to_json(pc) FROM preconfigured_carts pc WHERE pc.id = cart_id),
    'items', (SELECT items FROM preconfigured_carts WHERE id = cart_id)
  ) INTO cart_details;
  
  RETURN cart_details;
END;
$$ LANGUAGE plpgsql;

-- Trigger pour mettre à jour le timestamp updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Appliquer le trigger aux tables
CREATE TRIGGER delivery_zones_updated_at_trigger
BEFORE UPDATE ON delivery_zones
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER user_locations_updated_at_trigger
BEFORE UPDATE ON user_locations
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Ajouter des index pour améliorer les performances
CREATE INDEX IF NOT EXISTS idx_user_locations_user_id ON user_locations(user_id);
CREATE INDEX IF NOT EXISTS idx_delivery_zones_active ON delivery_zones(is_active);