-- Truck Upgrades System Migration
-- Apply via Supabase Dashboard SQL Editor

-- Add upgrade columns to trucks table
ALTER TABLE trucks ADD COLUMN IF NOT EXISTS engine_level INTEGER DEFAULT 0;    -- 0-3, speed bonus: +10/20/30%
ALTER TABLE trucks ADD COLUMN IF NOT EXISTS tank_level INTEGER DEFAULT 0;     -- 0-3, fuel capacity: +20/40/60%
ALTER TABLE trucks ADD COLUMN IF NOT EXISTS cabin_level INTEGER DEFAULT 0;     -- 0-3, reliability: less condition loss
ALTER TABLE trucks ADD COLUMN IF NOT EXISTS paint_color TEXT DEFAULT 'default'; -- 'default', 'red', 'blue', 'green', 'gold', 'black', 'white', 'purple'

-- Upgrade costs
-- Engine: 5000/15000/40000
-- Tank: 3000/8000/20000
-- Cabin: 4000/12000/30000
-- Paint: 2000 each

CREATE OR REPLACE FUNCTION upgrade_truck(
  p_truck_id UUID,
  p_company_id UUID,
  p_upgrade_type TEXT, -- 'engine', 'tank', 'cabin', 'paint'
  p_value TEXT -- level number as text for engine/tank/cabin, color name for paint
) RETURNS boolean AS $$
DECLARE
  v_cost INTEGER;
  v_current_level INTEGER;
BEGIN
  -- Verify ownership
  IF NOT EXISTS (SELECT 1 FROM trucks WHERE id = p_truck_id AND company_id = p_company_id) THEN
    RAISE EXCEPTION 'Грузовик не найден';
  END IF;

  IF p_upgrade_type = 'paint' THEN
    v_cost := 2000;
    IF (SELECT money FROM companies WHERE id = p_company_id) < v_cost THEN
      RAISE EXCEPTION 'Недостаточно средств';
    END IF;
    UPDATE trucks SET paint_color = p_value WHERE id = p_truck_id;
    UPDATE companies SET money = money - v_cost WHERE id = p_company_id;
    INSERT INTO transactions (company_id, type, description, amount)
    VALUES (p_company_id, 'upgrade', 'Покраска: ' || p_value, -v_cost);
    RETURN true;
  END IF;

  v_current_level := CASE p_upgrade_type
    WHEN 'engine' THEN (SELECT engine_level FROM trucks WHERE id = p_truck_id)
    WHEN 'tank' THEN (SELECT tank_level FROM trucks WHERE id = p_truck_id)
    WHEN 'cabin' THEN (SELECT cabin_level FROM trucks WHERE id = p_truck_id)
    ELSE 0
  END;

  IF v_current_level >= 3 THEN
    RAISE EXCEPTION 'Уже максимальный уровень';
  END IF;

  v_cost := CASE p_upgrade_type
    WHEN 'engine' THEN ARRAY[5000, 15000, 40000][v_current_level + 1]
    WHEN 'tank' THEN ARRAY[3000, 8000, 20000][v_current_level + 1]
    WHEN 'cabin' THEN ARRAY[4000, 12000, 30000][v_current_level + 1]
    ELSE 0
  END;

  IF (SELECT money FROM companies WHERE id = p_company_id) < v_cost THEN
    RAISE EXCEPTION 'Недостаточно средств (нужно: €' || v_cost || ')';
  END IF;

  CASE p_upgrade_type
    WHEN 'engine' THEN UPDATE trucks SET engine_level = engine_level + 1 WHERE id = p_truck_id;
    WHEN 'tank' THEN
      UPDATE trucks SET
        tank_level = tank_level + 1,
        max_fuel = max_fuel * 1.2  -- +20% per level
      WHERE id = p_truck_id;
    WHEN 'cabin' THEN UPDATE trucks SET cabin_level = cabin_level + 1 WHERE id = p_truck_id;
  END CASE;

  UPDATE companies SET money = money - v_cost WHERE id = p_company_id;
  INSERT INTO transactions (company_id, type, description, amount)
  VALUES (p_company_id, 'upgrade',
    CASE p_upgrade_type WHEN 'engine' THEN 'Двигатель ур.' WHEN 'tank' THEN 'Бак ур.' WHEN 'cabin' THEN 'Кабина ур.' END || (v_current_level + 1),
    -v_cost);

  RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
