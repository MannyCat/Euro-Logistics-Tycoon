-- ============================================================
-- EURO LOGISTICS TYCOON — Full Database Schema
-- Run this in Supabase SQL Editor (https://supabase.com/dashboard)
-- Project: womtwysylililqudzaczne
-- ============================================================

-- Drop all existing tables to ensure clean migration
DROP TABLE IF EXISTS transactions CASCADE;
DROP TABLE IF EXISTS game_config CASCADE;
DROP TABLE IF EXISTS contracts CASCADE;
DROP TABLE IF EXISTS drivers CASCADE;
DROP TABLE IF EXISTS trucks CASCADE;
DROP TABLE IF EXISTS warehouses CASCADE;
DROP TABLE IF EXISTS companies CASCADE;
DROP TABLE IF EXISTS cities CASCADE;

-- Drop existing functions
DROP FUNCTION IF EXISTS create_company_for_user() CASCADE;
DROP FUNCTION IF EXISTS generate_contracts() CASCADE;
DROP FUNCTION IF EXISTS accept_contract(UUID, UUID, UUID) CASCADE;
DROP FUNCTION IF EXISTS complete_expired_contracts() CASCADE;
DROP FUNCTION IF EXISTS find_nearest_idle_truck(UUID, INTEGER) CASCADE;

-- Drop existing triggers
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- ===== 1. CITIES =====
CREATE TABLE cities (
  id SERIAL PRIMARY KEY,
  slug TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  country TEXT NOT NULL,
  latitude DOUBLE PRECISION NOT NULL,
  longitude DOUBLE PRECISION NOT NULL,
  population INTEGER DEFAULT 100000,
  warehouse_cost INTEGER DEFAULT 500000,
  depot_fee INTEGER DEFAULT 500,
  has_depot BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Seed 15 ETS2 cities with real-world coordinates
INSERT INTO cities (slug, name, country, latitude, longitude, population, warehouse_cost, depot_fee) VALUES
  ('london',    'London',      'UK',          51.5074,  -0.1278, 8982000, 800000, 800),
  ('paris',     'Paris',       'France',      48.8566,   2.3522, 2161000, 700000, 700),
  ('berlin',    'Berlin',      'Germany',     52.5200,  13.4050, 3645000, 600000, 600),
  ('amsterdam', 'Amsterdam',   'Netherlands', 52.3676,   4.9041,  872000, 550000, 550),
  ('brussels',  'Brussels',    'Belgium',     50.8503,   4.3517, 1200000, 500000, 500),
  ('frankfurt', 'Frankfurt',   'Germany',     50.1109,   8.6821,  753056, 550000, 550),
  ('zurich',    'Zurich',      'Switzerland', 47.3769,   8.5417,  434000, 700000, 700),
  ('madrid',    'Madrid',      'Spain',       40.4168,  -3.7038, 3223000, 600000, 600),
  ('rome',      'Rome',        'Italy',       41.9028,  12.4964, 2873000, 650000, 650),
  ('warsaw',    'Warsaw',      'Poland',      52.2297,  21.0122, 1794000, 450000, 450),
  ('vienna',    'Vienna',      'Austria',     48.2082,  16.3738, 1911000, 550000, 550),
  ('prague',    'Prague',      'Czech Rep.',  50.0755,  14.4378, 1309000, 450000, 450),
  ('budapest',  'Budapest',    'Hungary',     47.4979,  19.0402, 1752000, 400000, 400),
  ('stockholm', 'Stockholm',   'Sweden',      59.3293,  18.0686,  975000, 600000, 600),
  ('oslo',      'Oslo',        'Norway',      59.9139,  10.7522,  693000,  650000, 650);

-- ===== 2. COMPANIES =====
CREATE TABLE companies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  money BIGINT DEFAULT 1000000,
  reputation INTEGER DEFAULT 50,
  level INTEGER DEFAULT 1,
  xp INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(owner_id)
);

-- ===== 3. WAREHOUSES (branches in cities) =====
CREATE TABLE warehouses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID REFERENCES companies(id) ON DELETE CASCADE,
  city_id INTEGER REFERENCES cities(id) ON DELETE CASCADE,
  level INTEGER DEFAULT 1,
  capacity INTEGER DEFAULT 50,
  is_active BOOLEAN DEFAULT true,
  purchased_at TIMESTAMPTZ DEFAULT NOW()
);

-- ===== 4. CONTRACTS (before trucks so FK works) =====
CREATE TABLE contracts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  origin_city_id INTEGER REFERENCES cities(id),
  destination_city_id INTEGER REFERENCES cities(id),
  cargo_type TEXT NOT NULL,
  cargo_weight INTEGER DEFAULT 10,
  reward INTEGER NOT NULL,
  deadline_hours INTEGER DEFAULT 48,
  status TEXT NOT NULL DEFAULT 'available',
  assigned_company_id UUID REFERENCES companies(id),
  assigned_truck_id UUID,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '72 hours')
);

-- ===== 5. TRUCKS (after contracts so FK to contracts.id works) =====
CREATE TABLE trucks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID REFERENCES companies(id) ON DELETE CASCADE,
  driver_id UUID,
  truck_type TEXT NOT NULL DEFAULT 'light',
  name TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'idle',
  condition_pct INTEGER DEFAULT 100,
  fuel_level DOUBLE PRECISION DEFAULT 100.0,
  max_fuel DOUBLE PRECISION DEFAULT 120.0,
  current_city_id INTEGER REFERENCES cities(id),
  origin_city_id INTEGER REFERENCES cities(id),
  destination_city_id INTEGER REFERENCES cities(id),
  contract_id UUID REFERENCES contracts(id) ON DELETE SET NULL,
  departure_time TIMESTAMPTZ,
  estimated_arrival TIMESTAMPTZ,
  purchase_price INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ===== 6. DRIVERS =====
CREATE TABLE drivers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID REFERENCES companies(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  skill_level INTEGER DEFAULT 1,
  salary_daily INTEGER DEFAULT 300,
  status TEXT NOT NULL DEFAULT 'available',
  assigned_truck_id UUID REFERENCES trucks(id) ON DELETE SET NULL,
  hired_at TIMESTAMPTZ DEFAULT NOW()
);

-- ===== 7. TRANSACTIONS (ledger) =====
CREATE TABLE transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID REFERENCES companies(id) ON DELETE CASCADE,
  type TEXT NOT NULL,
  description TEXT NOT NULL,
  amount BIGINT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ===== 8. GAME CONFIG =====
CREATE TABLE game_config (
  id INTEGER PRIMARY KEY DEFAULT 1 CHECK (id = 1),
  contracts_generation_interval INTEGER DEFAULT 30,
  max_contracts INTEGER DEFAULT 50,
  truck_types JSONB DEFAULT '[
    {"type":"light","name":"Mercedes Actros L","price":80000,"speed":85,"fuel":120,"capacity":12},
    {"type":"medium","name":"Volvo FH16","price":150000,"speed":80,"fuel":200,"capacity":22},
    {"type":"heavy","name":"Scania R730","price":250000,"speed":75,"fuel":300,"capacity":30},
    {"type":"special","name":"MAN TGX 41.680","price":400000,"speed":70,"fuel":400,"capacity":44}
  ]'::jsonb,
  cargo_types JSONB DEFAULT '["FMCG","Machinery","Food","Electronics","Building Materials","Chemicals"]'::jsonb
);
INSERT INTO game_config (id) VALUES (1);

-- ============================================================
-- RLS POLICIES
-- ============================================================

ALTER TABLE cities ENABLE ROW LEVEL SECURITY;
ALTER TABLE companies ENABLE ROW LEVEL SECURITY;
ALTER TABLE warehouses ENABLE ROW LEVEL SECURITY;
ALTER TABLE trucks ENABLE ROW LEVEL SECURITY;
ALTER TABLE drivers ENABLE ROW LEVEL SECURITY;
ALTER TABLE contracts ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE game_config ENABLE ROW LEVEL SECURITY;

-- Cities: readable by all
CREATE POLICY "cities_read" ON cities FOR SELECT USING (true);

-- Companies: read all, manage own
CREATE POLICY "companies_read" ON companies FOR SELECT USING (true);
CREATE POLICY "companies_insert" ON companies FOR INSERT WITH CHECK (auth.uid() = owner_id);
CREATE POLICY "companies_update" ON companies FOR UPDATE USING (auth.uid() = owner_id);

-- Warehouses: read all, manage own
CREATE POLICY "warehouses_read" ON warehouses FOR SELECT USING (true);
CREATE POLICY "warehouses_insert" ON warehouses FOR INSERT WITH CHECK (
  auth.uid() IN (SELECT owner_id FROM companies WHERE id = company_id)
);
CREATE POLICY "warehouses_update" ON warehouses FOR UPDATE USING (
  auth.uid() IN (SELECT owner_id FROM companies WHERE id = company_id)
);
CREATE POLICY "warehouses_delete" ON warehouses FOR DELETE USING (
  auth.uid() IN (SELECT owner_id FROM companies WHERE id = company_id)
);

-- Trucks: read all, manage own
CREATE POLICY "trucks_read" ON trucks FOR SELECT USING (true);
CREATE POLICY "trucks_insert" ON trucks FOR INSERT WITH CHECK (
  auth.uid() IN (SELECT owner_id FROM companies WHERE id = company_id)
);
CREATE POLICY "trucks_update" ON trucks FOR UPDATE USING (
  auth.uid() IN (SELECT owner_id FROM companies WHERE id = company_id)
);

-- Drivers: read all, manage own
CREATE POLICY "drivers_read" ON drivers FOR SELECT USING (true);
CREATE POLICY "drivers_insert" ON drivers FOR INSERT WITH CHECK (
  auth.uid() IN (SELECT owner_id FROM companies WHERE id = company_id)
);
CREATE POLICY "drivers_update" ON drivers FOR UPDATE USING (
  auth.uid() IN (SELECT owner_id FROM companies WHERE id = company_id)
);
CREATE POLICY "drivers_delete" ON drivers FOR DELETE USING (
  auth.uid() IN (SELECT owner_id FROM companies WHERE id = company_id)
);

-- Contracts: read all, update own
CREATE POLICY "contracts_read" ON contracts FOR SELECT USING (true);
CREATE POLICY "contracts_update" ON contracts FOR UPDATE USING (
  auth.uid() IN (SELECT owner_id FROM companies WHERE id = assigned_company_id)
);

-- Transactions: read own, insert own
CREATE POLICY "transactions_read" ON transactions FOR SELECT USING (
  auth.uid() IN (SELECT owner_id FROM companies WHERE id = company_id)
);
CREATE POLICY "transactions_insert" ON transactions FOR INSERT WITH CHECK (
  auth.uid() IN (SELECT owner_id FROM companies WHERE id = company_id)
);

-- Game config: readable by all
CREATE POLICY "config_read" ON game_config FOR SELECT USING (true);

-- ============================================================
-- HELPER: Haversine distance (km)
-- ============================================================
CREATE OR REPLACE FUNCTION haversine_km(lat1 DOUBLE PRECISION, lon1 DOUBLE PRECISION, lat2 DOUBLE PRECISION, lon2 DOUBLE PRECISION)
RETURNS DOUBLE PRECISION AS $$
DECLARE
  R DOUBLE PRECISION := 6371.0;
  d_lat DOUBLE PRECISION;
  d_lon DOUBLE PRECISION;
  a DOUBLE PRECISION;
BEGIN
  d_lat := (lat2 - lat1) * PI() / 180;
  d_lon := (lon2 - lon1) * PI() / 180;
  a := sin(d_lat / 2) * sin(d_lat / 2) +
       cos(lat1 * PI() / 180) * cos(lat2 * PI() / 180) *
       sin(d_lon / 2) * sin(d_lon / 2);
  RETURN R * 2 * atan2(sqrt(a), sqrt(1 - a));
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- ============================================================
-- STORED FUNCTIONS
-- ============================================================

-- Create company for new user (called on sign-up trigger)
CREATE OR REPLACE FUNCTION create_company_for_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO companies (owner_id, name, money)
  VALUES (NEW.id, COALESCE(
    NEW.raw_user_meta_data->>'company_name',
    'New Logistics Co.'
  ), 1000000);

  -- Give a starter truck in London
  INSERT INTO trucks (company_id, truck_type, name, status, condition_pct, fuel_level, max_fuel, current_city_id, purchase_price)
  VALUES (
    (SELECT id FROM companies WHERE owner_id = NEW.id),
    'light', 'Starter Truck', 'idle', 100, 100.0, 120.0, 1, 0
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger: auto-create company + starter truck on user signup
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION create_company_for_user();

-- Generate contracts automatically
CREATE OR REPLACE FUNCTION generate_contracts()
RETURNS void AS $$
DECLARE
  v_origin_id INTEGER;
  v_dest_id INTEGER;
  v_cargo TEXT;
  v_dist DOUBLE PRECISION;
  v_reward INTEGER;
  v_cargo_arr JSONB;
  v_arr_len INTEGER;
BEGIN
  SELECT cargo_types INTO v_cargo_arr FROM game_config WHERE id = 1;
  v_arr_len := COALESCE(jsonb_array_length(v_cargo_arr), 6);

  -- Generate 3 random contracts
  FOR i IN 1..3 LOOP
    SELECT id INTO v_origin_id FROM cities ORDER BY RANDOM() LIMIT 1;
    SELECT id INTO v_dest_id FROM cities ORDER BY RANDOM() LIMIT 1;
    WHILE v_dest_id = v_origin_id LOOP
      SELECT id INTO v_dest_id FROM cities ORDER BY RANDOM() LIMIT 1;
    END LOOP;

    -- Pick random cargo type
    SELECT v_cargo_arr->>(floor(random() * v_arr_len)::INT) INTO v_cargo;

    -- Calculate real distance using haversine
    SELECT haversine_km(o.latitude, o.longitude, d.latitude, d.longitude) INTO v_dist
    FROM cities o, cities d WHERE o.id = v_origin_id AND d.id = v_dest_id;

    -- Reward: distance * 15-25 per km + random bonus
    v_reward := GREATEST((ROUND(v_dist) * (15 + (random() * 10)::INT))::INT, 500);

    INSERT INTO contracts (origin_city_id, destination_city_id, cargo_type, cargo_weight, reward)
    VALUES (v_origin_id, v_dest_id, v_cargo, 5 + (random() * 35)::INT, v_reward);
  END LOOP;

  -- Keep max contracts limit: remove oldest available contracts
  DELETE FROM contracts
  WHERE status = 'available'
  AND created_at < (
    SELECT created_at FROM contracts
    WHERE status = 'available'
    ORDER BY created_at DESC OFFSET (SELECT max_contracts FROM game_config WHERE id = 1)
    LIMIT 1
  )
  AND (SELECT COUNT(*) FROM contracts WHERE status = 'available') > (SELECT max_contracts FROM game_config WHERE id = 1);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Find nearest idle truck to a city (for auto-assignment)
CREATE OR REPLACE FUNCTION find_nearest_idle_truck(p_company_id UUID, p_city_id INTEGER)
RETURNS UUID AS $$
DECLARE
  v_truck_id UUID;
  v_city RECORD;
BEGIN
  SELECT * INTO v_city FROM cities WHERE id = p_city_id;
  IF NOT FOUND THEN RETURN NULL; END IF;

  SELECT t.id INTO v_truck_id
  FROM trucks t
  JOIN cities c ON c.id = t.current_city_id
  WHERE t.company_id = p_company_id
    AND t.status = 'idle'
    AND t.condition_pct >= 20
  ORDER BY haversine_km(v_city.latitude, v_city.longitude, c.latitude, c.longitude) ASC
  LIMIT 1;

  RETURN v_truck_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Accept contract: auto-assign nearest truck, update statuses, calc ETA
CREATE OR REPLACE FUNCTION accept_contract(
  p_contract_id UUID,
  p_truck_id UUID,
  p_company_id UUID
)
RETURNS boolean AS $$
DECLARE
  v_contract RECORD;
  v_truck RECORD;
  v_truck_id UUID;
  v_truck_type JSONB;
  v_speed INTEGER;
  v_dist DOUBLE PRECISION;
  v_eta TIMESTAMPTZ;
  v_fuel_cost DOUBLE PRECISION;
BEGIN
  -- Get contract
  SELECT * INTO v_contract FROM contracts WHERE id = p_contract_id AND status = 'available';
  IF NOT FOUND THEN RETURN false; END IF;

  -- If truck not specified, find nearest idle truck
  IF p_truck_id IS NULL THEN
    v_truck_id := find_nearest_idle_truck(p_company_id, v_contract.origin_city_id);
    IF v_truck_id IS NULL THEN RETURN false; END IF;
  END IF;

  -- Get truck
  SELECT * INTO v_truck FROM trucks WHERE id = v_truck_id AND status = 'idle' AND company_id = p_company_id;
  IF NOT FOUND THEN RETURN false; END IF;

  -- Get truck speed from config
  SELECT truck_types INTO v_truck_type FROM game_config WHERE id = 1;
  v_speed := 80; -- default
  IF v_truck_type IS NOT NULL THEN
    SELECT (elem->>'speed')::INT INTO v_speed
    FROM jsonb_array_elements(v_truck_type) AS elem
    WHERE elem->>'type' = v_truck.truck_type
    LIMIT 1;
    IF v_speed IS NULL THEN v_speed := 80; END IF;
  END IF;

  -- Calculate real distance using haversine
  SELECT haversine_km(o.latitude, o.longitude, d.latitude, d.longitude) INTO v_dist
  FROM cities o, cities d WHERE o.id = v_contract.origin_city_id AND d.id = v_contract.destination_city_id;

  -- ETA: distance / speed (hours)
  v_eta := NOW() + (v_dist / v_speed) * INTERVAL '1 hour';

  -- Fuel cost: distance * 2
  v_fuel_cost := v_dist * 2;

  -- Update contract
  UPDATE contracts SET
    status = 'accepted',
    assigned_company_id = p_company_id,
    assigned_truck_id = v_truck_id
  WHERE id = p_contract_id;

  -- Update truck
  UPDATE trucks SET
    status = 'loading',
    origin_city_id = v_contract.origin_city_id,
    destination_city_id = v_contract.destination_city_id,
    contract_id = p_contract_id,
    departure_time = NOW(),
    estimated_arrival = v_eta,
    fuel_level = GREATEST(fuel_level - v_fuel_cost * 0.1, 0)
  WHERE id = v_truck_id;

  -- Record transaction (fuel cost)
  INSERT INTO transactions (company_id, type, description, amount)
  VALUES (p_company_id, 'contract_accepted',
    'Контракт: ' || v_contract.cargo_type || ' (' || ROUND(v_dist) || 'km)',
    -(ROUND(v_fuel_cost))::BIGINT
  );

  RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Complete expired contracts + transition loading → in_transit
CREATE OR REPLACE FUNCTION complete_expired_contracts()
RETURNS void AS $$
DECLARE
  v_contract RECORD;
  v_xp_gain INTEGER;
  v_new_level INTEGER;
BEGIN
  -- Complete contracts where truck has arrived
  FOR v_contract IN
    SELECT c.id, c.assigned_company_id, c.assigned_truck_id, c.reward,
           c.destination_city_id, c.cargo_type
    FROM contracts c
    JOIN trucks t ON t.id = c.assigned_truck_id
    WHERE c.status = 'accepted'
      AND t.status IN ('in_transit', 'loading')
      AND t.estimated_arrival IS NOT NULL
      AND t.estimated_arrival < NOW()
  LOOP
    -- XP from reward
    v_xp_gain := (v_contract.reward / 100)::INT;

    -- Complete contract
    UPDATE contracts SET status = 'completed' WHERE id = v_contract.id;

    -- Reward company
    UPDATE companies SET
      money = money + v_contract.reward,
      xp = xp + v_xp_gain,
      reputation = LEAST(reputation + 1, 100)
    WHERE id = v_contract.assigned_company_id;

    -- Update truck: deliver to destination city, reduce condition
    UPDATE trucks SET
      status = 'idle',
      current_city_id = v_contract.destination_city_id,
      origin_city_id = NULL,
      destination_city_id = NULL,
      contract_id = NULL,
      departure_time = NULL,
      estimated_arrival = NULL,
      condition_pct = GREATEST(condition_pct - (2 + (random() * 3)::INT), 10)
    WHERE id = v_contract.assigned_truck_id;

    -- Record transaction
    INSERT INTO transactions (company_id, type, description, amount)
    VALUES (v_contract.assigned_company_id, 'contract_completed',
      'Доставка: ' || v_contract.cargo_type, v_contract.reward::BIGINT
    );

    -- Level up check: every 1000 XP
    UPDATE companies SET level = level + 1
    WHERE id = v_contract.assigned_company_id
      AND xp >= level * 1000;
  END LOOP;

  -- Transition loading → in_transit after 30 seconds
  UPDATE trucks SET status = 'in_transit'
  WHERE status = 'loading'
    AND departure_time IS NOT NULL
    AND departure_time < NOW() - INTERVAL '30 seconds';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- SEED: Generate initial contracts
-- ============================================================
SELECT generate_contracts();
SELECT generate_contracts();
SELECT generate_contracts();
SELECT generate_contracts();
SELECT generate_contracts();
SELECT generate_contracts();
SELECT generate_contracts();
SELECT generate_contracts();
SELECT generate_contracts();
SELECT generate_contracts();

-- ============================================================
-- REALTIME: Enable for contracts and trucks
-- ============================================================
ALTER PUBLICATION supabase_realtime ADD TABLE contracts;
ALTER PUBLICATION supabase_realtime ADD TABLE trucks;

-- ============================================================
-- CRON: Complete contracts every minute (via pg_cron)
-- ============================================================
-- Uncomment if pg_cron extension is enabled:
-- SELECT cron.schedule('complete_contracts', '* * * * *', 'SELECT complete_expired_contracts()');
