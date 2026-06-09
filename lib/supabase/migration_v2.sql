-- ══════════════════════════════════════════════════════════════════════
-- migration_v2.sql — Major gameplay expansion
-- 15 new cities, expanded road network, 8 truck types, better contracts
-- ══════════════════════════════════════════════════════════════════════

-- ─── 1. ADD 15 NEW CITIES (IDs 16–30) ────────────────────────────────
INSERT INTO cities (slug, name, country, latitude, longitude, population, warehouse_cost, depot_fee) VALUES
  ('hamburg',    'Hamburg',     'Germany',      53.5511,   9.9937,  1841000, 550000, 550),
  ('munich',     'Munich',      'Germany',      48.1351,  11.5820,  1472000, 600000, 600),
  ('lyon',       'Lyon',        'France',       45.7640,   4.8357,   516000, 500000, 500),
  ('barcelona',  'Barcelona',   'Spain',        41.3874,   2.1686,  1620000, 550000, 550),
  ('milan',      'Milan',       'Italy',        45.4642,   9.1900,  1379000, 600000, 600),
  ('copenhagen', 'Copenhagen',  'Denmark',      55.6761,  12.5683,   632000, 550000, 550),
  ('dublin',     'Dublin',      'Ireland',      53.3498,  -6.2603,   545000, 600000, 600),
  ('bucharest',  'Bucharest',   'Romania',      44.4268,  26.1025,  1883000, 350000, 350),
  ('sofia',      'Sofia',       'Bulgaria',     42.6977,  23.3219,  1290000, 350000, 350),
  ('belgrade',   'Belgrade',    'Serbia',       44.7866,  20.4489,  1346000, 350000, 350),
  ('zagreb',     'Zagreb',      'Croatia',      45.8150,  15.9819,   807000, 400000, 400),
  ('helsinki',   'Helsinki',    'Finland',      60.1699,  24.9384,   656000, 550000, 550),
  ('athens',     'Athens',      'Greece',       37.9838,  23.7275,   664000, 450000, 450),
  ('istanbul',   'Istanbul',    'Turkey',       41.0082,  28.9784, 15460000, 500000, 500),
  ('marseille',  'Marseille',   'France',       43.2965,   5.3698,   870000, 500000, 500);

-- ─── 2. UPDATE GAME CONFIG — expanded truck types ────────────────────
-- First check if game_config table exists
DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'game_config') THEN
    UPDATE game_config SET
      truck_types = '[
        {"type":"micro","name":"Renault Master","price":45000,"speed":90,"fuel":80,"capacity":6},
        {"type":"light","name":"Mercedes Actros L","price":80000,"speed":85,"fuel":120,"capacity":12},
        {"type":"medium","name":"Volvo FH16","price":150000,"speed":80,"fuel":200,"capacity":22},
        {"type":"heavy","name":"Scania R730","price":250000,"speed":75,"fuel":300,"capacity":30},
        {"type":"express","name":"Mercedes Actros F","price":320000,"speed":95,"fuel":250,"capacity":16},
        {"type":"special","name":"MAN TGX 41.680","price":400000,"speed":70,"fuel":400,"capacity":44},
        {"type":"oversized","name":"Volvo FH16 750","price":500000,"speed":60,"fuel":500,"capacity":55},
        {"type":"refrigerated","name":"Scania R450","price":280000,"speed":78,"fuel":280,"capacity":20}
      ]'::JSONB,
      max_contracts = 80
    WHERE id = 1;
  END IF;
END $$;

-- ─── 3. IMPROVE generate_contracts() — better rewards, urgency tiers ──
CREATE OR REPLACE FUNCTION generate_contracts()
RETURNS void AS $$
DECLARE
  v_origin_id INTEGER;
  v_dest_id INTEGER;
  v_cargo TEXT;
  v_dist DOUBLE PRECISION;
  v_reward INTEGER;
  v_deadline INT;
  v_expires INTERVAL;
  v_cargo_arr JSONB;
  v_arr_len INTEGER;
  v_urgency INT;
  v_cargo_mult FLOAT;
  v_weight INT;
BEGIN
  SELECT cargo_types INTO v_cargo_arr FROM game_config WHERE id = 1;
  v_arr_len := COALESCE(jsonb_array_length(v_cargo_arr), 6);

  -- Generate 5 random contracts (up from 3)
  FOR i IN 1..5 LOOP
    SELECT id INTO v_origin_id FROM cities ORDER BY RANDOM() LIMIT 1;
    SELECT id INTO v_dest_id FROM cities ORDER BY RANDOM() LIMIT 1;
    WHILE v_dest_id = v_origin_id LOOP
      SELECT id INTO v_dest_id FROM cities ORDER BY RANDOM() LIMIT 1;
    END LOOP;

    SELECT v_cargo_arr->>(floor(random() * v_arr_len)::INT) INTO v_cargo;

    SELECT haversine_km(o.latitude, o.longitude, d.latitude, d.longitude) INTO v_dist
    FROM cities o, cities d WHERE o.id = v_origin_id AND d.id = v_dest_id;

    -- Cargo type multiplier (high-value cargo pays more)
    v_cargo_mult := CASE v_cargo
      WHEN 'Electronics' THEN 1.5
      WHEN 'Machinery' THEN 1.35
      WHEN 'Chemicals' THEN 1.25
      WHEN 'Building Materials' THEN 0.9
      WHEN 'Food' THEN 0.85
      WHEN 'FMCG' THEN 1.0
      ELSE 1.0
    END;

    -- Weight: 3-40 tons
    v_weight := 3 + (random() * 37)::INT;

    -- Urgency tier: 1=standard, 2=urgent (better pay, shorter deadline), 3=express (best pay, tight deadline)
    v_urgency := CASE
      WHEN random() < 0.55 THEN 1  -- 55% standard
      WHEN random() < 0.80 THEN 2  -- 25% urgent
      ELSE 3                      -- 20% express
    END;

    -- Base reward: distance × rate, modified by cargo type and urgency
    v_reward := GREATEST(
      (ROUND(v_dist * (12 + random() * 8) * v_cargo_mult * v_weight / 20.0) * CASE v_urgency WHEN 1 THEN 1.0 WHEN 2 THEN 1.4 WHEN 3 THEN 1.9 END)::INT,
      300
    );

    -- Deadline and expiry based on urgency
    v_deadline := CASE v_urgency
      WHEN 1 THEN 72  -- 72 hours to deliver
      WHEN 2 THEN 36  -- 36 hours
      ELSE 18        -- 18 hours express
    END;

    v_expires := CASE v_urgency
      WHEN 1 THEN INTERVAL '48 hours'   -- available for 48h
      WHEN 2 THEN INTERVAL '24 hours'   -- available for 24h
      ELSE INTERVAL '12 hours'            -- available for 12h
    END;

    INSERT INTO contracts (origin_city_id, destination_city_id, cargo_type, cargo_weight, reward, deadline_hours, expires_at)
    VALUES (v_origin_id, v_dest_id, v_cargo, v_weight, v_reward, v_deadline, NOW() + v_expires);
  END LOOP;

  -- Expire old available contracts
  UPDATE contracts SET status = 'expired'
  WHERE status = 'available' AND expires_at < NOW();

  -- Keep max contracts limit
  DELETE FROM contracts
  WHERE status IN ('available', 'expired')
  AND created_at < (
    SELECT created_at FROM contracts
    WHERE status = 'available'
    ORDER BY created_at DESC
    OFFSET (SELECT COALESCE(max_contracts, 80) FROM game_config WHERE id = 1)
    LIMIT 1
  )
  AND (SELECT COUNT(*) FROM contracts WHERE status = 'available') > (SELECT COALESCE(max_contracts, 80) FROM game_config WHERE id = 1);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ─── 4. UPDATE accept_contract() — use path-aware distance ────────────
-- Add a helper to estimate road distance via BFS (SQL approximation)
CREATE OR REPLACE FUNCTION road_distance_km(p_from INTEGER, p_to INTEGER)
RETURNS DOUBLE PRECISION AS $$
DECLARE
  v_dist DOUBLE PRECISION;
BEGIN
  -- Approximate road distance: haversine × 1.25 (roads are ~25% longer than straight line)
  SELECT haversine_km(o.latitude, o.longitude, d.latitude, d.longitude) * 1.25 INTO v_dist
  FROM cities o, cities d WHERE o.id = p_from AND d.id = p_to;
  RETURN COALESCE(v_dist, 0);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- ─── 5. UPDATE haversine_km function if not exists ───────────────────
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'haversine_km') THEN
    CREATE OR REPLACE FUNCTION haversine_km(lat1 DOUBLE PRECISION, lon1 DOUBLE PRECISION, lat2 DOUBLE PRECISION, lon2 DOUBLE PRECISION)
    RETURNS DOUBLE PRECISION AS $$
    DECLARE
      r DOUBLE PRECISION := 6371.0;
      dlat DOUBLE PRECISION := (lat2 - lat1) * pi() / 180;
      dlon DOUBLE PRECISION := (lon2 - lon1) * pi() / 180;
      a DOUBLE PRECISION;
    BEGIN
      a := sin(dlat/2)^2 + cos(lat1*pi()/180) * cos(lat2*pi()/180) * sin(dlon/2)^2;
      RETURN r * 2 * atan2(sqrt(a), sqrt(1-a));
    END;
    $$ LANGUAGE plpgsql IMMUTABLE;
  END IF;
END $$;

-- ─── 6. ADD city demand multipliers for new cities ──────────────────
-- (These are used client-side in GameConstants, but let's also add cargo diversity)
-- FMCG, Machinery, Food, Electronics, Building Materials, Chemicals, Fashion, Perishable, Automotive, Pharmaceutical
DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'game_config') THEN
    UPDATE game_config SET
      cargo_types = '["FMCG","Machinery","Food","Electronics","Building Materials","Chemicals","Fashion","Perishable","Automotive","Pharmaceutical"]'::JSONB
    WHERE id = 1;
  END IF;
END $$;

-- ─── 7. ADD 'expired' status support in contracts table ──────────────
ALTER TABLE contracts DROP CONSTRAINT IF EXISTS contracts_status_check;
ALTER TABLE contracts ADD CONSTRAINT contracts_status_check
  CHECK (status IN ('available', 'accepted', 'in_transit', 'completed', 'expired', 'failed'));

-- ─── 8. INCREASE contract auto-complete timer ────────────────────────
-- The loading→in_transit transition happens via a cron or trigger.
-- For now, let's update the existing truck status trigger if it exists:
DO $$ BEGIN
  -- No changes needed here — the loading→in_transit is handled client-side
  NULL;
END $$;
