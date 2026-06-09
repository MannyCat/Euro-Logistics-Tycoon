-- =============================================
-- GARAGE SYSTEM MIGRATION
-- Must be applied via Supabase Dashboard SQL Editor
-- =============================================

-- Garages table
CREATE TABLE IF NOT EXISTS garages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  city_id INTEGER NOT NULL,
  slots INTEGER NOT NULL DEFAULT 2,       -- initial parking slots
  max_slots INTEGER NOT NULL DEFAULT 8,     -- max after upgrades
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(company_id, city_id)
);

-- RLS
ALTER TABLE garages ENABLE ROW LEVEL SECURITY;
CREATE POLICY "garages_read" ON garages FOR SELECT USING (true);
CREATE POLICY "garages_insert" ON garages FOR INSERT WITH CHECK (
  company_id IN (SELECT id FROM companies WHERE owner_id = auth.uid())
);
CREATE POLICY "garages_update" ON garages FOR UPDATE USING (
  company_id IN (SELECT id FROM companies WHERE owner_id = auth.uid())
);

-- Function to buy a garage in a city
CREATE OR REPLACE FUNCTION buy_garage(p_company_id UUID, p_city_id INTEGER)
RETURNS boolean AS $$
DECLARE
  v_cost INTEGER := 20000;
BEGIN
  -- Check not already owned
  IF EXISTS (SELECT 1 FROM garages WHERE company_id = p_company_id AND city_id = p_city_id) THEN
    RAISE EXCEPTION 'Гараж уже куплен';
  END IF;

  -- Check money
  IF (SELECT money FROM companies WHERE id = p_company_id) < v_cost THEN
    RAISE EXCEPTION 'Недостаточно средств';
  END IF;

  -- Deduct and create
  UPDATE companies SET money = money - v_cost WHERE id = p_company_id;
  INSERT INTO garages (company_id, city_id) VALUES (p_company_id, p_city_id);
  INSERT INTO transactions (company_id, type, description, amount)
  VALUES (p_company_id, 'garage', 'Гараж в городе #' || p_city_id, -v_cost);

  RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to expand garage (+2 slots)
CREATE OR REPLACE FUNCTION expand_garage(p_company_id UUID, p_city_id INTEGER)
RETURNS boolean AS $$
DECLARE
  v_cost INTEGER := 15000;
  v_current_slots INTEGER;
BEGIN
  SELECT slots INTO v_current_slots FROM garages
  WHERE company_id = p_company_id AND city_id = p_city_id;

  IF v_current_slots IS NULL THEN
    RAISE EXCEPTION 'Гараж не найден';
  END IF;

  IF v_current_slots >= 8 THEN
    RAISE EXCEPTION 'Максимальный размер гаража';
  END IF;

  -- Cost increases with each expansion level
  v_cost := 15000 * ((v_current_slots - 2) / 2 + 1);

  IF (SELECT money FROM companies WHERE id = p_company_id) < v_cost THEN
    RAISE EXCEPTION 'Недостаточно средств';
  END IF;

  UPDATE garages SET slots = slots + 2 WHERE company_id = p_company_id AND city_id = p_city_id;
  UPDATE companies SET money = money - v_cost WHERE id = p_company_id;
  INSERT INTO transactions (company_id, type, description, amount)
  VALUES (p_company_id, 'garage_expand', 'Расширение гаража #' || p_city_id, -v_cost);

  RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
