-- Migration: Driver Leveling & Skills System
-- Adds XP, fatigue, skills, and RPC functions for driver management

-- Add XP and stats columns to drivers
ALTER TABLE drivers ADD COLUMN IF NOT EXISTS xp INTEGER DEFAULT 0;
ALTER TABLE drivers ADD COLUMN IF NOT EXISTS trips_completed INTEGER DEFAULT 0;
ALTER TABLE drivers ADD COLUMN IF NOT EXISTS fatigue INTEGER DEFAULT 0; -- 0-100, 100 = exhausted
ALTER TABLE drivers ADD COLUMN IF NOT EXISTS last_trip_at TIMESTAMPTZ;

-- Skill columns (0-100 each, start at 0, cap at 100)
ALTER TABLE drivers ADD COLUMN IF NOT EXISTS speed_skill INTEGER DEFAULT 0;
ALTER TABLE drivers ADD COLUMN IF NOT EXISTS fuel_efficiency_skill INTEGER DEFAULT 0;
ALTER TABLE drivers ADD COLUMN IF NOT EXISTS reliability_skill INTEGER DEFAULT 0;

-- Function to grant XP and level up driver after completing a trip
CREATE OR REPLACE FUNCTION driver_complete_trip(p_driver_id UUID)
RETURNS boolean AS $$
DECLARE
  v_xp_gain INTEGER := 25;
  v_driver RECORD;
  v_old_level INTEGER;
  v_new_xp INTEGER;
  v_new_level INTEGER;
BEGIN
  -- Get driver
  SELECT * INTO v_driver FROM drivers WHERE id = p_driver_id;
  IF v_driver.id IS NULL THEN RETURN false; END IF;

  v_old_level := v_driver.skill_level;
  v_new_xp := v_driver.xp + v_xp_gain;

  -- Update trip count, XP, and last trip
  UPDATE drivers SET
    trips_completed = trips_completed + 1,
    last_trip_at = NOW(),
    xp = v_new_xp
  WHERE id = p_driver_id;

  -- Level up check (every 100 XP = 1 level, max 20)
  v_new_level := LEAST(20, v_old_level + FLOOR(v_new_xp / 100.0)::int - FLOOR(v_driver.xp / 100.0)::int);
  IF v_new_level > v_old_level THEN
    UPDATE drivers SET
      skill_level = v_new_level,
      salary_daily = salary_daily + (v_new_level - v_old_level) * 50
    WHERE id = p_driver_id;
  END IF;

  -- Random skill gain (0-3 points in a random skill per trip)
  UPDATE drivers SET
    speed_skill = LEAST(100, speed_skill + (CASE WHEN random() < 0.4 THEN (random() * 3)::int ELSE 0 END)),
    fuel_efficiency_skill = LEAST(100, fuel_efficiency_skill + (CASE WHEN random() < 0.4 THEN (random() * 3)::int ELSE 0 END)),
    reliability_skill = LEAST(100, reliability_skill + (CASE WHEN random() < 0.4 THEN (random() * 3)::int ELSE 0 END))
  WHERE id = p_driver_id;

  RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to rest driver (reduce fatigue)
CREATE OR REPLACE FUNCTION driver_rest(p_driver_id UUID)
RETURNS boolean AS $$
BEGIN
  UPDATE drivers SET fatigue = GREATEST(0, fatigue - 50) WHERE id = p_driver_id;
  RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Assign driver to truck
CREATE OR REPLACE FUNCTION assign_driver(p_driver_id UUID, p_truck_id UUID, p_company_id UUID)
RETURNS boolean AS $$
BEGIN
  -- Unassign from current truck if any
  UPDATE trucks SET driver_id = NULL WHERE driver_id = p_driver_id AND company_id = p_company_id;
  -- Assign to new truck
  UPDATE trucks SET driver_id = p_driver_id WHERE id = p_truck_id AND company_id = p_company_id;
  -- Update driver
  UPDATE drivers SET assigned_truck_id = p_truck_id, status = 'assigned' WHERE id = p_driver_id AND company_id = p_company_id;
  RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Unassign driver from truck
CREATE OR REPLACE FUNCTION unassign_driver(p_driver_id UUID, p_company_id UUID)
RETURNS boolean AS $$
DECLARE
  v_truck_id UUID;
BEGIN
  -- Get the assigned truck ID
  SELECT assigned_truck_id INTO v_truck_id FROM drivers WHERE id = p_driver_id AND company_id = p_company_id;
  IF v_truck_id IS NOT NULL THEN
    UPDATE trucks SET driver_id = NULL WHERE id = v_truck_id AND company_id = p_company_id;
  END IF;
  UPDATE drivers SET assigned_truck_id = NULL, status = 'available' WHERE id = p_driver_id AND company_id = p_company_id;
  RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
