-- Activer l'extension uuid-ossp si ce n'est pas déjà fait
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Table pour les livreurs
CREATE TABLE IF NOT EXISTS public.delivery_persons (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  is_active boolean DEFAULT true,
  vehicle_type text,
  license_plate text,
  current_status text DEFAULT 'available',
  rating numeric(3,2) DEFAULT 5.0,
  total_deliveries integer DEFAULT 0,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Ajouter des contraintes de validation
ALTER TABLE public.delivery_persons ADD CONSTRAINT delivery_persons_current_status_check 
  CHECK (current_status IN ('available', 'delivering', 'offline', 'on_break'));

-- Table pour l'historique des statuts de commande
CREATE TABLE IF NOT EXISTS public.order_status_history (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id uuid NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
  status text NOT NULL,
  notes text,
  created_by uuid REFERENCES public.profiles(id),
  created_at timestamptz DEFAULT now()
);

-- Table pour le suivi en temps réel des commandes
CREATE TABLE IF NOT EXISTS public.order_tracking (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id uuid NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
  delivery_person_id uuid REFERENCES public.delivery_persons(id),
  current_latitude numeric(10,7),
  current_longitude numeric(10,7),
  estimated_delivery_time timestamptz,
  last_updated_at timestamptz DEFAULT now()
);

-- Table pour les zones de livraison
CREATE TABLE IF NOT EXISTS public.delivery_zones (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  description text,
  is_active boolean DEFAULT true,
  delivery_fee numeric(10,2) DEFAULT 2000.0,
  min_delivery_time integer, -- en minutes
  max_delivery_time integer, -- en minutes
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Ajouter des colonnes à la table orders existante
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS delivery_address text;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS delivery_zone_id uuid REFERENCES public.delivery_zones(id);
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS delivery_fee numeric(10,2) DEFAULT 2000.0;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS delivery_notes text;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS delivery_person_id uuid REFERENCES public.delivery_persons(id);
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS estimated_delivery_time timestamptz;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS actual_delivery_time timestamptz;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS qr_code text;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS updated_at timestamptz DEFAULT now();

-- Modifier la contrainte de statut pour inclure les nouveaux statuts
ALTER TABLE public.orders DROP CONSTRAINT IF EXISTS orders_status_check;
ALTER TABLE public.orders ADD CONSTRAINT orders_status_check 
  CHECK (status IN ('pending', 'confirmed', 'preparing', 'ready_for_pickup', 'out_for_delivery', 'delivered', 'cancelled'));

-- Ajouter des permissions au rôle admin_permissions
ALTER TABLE public.admin_permissions ADD COLUMN IF NOT EXISTS can_manage_deliveries boolean DEFAULT false;
ALTER TABLE public.admin_permissions ADD COLUMN IF NOT EXISTS can_validate_orders boolean DEFAULT false;

-- Fonction pour mettre à jour le statut d'une commande
CREATE OR REPLACE FUNCTION update_order_status(
  order_id uuid,
  new_status text,
  notes text DEFAULT NULL,
  user_id uuid DEFAULT auth.uid()
)
RETURNS void AS $$
BEGIN
  -- Vérifier si la commande existe
  IF NOT EXISTS (SELECT 1 FROM public.orders WHERE id = order_id) THEN
    RAISE EXCEPTION 'Commande non trouvée';
  END IF;

  -- Mettre à jour le statut de la commande
  UPDATE public.orders
  SET 
    status = new_status,
    updated_at = now()
  WHERE id = order_id;

  -- Ajouter une entrée dans l'historique
  INSERT INTO public.order_status_history (
    order_id,
    status,
    notes,
    created_by
  ) VALUES (
    order_id,
    new_status,
    notes,
    user_id
  );

  -- Si le statut est "delivered", mettre à jour actual_delivery_time
  IF new_status = 'delivered' THEN
    UPDATE public.orders
    SET actual_delivery_time = now()
    WHERE id = order_id;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- Fonction pour assigner un livreur à une commande
CREATE OR REPLACE FUNCTION assign_delivery_person(
  order_id uuid,
  delivery_person_id uuid,
  user_id uuid DEFAULT auth.uid()
)
RETURNS void AS $$
DECLARE
  delivery_person_user_id uuid;
BEGIN
  -- Vérifier si la commande existe
  IF NOT EXISTS (SELECT 1 FROM public.orders WHERE id = order_id) THEN
    RAISE EXCEPTION 'Commande non trouvée';
  END IF;

  -- Vérifier si le livreur existe et est actif
  SELECT user_id INTO delivery_person_user_id
  FROM public.delivery_persons
  WHERE id = delivery_person_id AND is_active = true;

  IF delivery_person_user_id IS NULL THEN
    RAISE EXCEPTION 'Livreur non trouvé ou inactif';
  END IF;

  -- Mettre à jour la commande
  UPDATE public.orders
  SET 
    delivery_person_id = delivery_person_id,
    status = 'out_for_delivery',
    updated_at = now()
  WHERE id = order_id;

  -- Mettre à jour le statut du livreur
  UPDATE public.delivery_persons
  SET 
    current_status = 'delivering',
    updated_at = now()
  WHERE id = delivery_person_id;

  -- Ajouter une entrée dans l'historique
  INSERT INTO public.order_status_history (
    order_id,
    status,
    notes,
    created_by
  ) VALUES (
    order_id,
    'out_for_delivery',
    'Commande assignée au livreur',
    user_id
  );

  -- Créer une entrée de suivi
  INSERT INTO public.order_tracking (
    order_id,
    delivery_person_id,
    estimated_delivery_time
  ) VALUES (
    order_id,
    delivery_person_id,
    now() + interval '1 hour' -- Estimation par défaut de 1 heure
  );
END;
$$ LANGUAGE plpgsql;

-- Fonction pour générer un code QR pour une commande
CREATE OR REPLACE FUNCTION generate_order_qr_code(order_id uuid)
RETURNS text AS $$
DECLARE
  qr_code text;
BEGIN
  -- Générer un code unique basé sur l'ID de commande et un timestamp
  qr_code := 'RP-' || replace(order_id::text, '-', '') || '-' || 
              to_char(now(), 'YYYYMMDDHH24MISS');
  
  -- Mettre à jour la commande avec le code QR
  UPDATE public.orders
  SET qr_code = qr_code
  WHERE id = order_id;
  
  RETURN qr_code;
END;
$$ LANGUAGE plpgsql;

-- Fonction pour vérifier si un utilisateur est un livreur
CREATE OR REPLACE FUNCTION is_delivery_person()
RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 
    FROM public.delivery_persons 
    WHERE user_id = auth.uid() AND is_active = true
  );
END;
$$ LANGUAGE plpgsql;

-- Fonction pour vérifier si un utilisateur est un validateur de commandes
CREATE OR REPLACE FUNCTION is_order_validator()
RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 
    FROM public.admin_permissions 
    WHERE user_id = auth.uid() AND (can_validate_orders = true OR is_super_admin = true)
  );
END;
$$ LANGUAGE plpgsql;

-- Fonction pour mettre à jour la position du livreur
CREATE OR REPLACE FUNCTION update_delivery_location(
  tracking_id uuid,
  latitude numeric(10,7),
  longitude numeric(10,7)
)
RETURNS void AS $$
BEGIN
  UPDATE public.order_tracking
  SET 
    current_latitude = latitude,
    current_longitude = longitude,
    last_updated_at = now()
  WHERE id = tracking_id;
END;
$$ LANGUAGE plpgsql;

-- Activer RLS sur les nouvelles tables
ALTER TABLE public.delivery_persons ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_status_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_tracking ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.delivery_zones ENABLE ROW LEVEL SECURITY;

-- Politiques RLS pour delivery_persons
CREATE POLICY "Admins can manage delivery persons"
  ON public.delivery_persons
  FOR ALL
  TO public
  USING (has_admin_permission('deliveries') OR is_super_admin());

CREATE POLICY "Delivery persons can view their own profile"
  ON public.delivery_persons
  FOR SELECT
  TO public
  USING (user_id = auth.uid());

-- Politiques RLS pour order_status_history
CREATE POLICY "Admins can manage order status history"
  ON public.order_status_history
  FOR ALL
  TO public
  USING (has_admin_permission('orders') OR is_super_admin());

CREATE POLICY "Users can view their own order status history"
  ON public.order_status_history
  FOR SELECT
  TO public
  USING (EXISTS (
    SELECT 1 FROM public.orders
    WHERE orders.id = order_status_history.order_id
    AND orders.user_id = auth.uid()
  ));

CREATE POLICY "Delivery persons can view assigned order status history"
  ON public.order_status_history
  FOR SELECT
  TO public
  USING (EXISTS (
    SELECT 1 FROM public.orders
    WHERE orders.id = order_status_history.order_id
    AND orders.delivery_person_id IN (
      SELECT id FROM public.delivery_persons
      WHERE user_id = auth.uid()
    )
  ));

-- Politiques RLS pour order_tracking
CREATE POLICY "Admins can manage order tracking"
  ON public.order_tracking
  FOR ALL
  TO public
  USING (has_admin_permission('orders') OR is_super_admin());

CREATE POLICY "Users can view their own order tracking"
  ON public.order_tracking
  FOR SELECT
  TO public
  USING (EXISTS (
    SELECT 1 FROM public.orders
    WHERE orders.id = order_tracking.order_id
    AND orders.user_id = auth.uid()
  ));

CREATE POLICY "Delivery persons can update their assigned order tracking"
  ON public.order_tracking
  FOR UPDATE
  TO public
  USING (delivery_person_id IN (
    SELECT id FROM public.delivery_persons
    WHERE user_id = auth.uid()
  ));

CREATE POLICY "Delivery persons can view assigned order tracking"
  ON public.order_tracking
  FOR SELECT
  TO public
  USING (delivery_person_id IN (
    SELECT id FROM public.delivery_persons
    WHERE user_id = auth.uid()
  ));

-- Politiques RLS pour delivery_zones
CREATE POLICY "Admins can manage delivery zones"
  ON public.delivery_zones
  FOR ALL
  TO public
  USING (has_admin_permission('deliveries') OR is_super_admin());

CREATE POLICY "Anyone can view active delivery zones"
  ON public.delivery_zones
  FOR SELECT
  TO public
  USING (is_active = true);

-- Mettre à jour les politiques RLS pour orders
CREATE POLICY "Delivery persons can view and update assigned orders"
  ON public.orders
  FOR ALL
  TO public
  USING (delivery_person_id IN (
    SELECT id FROM public.delivery_persons
    WHERE user_id = auth.uid()
  ));

CREATE POLICY "Order validators can validate orders"
  ON public.orders
  FOR UPDATE
  TO public
  USING (is_order_validator());

-- Trigger pour mettre à jour updated_at
CREATE OR REPLACE FUNCTION trigger_set_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_timestamp_delivery_persons
BEFORE UPDATE ON public.delivery_persons
FOR EACH ROW
EXECUTE FUNCTION trigger_set_timestamp();

CREATE TRIGGER set_timestamp_delivery_zones
BEFORE UPDATE ON public.delivery_zones
FOR EACH ROW
EXECUTE FUNCTION trigger_set_timestamp();

CREATE TRIGGER set_timestamp_orders
BEFORE UPDATE ON public.orders
FOR EACH ROW
EXECUTE FUNCTION trigger_set_timestamp();

-- Insérer des zones de livraison par défaut
INSERT INTO public.delivery_zones (name, description, delivery_fee, min_delivery_time, max_delivery_time)
VALUES 
('Zone Centre', 'Centre-ville et quartiers proches', 2000.0, 30, 45),
('Zone Périphérique', 'Quartiers périphériques', 3000.0, 45, 60),
('Zone Étendue', 'Banlieue et villages proches', 4000.0, 60, 90)
ON CONFLICT DO NOTHING;