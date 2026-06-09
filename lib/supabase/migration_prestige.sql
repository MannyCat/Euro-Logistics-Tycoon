-- =============================================
-- Migration: Prestige System
-- Run via Supabase Dashboard SQL Editor
-- =============================================

-- Add prestige columns to companies
ALTER TABLE companies ADD COLUMN IF NOT EXISTS prestige_level INTEGER DEFAULT 0;
ALTER TABLE companies ADD COLUMN IF NOT EXISTS total_earned_money BIGINT DEFAULT 0;

-- Prestige bonuses table
CREATE TABLE IF NOT EXISTS prestige_bonuses (
  company_id UUID PRIMARY KEY REFERENCES companies(id),
  prestige_level INTEGER DEFAULT 0,
  income_bonus NUMERIC(3,2) DEFAULT 0,    -- +5% per level
  xp_bonus NUMERIC(3,2) DEFAULT 0,       -- +10% per level
  fuel_discount NUMERIC(3,2) DEFAULT 0,   -- +3% per level
  UNIQUE(company_id)
);

ALTER TABLE prestige_bonuses ENABLE ROW LEVEL SECURITY;
CREATE POLICY "prestige_read" ON prestige_bonuses FOR SELECT USING (true);
CREATE POLICY "prestige_insert" ON prestige_bonuses FOR INSERT WITH CHECK (true);
CREATE POLICY "prestige_update" ON prestige_bonuses FOR UPDATE USING (true);

-- Prestige reset function
CREATE OR REPLACE FUNCTION prestige_reset(p_company_id UUID)
RETURNS boolean AS $$
DECLARE
  v_current_level INTEGER;
  v_new_money INTEGER := 1000000; -- Start with €1M after prestige
BEGIN
  SELECT prestige_level INTO v_current_level FROM companies WHERE id = p_company_id;

  -- Must be at least level 10 to prestige
  IF (SELECT level FROM companies WHERE id = p_company_id) < 10 THEN
    RAISE EXCEPTION 'Нужен 10-й уровень для престижа';
  END IF;

  -- Increment prestige level
  UPDATE companies SET
    prestige_level = prestige_level + 1,
    level = 1,
    xp = 0,
    money = v_new_money,
    reputation = 50,
    total_earned_money = 0
  WHERE id = p_company_id;

  -- Delete all trucks
  DELETE FROM trucks WHERE company_id = p_company_id;

  -- Delete all drivers
  DELETE FROM drivers WHERE company_id = p_company_id;

  -- Delete all warehouses
  DELETE FROM warehouses WHERE company_id = p_company_id;

  -- Delete all garages
  DELETE FROM garages WHERE company_id = p_company_id;

  -- Delete all market listings
  DELETE FROM market_listings WHERE seller_id = p_company_id;

  -- Leave clan if in one
  DELETE FROM clan_members WHERE company_id = p_company_id;

  -- Update prestige bonuses
  INSERT INTO prestige_bonuses (company_id, prestige_level, income_bonus, xp_bonus, fuel_discount)
  VALUES (p_company_id, v_current_level + 1,
    (v_current_level + 1) * 0.05,
    (v_current_level + 1) * 0.10,
    (v_current_level + 1) * 0.03)
  ON CONFLICT (company_id) DO UPDATE SET
    prestige_level = v_current_level + 1,
    income_bonus = (v_current_level + 1) * 0.05,
    xp_bonus = (v_current_level + 1) * 0.10,
    fuel_discount = (v_current_level + 1) * 0.03;

  -- Log
  INSERT INTO event_log (company_id, event_type, title, description, icon_name, color_hex)
  VALUES (p_company_id, 'prestige', 'Престиж!',
    format('Престиж-сброс! Уровень престижа: %s. Бонусы увеличены.', v_current_level + 1),
    'star', 'F5C542');

  RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
