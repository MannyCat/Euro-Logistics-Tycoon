-- ============================================================================
-- SHIPPING MANAGER - Complete Database Migration
-- Multiplayer Economic Shipping Strategy Game
-- Supabase (PostgreSQL + Auth + Realtime)
-- ============================================================================
-- Version: 1.0.0
-- Description: Drops all old tables (hacker game) and creates the full
--              Shipping Manager schema including tables, functions, triggers,
--              RLS policies, indexes, and seed data.
-- ============================================================================

BEGIN;

-- ============================================================================
-- PART 1: DROP ALL EXISTING TABLES
-- ============================================================================
-- We drop all existing tables to clear the old hacker game schema.
-- We must drop in reverse dependency order; use CASCADE to handle FKs.
-- We also drop custom types, functions, and triggers from the old schema.
-- ============================================================================

DO $$
DECLARE
    r RECORD;
BEGIN
    -- Drop all custom functions with parameters
    FOR r IN (SELECT p.proname::text, n.nspname::text,
                     pg_get_function_identity_arguments(p.oid) as args
              FROM pg_proc p
              JOIN pg_namespace n ON p.pronamespace = n.oid
              WHERE n.nspname = 'public') LOOP
        BEGIN
            EXECUTE format('DROP FUNCTION IF EXISTS %I.%I(%s) CASCADE',
                           r.nspname, r.proname, r.args);
        EXCEPTION WHEN OTHERS THEN
            NULL;
        END;
    END LOOP;
END $$;

-- Drop all existing tables
DROP TABLE IF EXISTS fuel_purchases CASCADE;
DROP TABLE IF EXISTS transactions CASCADE;
DROP TABLE IF EXISTS loans CASCADE;
DROP TABLE IF EXISTS employees CASCADE;
DROP TABLE IF EXISTS ship_market CASCADE;
DROP TABLE IF EXISTS factory_inventory CASCADE;
DROP TABLE IF EXISTS factories CASCADE;
DROP TABLE IF EXISTS voyages CASCADE;
DROP TABLE IF EXISTS port_distances CASCADE;
DROP TABLE IF EXISTS port_market CASCADE;
DROP TABLE IF EXISTS goods CASCADE;
DROP TABLE IF EXISTS ports CASCADE;
DROP TABLE IF EXISTS ships CASCADE;
DROP TABLE IF EXISTS ship_types CASCADE;
DROP TABLE IF EXISTS price_history CASCADE;
DROP TABLE IF EXISTS profiles CASCADE;

-- Drop any remaining tables from the old schema
DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN (SELECT tablename::text, schemaname::text
              FROM pg_tables
              WHERE schemaname = 'public') LOOP
        EXECUTE format('DROP TABLE IF EXISTS %I.%I CASCADE', r.schemaname, r.tablename);
    END LOOP;
END $$;

-- Drop old enums if they exist
DROP TYPE IF EXISTS ship_status_enum CASCADE;
DROP TYPE IF EXISTS voyage_status_enum CASCADE;
DROP TYPE IF EXISTS ship_type_category_enum CASCADE;
DROP TYPE IF EXISTS good_category_enum CASCADE;
DROP TYPE IF EXISTS employee_role_enum CASCADE;
DROP TYPE IF EXISTS loan_status_enum CASCADE;
DROP TYPE IF EXISTS transaction_type_enum CASCADE;
DROP TYPE IF EXISTS ship_market_status_enum CASCADE;
DROP TYPE IF EXISTS factory_type_enum CASCADE;

-- ============================================================================
-- PART 2: CREATE ENUMERATED TYPES
-- ============================================================================

CREATE TYPE ship_type_category_enum AS ENUM (
    'tanker', 'dry_bulk', 'container', 'ro_ro'
);

CREATE TYPE ship_status_enum AS ENUM (
    'idle', 'loading', 'in_transit', 'unloading', 'in_dock'
);

CREATE TYPE good_category_enum AS ENUM (
    'liquid', 'bulk', 'container', 'rollable'
);

CREATE TYPE voyage_status_enum AS ENUM (
    'planned', 'loading', 'in_transit', 'unloading', 'completed'
);

CREATE TYPE employee_role_enum AS ENUM (
    'agent', 'executive', 'crew_manager'
);

CREATE TYPE loan_status_enum AS ENUM (
    'active', 'paid_off', 'defaulted'
);

CREATE TYPE transaction_type_enum AS ENUM (
    'cargo_sale', 'cargo_buy', 'fuel', 'loan_payment', 'salary',
    'ship_purchase', 'ship_sale', 'factory_build', 'repair',
    'tax', 'credit', 'factory_output_sale', 'factory_input_buy',
    'ship_market_sale', 'ship_market_purchase', 'employee_hire',
    'loan_disbursement'
);

CREATE TYPE ship_market_status_enum AS ENUM (
    'listed', 'sold', 'cancelled'
);

-- ============================================================================
-- PART 3: CREATE TABLES
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 3.1 profiles — Company profile linked to auth.users
-- ----------------------------------------------------------------------------
CREATE TABLE profiles (
    id             UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    company_name   TEXT NOT NULL DEFAULT 'New Shipping Co.',
    money          NUMERIC(15,2) NOT NULL DEFAULT 500000.00,
    reputation     NUMERIC(5,2) NOT NULL DEFAULT 50.00,
    level          INTEGER NOT NULL DEFAULT 1,
    xp             INTEGER NOT NULL DEFAULT 0,
    is_online      BOOLEAN NOT NULL DEFAULT FALSE,
    last_seen_at   TIMESTAMPTZ,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_money_nonnegative CHECK (money >= 0),
    CONSTRAINT chk_reputation_range CHECK (reputation >= 0 AND reputation <= 100),
    CONSTRAINT chk_level_positive CHECK (level >= 1),
    CONSTRAINT chk_xp_nonnegative CHECK (xp >= 0)
);

COMMENT ON TABLE profiles IS 'Player company profiles linked to Supabase Auth accounts';
COMMENT ON COLUMN profiles.id IS 'References auth.users.id — the player account';
COMMENT ON COLUMN profiles.company_name IS 'Display name for the shipping company';
COMMENT ON COLUMN profiles.money IS 'Current cash balance (game currency)';
COMMENT ON COLUMN profiles.reputation IS 'Company reputation score 0-100, affects market prices and loan rates';
COMMENT ON COLUMN profiles.level IS 'Company level, unlocks features as it increases';
COMMENT ON COLUMN profiles.xp IS 'Experience points accumulated toward next level';

-- ----------------------------------------------------------------------------
-- 3.2 ship_types — Reference table of ship classes
-- ----------------------------------------------------------------------------
CREATE TABLE ship_types (
    id                SERIAL PRIMARY KEY,
    name              TEXT NOT NULL UNIQUE,
    type              ship_type_category_enum NOT NULL,
    dwt_capacity      NUMERIC(10,2) NOT NULL,
    teu_capacity      INTEGER NOT NULL DEFAULT 0,
    speed_knots       NUMERIC(5,2) NOT NULL,
    fuel_per_nm       NUMERIC(8,4) NOT NULL,
    base_price        NUMERIC(15,2) NOT NULL,
    max_age_years     INTEGER NOT NULL DEFAULT 25,
    crew_size         INTEGER NOT NULL DEFAULT 10,
    description       TEXT,

    CONSTRAINT chk_dwt_positive CHECK (dwt_capacity > 0),
    CONSTRAINT chk_speed_positive CHECK (speed_knots > 0),
    CONSTRAINT chk_fuel_positive CHECK (fuel_per_nm > 0),
    CONSTRAINT chk_base_price_positive CHECK (base_price > 0),
    CONSTRAINT chk_crew_positive CHECK (crew_size > 0)
);

COMMENT ON TABLE ship_types IS 'Reference data for ship classes available in the game';
COMMENT ON COLUMN ship_types.dwt_capacity IS 'Deadweight tonnage capacity in metric tonnes';
COMMENT ON COLUMN ship_types.teu_capacity IS 'Twenty-foot Equivalent Unit capacity (container ships only)';
COMMENT ON COLUMN ship_types.fuel_per_nm IS 'Fuel consumption in barrels per nautical mile';
COMMENT ON COLUMN ship_types.max_age_years IS 'Maximum operational lifespan before mandatory scrapping';

-- ----------------------------------------------------------------------------
-- 3.3 ports — World ports
-- ----------------------------------------------------------------------------
CREATE TABLE ports (
    id                     SERIAL PRIMARY KEY,
    name                   TEXT NOT NULL UNIQUE,
    country                TEXT NOT NULL,
    region                 TEXT NOT NULL,
    has_fuel_station       BOOLEAN NOT NULL DEFAULT TRUE,
    has_dry_dock           BOOLEAN NOT NULL DEFAULT FALSE,
    tax_rate               NUMERIC(5,4) NOT NULL DEFAULT 0.0500,
    daily_maintenance_cost NUMERIC(15,2) NOT NULL DEFAULT 500.00,
    latitude               NUMERIC(9,6) NOT NULL,
    longitude              NUMERIC(9,6) NOT NULL,
    description            TEXT,

    CONSTRAINT chk_tax_rate CHECK (tax_rate >= 0 AND tax_rate <= 1),
    CONSTRAINT chk_maintenance CHECK (daily_maintenance_cost >= 0)
);

COMMENT ON TABLE ports IS 'Real-world ports where ships can dock, trade, and refuel';
COMMENT ON COLUMN ports.tax_rate IS 'Port tax rate as decimal (e.g. 0.05 = 5%)';
COMMENT ON COLUMN ports.daily_maintenance_cost IS 'Base cost to keep a ship at this port per day';

-- ----------------------------------------------------------------------------
-- 3.4 goods — Cargo types
-- ----------------------------------------------------------------------------
CREATE TABLE goods (
    id              SERIAL PRIMARY KEY,
    name            TEXT NOT NULL UNIQUE,
    category        good_category_enum NOT NULL,
    unit            TEXT NOT NULL DEFAULT 'tonnes',
    base_price      NUMERIC(15,2) NOT NULL,
    volume_per_unit NUMERIC(8,4) NOT NULL DEFAULT 1.0000,
    description     TEXT,

    CONSTRAINT chk_base_price_positive CHECK (base_price > 0)
);

COMMENT ON TABLE goods IS 'Types of cargo that can be bought, sold, and transported';
COMMENT ON COLUMN goods.unit IS 'Unit of measurement: tonnes, TEU, or units';
COMMENT ON COLUMN goods.volume_per_unit IS 'Volume per unit of this good';

-- ----------------------------------------------------------------------------
-- 3.5 ships — Player-owned ships
-- ----------------------------------------------------------------------------
CREATE TABLE ships (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id        UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    ship_type_id    INTEGER NOT NULL REFERENCES ship_types(id) ON DELETE RESTRICT,
    name            TEXT NOT NULL DEFAULT 'Unnamed Vessel',
    age             NUMERIC(5,2) NOT NULL DEFAULT 0.00,
    condition_pct   NUMERIC(5,2) NOT NULL DEFAULT 100.00,
    status          ship_status_enum NOT NULL DEFAULT 'idle',
    current_port_id INTEGER REFERENCES ports(id) ON DELETE SET NULL,
    fuel_level      NUMERIC(10,2) NOT NULL DEFAULT 0.00,
    purchased_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    purchase_price  NUMERIC(15,2) NOT NULL,

    CONSTRAINT chk_age_nonnegative CHECK (age >= 0),
    CONSTRAINT chk_condition_range CHECK (condition_pct >= 0 AND condition_pct <= 100),
    CONSTRAINT chk_fuel_nonnegative CHECK (fuel_level >= 0)
);

COMMENT ON TABLE ships IS 'Player-owned vessels in the game world';
COMMENT ON COLUMN ships.age IS 'Current age of the ship in years';
COMMENT ON COLUMN ships.condition_pct IS 'Hull/structural condition percentage, affects speed and fuel efficiency';
COMMENT ON COLUMN ships.fuel_level IS 'Current fuel on board in barrels';

-- ----------------------------------------------------------------------------
-- 3.6 port_market — Dynamic prices per port per good
-- ----------------------------------------------------------------------------
CREATE TABLE port_market (
    port_id            INTEGER NOT NULL REFERENCES ports(id) ON DELETE CASCADE,
    good_id            INTEGER NOT NULL REFERENCES goods(id) ON DELETE CASCADE,
    buy_price          NUMERIC(15,2) NOT NULL,
    sell_price         NUMERIC(15,2) NOT NULL,
    available_quantity NUMERIC(12,2) NOT NULL DEFAULT 0,
    last_updated       TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    PRIMARY KEY (port_id, good_id),
    CONSTRAINT chk_buy_sell_sensible CHECK (sell_price >= buy_price * 0.5),
    CONSTRAINT chk_quantity_nonnegative CHECK (available_quantity >= 0)
);

COMMENT ON TABLE port_market IS 'Dynamic market prices per port/good pair — fluctuates over time';
COMMENT ON COLUMN port_market.buy_price IS 'Price to buy this good at this port (what player pays)';
COMMENT ON COLUMN port_market.sell_price IS 'Price to sell this good at this port (what player receives)';
COMMENT ON COLUMN port_market.available_quantity IS 'Current supply available for purchase';

-- ----------------------------------------------------------------------------
-- 3.7 port_distances — Distances between ports in nautical miles
-- ----------------------------------------------------------------------------
CREATE TABLE port_distances (
    port_a_id    INTEGER NOT NULL REFERENCES ports(id) ON DELETE CASCADE,
    port_b_id    INTEGER NOT NULL REFERENCES ports(id) ON DELETE CASCADE,
    distance_nm  NUMERIC(10,2) NOT NULL,

    PRIMARY KEY (port_a_id, port_b_id),
    CONSTRAINT chk_distance_positive CHECK (distance_nm > 0),
    CONSTRAINT chk_not_same_port CHECK (port_a_id != port_b_id)
);

COMMENT ON TABLE port_distances IS 'Pre-calculated distances between port pairs in nautical miles';
COMMENT ON COLUMN port_distances.distance_nm IS 'Great-circle distance in nautical miles';

-- ----------------------------------------------------------------------------
-- 3.8 voyages — Active ship voyages
-- ----------------------------------------------------------------------------
CREATE TABLE voyages (
    id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ship_id              UUID NOT NULL REFERENCES ships(id) ON DELETE CASCADE,
    origin_port_id       INTEGER NOT NULL REFERENCES ports(id) ON DELETE RESTRICT,
    destination_port_id  INTEGER NOT NULL REFERENCES ports(id) ON DELETE RESTRICT,
    cargo_good_id        INTEGER NOT NULL REFERENCES goods(id) ON DELETE RESTRICT,
    cargo_quantity       NUMERIC(12,2) NOT NULL,
    status               voyage_status_enum NOT NULL DEFAULT 'planned',
    departure_time       TIMESTAMPTZ,
    estimated_arrival    TIMESTAMPTZ,
    actual_arrival       TIMESTAMPTZ,
    fuel_consumed        NUMERIC(10,2) NOT NULL DEFAULT 0,
    revenue              NUMERIC(15,2) NOT NULL DEFAULT 0,
    cost                 NUMERIC(15,2) NOT NULL DEFAULT 0,

    CONSTRAINT chk_cargo_quantity CHECK (cargo_quantity >= 0),
    CONSTRAINT chk_revenue CHECK (revenue >= 0),
    CONSTRAINT chk_not_same_port CHECK (origin_port_id != destination_port_id)
);

COMMENT ON TABLE voyages IS 'Records of ship voyages between ports carrying cargo';
COMMENT ON COLUMN voyages.cargo_quantity IS 'Amount of cargo carried on this voyage';
COMMENT ON COLUMN voyages.fuel_consumed IS 'Total fuel consumed during the voyage';
COMMENT ON COLUMN voyages.revenue IS 'Money earned from selling cargo at destination';
COMMENT ON COLUMN voyages.cost IS 'Total cost of the voyage (fuel + port fees)';

-- ----------------------------------------------------------------------------
-- 3.9 factories — Production facilities in ports
-- ----------------------------------------------------------------------------
CREATE TABLE factories (
    id                       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id                 UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    port_id                  INTEGER NOT NULL REFERENCES ports(id) ON DELETE CASCADE,
    factory_type             TEXT NOT NULL,
    level                    INTEGER NOT NULL DEFAULT 1,
    efficiency_pct           NUMERIC(5,2) NOT NULL DEFAULT 100.00,
    input_goods              JSONB NOT NULL DEFAULT '[]'::jsonb,
    output_good_id           INTEGER NOT NULL REFERENCES goods(id) ON DELETE RESTRICT,
    output_quantity_per_cycle NUMERIC(12,2) NOT NULL,
    cycle_hours              NUMERIC(5,2) NOT NULL DEFAULT 24.00,
    is_running               BOOLEAN NOT NULL DEFAULT FALSE,
    last_cycle_time          TIMESTAMPTZ,
    build_cost               NUMERIC(15,2) NOT NULL DEFAULT 0,
    created_at               TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_level_positive CHECK (level >= 1 AND level <= 10),
    CONSTRAINT chk_efficiency CHECK (efficiency_pct > 0 AND efficiency_pct <= 150),
    CONSTRAINT chk_output_quantity CHECK (output_quantity_per_cycle > 0),
    CONSTRAINT chk_cycle_hours CHECK (cycle_hours > 0),
    CONSTRAINT chk_build_cost CHECK (build_cost >= 0)
);

COMMENT ON TABLE factories IS 'Production facilities that transform input goods into output goods';
COMMENT ON COLUMN factories.input_goods IS 'JSON array of {good_id, quantity_per_cycle} for required inputs';
COMMENT ON COLUMN factories.efficiency_pct IS 'Production efficiency percentage; affected by level and executives';
COMMENT ON COLUMN factories.cycle_hours IS 'Hours per production cycle';
COMMENT ON COLUMN factories.build_cost IS 'Cost to build/upgrade this factory';

-- ----------------------------------------------------------------------------
-- 3.10 factory_inventory — Factory stored goods
-- ----------------------------------------------------------------------------
CREATE TABLE factory_inventory (
    factory_id    UUID NOT NULL REFERENCES factories(id) ON DELETE CASCADE,
    good_id       INTEGER NOT NULL REFERENCES goods(id) ON DELETE CASCADE,
    quantity      NUMERIC(12,2) NOT NULL DEFAULT 0,

    PRIMARY KEY (factory_id, good_id),
    CONSTRAINT chk_quantity_nonnegative CHECK (quantity >= 0)
);

COMMENT ON TABLE factory_inventory IS 'Stores raw materials and finished goods held by factories';

-- ----------------------------------------------------------------------------
-- 3.11 ship_market — P2P ship listings
-- ----------------------------------------------------------------------------
CREATE TABLE ship_market (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    seller_id      UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    ship_id        UUID NOT NULL REFERENCES ships(id) ON DELETE CASCADE,
    asking_price   NUMERIC(15,2) NOT NULL,
    listed_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    status         ship_market_status_enum NOT NULL DEFAULT 'listed',

    CONSTRAINT chk_asking_price CHECK (asking_price > 0)
);

COMMENT ON TABLE ship_market IS 'Player-to-player ship marketplace listings';
COMMENT ON COLUMN ship_market.asking_price IS 'Price the seller is asking for the ship';

-- ----------------------------------------------------------------------------
-- 3.12 employees — Company personnel
-- ----------------------------------------------------------------------------
CREATE TABLE employees (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id       UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    name           TEXT NOT NULL,
    role           employee_role_enum NOT NULL,
    skill_level    INTEGER NOT NULL DEFAULT 1,
    salary_daily   NUMERIC(10,2) NOT NULL,
    hired_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    port_id        INTEGER REFERENCES ports(id) ON DELETE SET NULL,

    CONSTRAINT chk_skill CHECK (skill_level >= 1 AND skill_level <= 10),
    CONSTRAINT chk_salary CHECK (salary_daily >= 0)
);

COMMENT ON TABLE employees IS 'Personnel hired by players — agents, executives, crew managers';
COMMENT ON COLUMN employees.role IS 'agent: improves port relations/prices; executive: company efficiency; crew_manager: ship crew costs';
COMMENT ON COLUMN employees.port_id IS 'For agents: the port where they operate and provide bonuses';

-- ----------------------------------------------------------------------------
-- 3.13 loans — Bank loans
-- ----------------------------------------------------------------------------
CREATE TABLE loans (
    id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    borrower_id        UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    amount             NUMERIC(15,2) NOT NULL,
    interest_rate      NUMERIC(5,4) NOT NULL,
    monthly_payment    NUMERIC(15,2) NOT NULL,
    total_months       INTEGER NOT NULL,
    months_paid        INTEGER NOT NULL DEFAULT 0,
    remaining_balance  NUMERIC(15,2) NOT NULL,
    status             loan_status_enum NOT NULL DEFAULT 'active',
    taken_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_loan_amount CHECK (amount > 0),
    CONSTRAINT chk_interest CHECK (interest_rate >= 0),
    CONSTRAINT chk_monthly_payment CHECK (monthly_payment > 0),
    CONSTRAINT chk_total_months CHECK (total_months > 0),
    CONSTRAINT chk_months_paid CHECK (months_paid >= 0 AND months_paid <= total_months),
    CONSTRAINT chk_remaining CHECK (remaining_balance >= 0)
);

COMMENT ON TABLE loans IS 'Bank loans taken out by players for purchasing ships/factories';
COMMENT ON COLUMN loans.interest_rate IS 'Annual interest rate as decimal (e.g. 0.06 = 6%)';
COMMENT ON COLUMN loans.remaining_balance IS 'Outstanding principal remaining on the loan';

-- ----------------------------------------------------------------------------
-- 3.14 transactions — Financial ledger
-- ----------------------------------------------------------------------------
CREATE TABLE transactions (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    player_id      UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    type           transaction_type_enum NOT NULL,
    amount         NUMERIC(15,2) NOT NULL,
    description    TEXT,
    reference_type TEXT,
    reference_id   UUID,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_amount CHECK (amount != 0)
);

COMMENT ON TABLE transactions IS 'Complete financial transaction ledger for all players';
COMMENT ON COLUMN transactions.amount IS 'Transaction amount; positive = income, negative = expense';
COMMENT ON COLUMN transactions.reference_type IS 'Type of referenced entity (e.g. voyage, ship, factory)';
COMMENT ON COLUMN transactions.reference_id IS 'UUID of the referenced entity';

-- ----------------------------------------------------------------------------
-- 3.15 fuel_purchases — Fuel transaction records
-- ----------------------------------------------------------------------------
CREATE TABLE fuel_purchases (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    player_id       UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    port_id         INTEGER NOT NULL REFERENCES ports(id) ON DELETE CASCADE,
    ship_id         UUID NOT NULL REFERENCES ships(id) ON DELETE CASCADE,
    quantity_liters NUMERIC(12,2) NOT NULL,
    price_per_liter NUMERIC(10,4) NOT NULL,
    total_cost      NUMERIC(15,2) NOT NULL,
    purchased_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_fuel_qty CHECK (quantity_liters > 0),
    CONSTRAINT chk_fuel_price CHECK (price_per_liter > 0),
    CONSTRAINT chk_fuel_total CHECK (total_cost >= 0)
);

COMMENT ON TABLE fuel_purchases IS 'Detailed records of fuel purchases at ports';

-- ----------------------------------------------------------------------------
-- 3.16 price_history — Historical price tracking
-- ----------------------------------------------------------------------------
CREATE TABLE price_history (
    id           BIGSERIAL PRIMARY KEY,
    port_id      INTEGER NOT NULL REFERENCES ports(id) ON DELETE CASCADE,
    good_id      INTEGER NOT NULL REFERENCES goods(id) ON DELETE CASCADE,
    price        NUMERIC(15,2) NOT NULL,
    recorded_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_price_positive CHECK (price > 0)
);

COMMENT ON TABLE price_history IS 'Historical price data for market analysis and charts';

-- ============================================================================
-- PART 4: INDEXES
-- ============================================================================

-- profiles
CREATE INDEX idx_profiles_company_name ON profiles(company_name);
CREATE INDEX idx_profiles_level ON profiles(level);
CREATE INDEX idx_profiles_money ON profiles(money);

-- ships
CREATE INDEX idx_ships_owner_id ON ships(owner_id);
CREATE INDEX idx_ships_ship_type_id ON ships(ship_type_id);
CREATE INDEX idx_ships_status ON ships(status);
CREATE INDEX idx_ships_current_port ON ships(current_port_id);

-- ports
CREATE INDEX idx_ports_region ON ports(region);
CREATE INDEX idx_ports_country ON ports(country);
CREATE INDEX idx_ports_coordinates ON ports(latitude, longitude);

-- port_market
CREATE INDEX idx_port_market_good_id ON port_market(good_id);
CREATE INDEX idx_port_market_updated ON port_market(last_updated);

-- port_distances (reverse lookup)
CREATE INDEX idx_port_distances_b_a ON port_distances(port_b_id, port_a_id);

-- voyages
CREATE INDEX idx_voyages_ship_id ON voyages(ship_id);
CREATE INDEX idx_voyages_origin ON voyages(origin_port_id);
CREATE INDEX idx_voyages_destination ON voyages(destination_port_id);
CREATE INDEX idx_voyages_status ON voyages(status);
CREATE INDEX idx_voyages_estimated_arrival ON voyages(estimated_arrival);

-- factories
CREATE INDEX idx_factories_owner_id ON factories(owner_id);
CREATE INDEX idx_factories_port_id ON factories(port_id);
CREATE INDEX idx_factories_type ON factories(factory_type);

-- factory_inventory
CREATE INDEX idx_factory_inventory_good ON factory_inventory(good_id);

-- ship_market
CREATE INDEX idx_ship_market_seller ON ship_market(seller_id);
CREATE INDEX idx_ship_market_ship ON ship_market(ship_id);
CREATE INDEX idx_ship_market_status ON ship_market(status);

-- employees
CREATE INDEX idx_employees_owner ON employees(owner_id);
CREATE INDEX idx_employees_role ON employees(role);
CREATE INDEX idx_employees_port ON employees(port_id);

-- loans
CREATE INDEX idx_loans_borrower ON loans(borrower_id);
CREATE INDEX idx_loans_status ON loans(status);

-- transactions
CREATE INDEX idx_transactions_player ON transactions(player_id);
CREATE INDEX idx_transactions_type ON transactions(type);
CREATE INDEX idx_transactions_created ON transactions(created_at DESC);
CREATE INDEX idx_transactions_reference ON transactions(reference_type, reference_id);

-- fuel_purchases
CREATE INDEX idx_fuel_purchases_player ON fuel_purchases(player_id);
CREATE INDEX idx_fuel_purchases_ship ON fuel_purchases(ship_id);
CREATE INDEX idx_fuel_purchases_port ON fuel_purchases(port_id);

-- price_history
CREATE INDEX idx_price_history_port_good ON price_history(port_id, good_id);
CREATE INDEX idx_price_history_recorded ON price_history(recorded_at DESC);
CREATE INDEX idx_price_history_composite ON price_history(port_id, good_id, recorded_at DESC);

-- ============================================================================
-- PART 5: ROW LEVEL SECURITY (RLS)
-- ============================================================================

-- Enable RLS on all player-facing tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE ships ENABLE ROW LEVEL SECURITY;
ALTER TABLE voyages ENABLE ROW LEVEL SECURITY;
ALTER TABLE factories ENABLE ROW LEVEL SECURITY;
ALTER TABLE factory_inventory ENABLE ROW LEVEL SECURITY;
ALTER TABLE ship_market ENABLE ROW LEVEL SECURITY;
ALTER TABLE employees ENABLE ROW LEVEL SECURITY;
ALTER TABLE loans ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE fuel_purchases ENABLE ROW LEVEL SECURITY;

-- ----------------------------------------------------------------------------
-- 5.1 profiles RLS
-- ----------------------------------------------------------------------------
CREATE POLICY profiles_select_all ON profiles
    FOR SELECT USING (true);

CREATE POLICY profiles_update_own ON profiles
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY profiles_insert_own ON profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

-- ----------------------------------------------------------------------------
-- 5.2 ships RLS
-- ----------------------------------------------------------------------------
-- Everyone can see basic ship info (for port views)
CREATE POLICY ships_select_all ON ships
    FOR SELECT USING (true);

CREATE POLICY ships_insert_own ON ships
    FOR INSERT WITH CHECK (auth.uid() = owner_id);

CREATE POLICY ships_update_own ON ships
    FOR UPDATE USING (auth.uid() = owner_id);

CREATE POLICY ships_delete_own ON ships
    FOR DELETE USING (auth.uid() = owner_id);

-- ----------------------------------------------------------------------------
-- 5.3 voyages RLS
-- ----------------------------------------------------------------------------
CREATE POLICY voyages_select_all ON voyages
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM ships WHERE ships.id = voyages.ship_id AND ships.owner_id = auth.uid())
    );

CREATE POLICY voyages_insert_own ON voyages
    FOR INSERT WITH CHECK (
        EXISTS (SELECT 1 FROM ships WHERE ships.id = voyages.ship_id AND ships.owner_id = auth.uid())
    );

CREATE POLICY voyages_update_own ON voyages
    FOR UPDATE USING (
        EXISTS (SELECT 1 FROM ships WHERE ships.id = voyages.ship_id AND ships.owner_id = auth.uid())
    );

-- ----------------------------------------------------------------------------
-- 5.4 factories RLS
-- ----------------------------------------------------------------------------
-- Anyone can see factories at a port (public info)
CREATE POLICY factories_select_all ON factories
    FOR SELECT USING (true);

CREATE POLICY factories_insert_own ON factories
    FOR INSERT WITH CHECK (auth.uid() = owner_id);

CREATE POLICY factories_update_own ON factories
    FOR UPDATE USING (auth.uid() = owner_id);

CREATE POLICY factories_delete_own ON factories
    FOR DELETE USING (auth.uid() = owner_id);

-- ----------------------------------------------------------------------------
-- 5.5 factory_inventory RLS
-- ----------------------------------------------------------------------------
CREATE POLICY factory_inventory_select_own ON factory_inventory
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM factories WHERE factories.id = factory_inventory.factory_id AND factories.owner_id = auth.uid())
    );

CREATE POLICY factory_inventory_insert_own ON factory_inventory
    FOR INSERT WITH CHECK (
        EXISTS (SELECT 1 FROM factories WHERE factories.id = factory_inventory.factory_id AND factories.owner_id = auth.uid())
    );

CREATE POLICY factory_inventory_update_own ON factory_inventory
    FOR UPDATE USING (
        EXISTS (SELECT 1 FROM factories WHERE factories.id = factory_inventory.factory_id AND factories.owner_id = auth.uid())
    );

CREATE POLICY factory_inventory_delete_own ON factory_inventory
    FOR DELETE USING (
        EXISTS (SELECT 1 FROM factories WHERE factories.id = factory_inventory.factory_id AND factories.owner_id = auth.uid())
    );

-- ----------------------------------------------------------------------------
-- 5.6 ship_market RLS
-- ----------------------------------------------------------------------------
-- All authenticated users can browse the ship market
CREATE POLICY ship_market_select_all ON ship_market
    FOR SELECT USING (true);

CREATE POLICY ship_market_insert_own ON ship_market
    FOR INSERT WITH CHECK (auth.uid() = seller_id);

CREATE POLICY ship_market_update_own ON ship_market
    FOR UPDATE USING (auth.uid() = seller_id);

-- ----------------------------------------------------------------------------
-- 5.7 employees RLS
-- ----------------------------------------------------------------------------
CREATE POLICY employees_select_own ON employees
    FOR SELECT USING (auth.uid() = owner_id);

CREATE POLICY employees_insert_own ON employees
    FOR INSERT WITH CHECK (auth.uid() = owner_id);

CREATE POLICY employees_update_own ON employees
    FOR UPDATE USING (auth.uid() = owner_id);

CREATE POLICY employees_delete_own ON employees
    FOR DELETE USING (auth.uid() = owner_id);

-- ----------------------------------------------------------------------------
-- 5.8 loans RLS
-- ----------------------------------------------------------------------------
CREATE POLICY loans_select_own ON loans
    FOR SELECT USING (auth.uid() = borrower_id);

CREATE POLICY loans_insert_own ON loans
    FOR INSERT WITH CHECK (auth.uid() = borrower_id);

CREATE POLICY loans_update_own ON loans
    FOR UPDATE USING (auth.uid() = borrower_id);

-- ----------------------------------------------------------------------------
-- 5.9 transactions RLS
-- ----------------------------------------------------------------------------
CREATE POLICY transactions_select_own ON transactions
    FOR SELECT USING (auth.uid() = player_id);

CREATE POLICY transactions_insert_own ON transactions
    FOR INSERT WITH CHECK (auth.uid() = player_id);

-- ----------------------------------------------------------------------------
-- 5.10 fuel_purchases RLS
-- ----------------------------------------------------------------------------
CREATE POLICY fuel_purchases_select_own ON fuel_purchases
    FOR SELECT USING (auth.uid() = player_id);

CREATE POLICY fuel_purchases_insert_own ON fuel_purchases
    FOR INSERT WITH CHECK (auth.uid() = player_id);

-- ============================================================================
-- PART 6: FUNCTIONS
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 6.1 get_port_distance — Look up distance between two ports (bidirectional)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION get_port_distance(port_a INTEGER, port_b INTEGER)
RETURNS NUMERIC(10,2)
LANGUAGE plpgsql STABLE SECURITY DEFINER
AS $$
DECLARE
    dist NUMERIC(10,2);
BEGIN
    SELECT distance_nm INTO dist FROM port_distances WHERE port_a_id = port_a AND port_b_id = port_b;
    IF FOUND THEN RETURN dist; END IF;

    SELECT distance_nm INTO dist FROM port_distances WHERE port_a_id = port_b AND port_b_id = port_a;
    IF FOUND THEN RETURN dist; END IF;

    RETURN 0;
END;
$$;

COMMENT ON FUNCTION get_port_distance IS 'Returns the distance in nautical miles between two ports (bidirectional lookup)';

-- ----------------------------------------------------------------------------
-- 6.2 get_effective_speed — Ship speed adjusted for hull condition
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION get_effective_speed(p_ship_id UUID)
RETURNS NUMERIC(5,2)
LANGUAGE plpgsql STABLE SECURITY DEFINER
AS $$
DECLARE
    v_base_speed NUMERIC(5,2);
    v_condition  NUMERIC(5,2);
BEGIN
    SELECT st.speed_knots, s.condition_pct
    INTO v_base_speed, v_condition
    FROM ships s
    JOIN ship_types st ON s.ship_type_id = st.id
    WHERE s.id = p_ship_id;

    IF NOT FOUND THEN RETURN 0; END IF;

    -- Condition affects speed: at 50% condition, speed drops to 80%
    RETURN ROUND(v_base_speed * (0.8 + (v_condition / 100.0) * 0.2), 2);
END;
$$;

COMMENT ON FUNCTION get_effective_speed IS 'Returns effective speed in knots accounting for ship hull condition';

-- ----------------------------------------------------------------------------
-- 6.3 get_effective_fuel_rate — Fuel consumption adjusted for hull condition
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION get_effective_fuel_rate(p_ship_id UUID)
RETURNS NUMERIC(8,4)
LANGUAGE plpgsql STABLE SECURITY DEFINER
AS $$
DECLARE
    v_base_fuel  NUMERIC(8,4);
    v_condition  NUMERIC(5,2);
BEGIN
    SELECT st.fuel_per_nm, s.condition_pct
    INTO v_base_fuel, v_condition
    FROM ships s
    JOIN ship_types st ON s.ship_type_id = st.id
    WHERE s.id = p_ship_id;

    IF NOT FOUND THEN RETURN 0; END IF;

    -- Poor condition increases fuel consumption: at 50% condition, fuel use goes up 40%
    RETURN ROUND(v_base_fuel * (2.0 - (v_condition / 100.0) * 1.2), 4);
END;
$$;

COMMENT ON FUNCTION get_effective_fuel_rate IS 'Returns effective fuel consumption per NM accounting for ship condition';

-- ----------------------------------------------------------------------------
-- 6.4 calculate_voyage_time — Returns hours based on distance and ship speed
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION calculate_voyage_time(p_ship_id UUID, p_origin_port INTEGER, p_dest_port INTEGER)
RETURNS NUMERIC(10,2)
LANGUAGE plpgsql STABLE SECURITY DEFINER
AS $$
DECLARE
    v_distance_nm NUMERIC(10,2);
    v_speed       NUMERIC(5,2);
    v_hours       NUMERIC(10,2);
BEGIN
    v_distance_nm := get_port_distance(p_origin_port, p_dest_port);
    v_speed := get_effective_speed(p_ship_id);

    IF v_speed = 0 THEN RETURN 0; END IF;
    IF v_distance_nm = 0 THEN RETURN 0; END IF;

    -- Hours = distance / speed * 1.1 (10% buffer for weather/delays)
    v_hours := (v_distance_nm / v_speed) * 1.1;
    RETURN ROUND(v_hours, 2);
END;
$$;

COMMENT ON FUNCTION calculate_voyage_time IS 'Calculates estimated voyage time in hours between two ports for a given ship';

-- ----------------------------------------------------------------------------
-- 6.5 calculate_voyage_fuel — Returns total fuel consumption in barrels
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION calculate_voyage_fuel(p_ship_id UUID, p_origin_port INTEGER, p_dest_port INTEGER)
RETURNS NUMERIC(10,2)
LANGUAGE plpgsql STABLE SECURITY DEFINER
AS $$
DECLARE
    v_distance_nm NUMERIC(10,2);
    v_fuel_rate   NUMERIC(8,4);
    v_total_fuel  NUMERIC(10,2);
BEGIN
    v_distance_nm := get_port_distance(p_origin_port, p_dest_port);
    v_fuel_rate := get_effective_fuel_rate(p_ship_id);

    IF v_distance_nm = 0 THEN RETURN 0; END IF;

    -- Total fuel = distance * fuel rate * 1.1 (buffer)
    v_total_fuel := v_distance_nm * v_fuel_rate * 1.1;
    RETURN ROUND(v_total_fuel, 2);
END;
$$;

COMMENT ON FUNCTION calculate_voyage_fuel IS 'Calculates total fuel needed for a voyage in barrels';

-- ----------------------------------------------------------------------------
-- 6.6 buy_cargo — Validates and purchases cargo for a ship at a port
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION buy_cargo(
    p_player_id UUID,
    p_port_id INTEGER,
    p_good_id INTEGER,
    p_quantity NUMERIC(12,2),
    p_ship_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
    v_ship          RECORD;
    v_market        RECORD;
    v_ship_type     RECORD;
    v_good          RECORD;
    v_total_cost    NUMERIC(15,2);
    v_cargo_volume  NUMERIC(12,2);
    v_capacity      NUMERIC(12,2);
BEGIN
    -- 1. Validate ship ownership and status
    SELECT * INTO v_ship FROM ships WHERE id = p_ship_id AND owner_id = p_player_id;
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'Ship not found or not owned by player');
    END IF;

    IF v_ship.status NOT IN ('idle', 'loading') THEN
        RETURN jsonb_build_object('success', false, 'error', 'Ship is not available for loading (status: ' || v_ship.status || ')');
    END IF;

    IF v_ship.current_port_id IS NULL OR v_ship.current_port_id != p_port_id THEN
        RETURN jsonb_build_object('success', false, 'error', 'Ship is not at the specified port');
    END IF;

    -- 2. Get ship type info for capacity check
    SELECT * INTO v_ship_type FROM ship_types WHERE id = v_ship.ship_type_id;
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'Ship type not found');
    END IF;

    -- 3. Get good info
    SELECT * INTO v_good FROM goods WHERE id = p_good_id;
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'Good not found');
    END IF;

    -- 4. Validate market availability
    SELECT * INTO v_market FROM port_market WHERE port_id = p_port_id AND good_id = p_good_id;
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'Good not available at this port');
    END IF;

    IF v_market.available_quantity < p_quantity THEN
        RETURN jsonb_build_object('success', false, 'error', 'Insufficient supply. Available: ' || v_market.available_quantity);
    END IF;

    -- 5. Calculate cost
    v_total_cost := v_market.buy_price * p_quantity;

    -- 6. Check player money
    IF (SELECT money FROM profiles WHERE id = p_player_id) < v_total_cost THEN
        RETURN jsonb_build_object('success', false, 'error', 'Insufficient funds. Need: ' || v_total_cost);
    END IF;

    -- 7. Check capacity
    IF v_good.unit = 'TEU' THEN
        v_capacity := v_ship_type.teu_capacity::NUMERIC(12,2);
    ELSE
        v_capacity := v_ship_type.dwt_capacity;
    END IF;

    v_cargo_volume := p_quantity * v_good.volume_per_unit;
    IF v_cargo_volume > v_capacity THEN
        RETURN jsonb_build_object('success', false, 'error', 'Exceeds ship capacity');
    END IF;

    -- 8. Execute the purchase
    UPDATE profiles SET money = money - v_total_cost, updated_at = NOW() WHERE id = p_player_id;

    UPDATE port_market
    SET available_quantity = available_quantity - p_quantity,
        last_updated = NOW()
    WHERE port_id = p_port_id AND good_id = p_good_id;

    UPDATE ships SET status = 'loading' WHERE id = p_ship_id;

    INSERT INTO transactions (player_id, type, amount, description, reference_type, reference_id)
    VALUES (p_player_id, 'cargo_buy', -v_total_cost,
            'Purchased ' || p_quantity || ' ' || v_good.unit || ' of ' || v_good.name ||
            ' at ' || (SELECT name FROM ports WHERE id = p_port_id) ||
            ' for ship ' || p_ship_id,
            'ship', p_ship_id);

    RETURN jsonb_build_object(
        'success', true,
        'cost', v_total_cost,
        'quantity', p_quantity,
        'good_name', v_good.name,
        'ship_id', p_ship_id
    );
END;
$$;

COMMENT ON FUNCTION buy_cargo IS 'Purchases cargo at a port for a specific ship, validates everything and records transaction';

-- ----------------------------------------------------------------------------
-- 6.7 start_voyage — Validates and creates voyage, changes ship status
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION start_voyage(
    p_ship_id UUID,
    p_dest_port INTEGER,
    p_cargo_good_id INTEGER,
    p_cargo_quantity NUMERIC(12,2)
)
RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
    v_ship          RECORD;
    v_fuel_needed   NUMERIC(10,2);
    v_voyage_time   NUMERIC(10,2);
    v_origin_port   INTEGER;
    v_voyage_id     UUID;
    v_departure     TIMESTAMPTZ;
    v_arrival       TIMESTAMPTZ;
    v_ship_type     RECORD;
    v_max_fuel      NUMERIC(10,2);
BEGIN
    -- 1. Validate ship
    SELECT * INTO v_ship FROM ships WHERE id = p_ship_id;
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'Ship not found');
    END IF;

    IF v_ship.status NOT IN ('idle', 'loading') THEN
        RETURN jsonb_build_object('success', false, 'error', 'Ship cannot depart (status: ' || v_ship.status || ')');
    END IF;

    v_origin_port := v_ship.current_port_id;
    IF v_origin_port IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Ship has no current port');
    END IF;

    IF v_origin_port = p_dest_port THEN
        RETURN jsonb_build_object('success', false, 'error', 'Ship is already at destination');
    END IF;

    -- 2. Calculate fuel needed
    v_fuel_needed := calculate_voyage_fuel(p_ship_id, v_origin_port, p_dest_port);

    -- Get max fuel capacity (~15% of DWT)
    SELECT * INTO v_ship_type FROM ship_types WHERE id = v_ship.ship_type_id;
    v_max_fuel := v_ship_type.dwt_capacity * 0.15;

    IF v_ship.fuel_level < v_fuel_needed THEN
        RETURN jsonb_build_object('success', false,
            'error', 'Insufficient fuel. Need: ' || v_fuel_needed || ', Have: ' || v_ship.fuel_level);
    END IF;

    -- 3. Calculate voyage time
    v_voyage_time := calculate_voyage_time(p_ship_id, v_origin_port, p_dest_port);

    -- 4. Create voyage record
    v_departure := NOW();
    v_arrival := v_departure + (v_voyage_time || ' hours')::INTERVAL;

    INSERT INTO voyages (ship_id, origin_port_id, destination_port_id, cargo_good_id, cargo_quantity,
                          status, departure_time, estimated_arrival, fuel_consumed)
    VALUES (p_ship_id, v_origin_port, p_dest_port, p_cargo_good_id, p_cargo_quantity,
            'in_transit', v_departure, v_arrival, v_fuel_needed)
    RETURNING id INTO v_voyage_id;

    -- 5. Update ship
    UPDATE ships
    SET status = 'in_transit',
        fuel_level = fuel_level - v_fuel_needed,
        current_port_id = NULL
    WHERE id = p_ship_id;

    RETURN jsonb_build_object(
        'success', true,
        'voyage_id', v_voyage_id,
        'departure', v_departure,
        'estimated_arrival', v_arrival,
        'voyage_hours', v_voyage_time,
        'fuel_consumed', v_fuel_needed
    );
END;
$$;

COMMENT ON FUNCTION start_voyage IS 'Starts a ship voyage between two ports, validates fuel and ship status';

-- ----------------------------------------------------------------------------
-- 6.8 complete_voyage — Sells cargo, updates player money, resets ship
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION complete_voyage(p_voyage_id UUID)
RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
    v_voyage        RECORD;
    v_sell_price    NUMERIC(15,2);
    v_revenue       NUMERIC(15,2);
    v_tax           NUMERIC(15,2);
    v_net_revenue   NUMERIC(15,2);
    v_owner_id      UUID;
    v_good_name     TEXT;
    v_dest_name     TEXT;
    v_port_tax_rate NUMERIC(5,4);
BEGIN
    -- 1. Get voyage
    SELECT * INTO v_voyage FROM voyages WHERE id = p_voyage_id;
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'Voyage not found');
    END IF;

    IF v_voyage.status = 'completed' THEN
        RETURN jsonb_build_object('success', false, 'error', 'Voyage already completed');
    END IF;

    IF v_voyage.status != 'in_transit' THEN
        RETURN jsonb_build_object('success', false, 'error', 'Voyage is not in transit');
    END IF;

    -- 2. Get ship owner
    SELECT owner_id INTO v_owner_id FROM ships WHERE id = v_voyage.ship_id;
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'Ship not found');
    END IF;

    -- 3. Get sell price at destination
    SELECT sell_price INTO v_sell_price
    FROM port_market
    WHERE port_id = v_voyage.destination_port_id AND good_id = v_voyage.cargo_good_id;

    IF v_sell_price IS NULL THEN
        SELECT base_price INTO v_sell_price FROM goods WHERE id = v_voyage.cargo_good_id;
    END IF;

    IF v_sell_price IS NULL THEN
        v_sell_price := 0;
    END IF;

    -- 4. Calculate revenue
    v_revenue := v_sell_price * v_voyage.cargo_quantity;

    -- 5. Apply destination port tax
    SELECT tax_rate INTO v_port_tax_rate FROM ports WHERE id = v_voyage.destination_port_id;
    v_tax := v_revenue * COALESCE(v_port_tax_rate, 0);
    v_net_revenue := v_revenue - v_tax;

    -- 6. Update voyage
    UPDATE voyages
    SET status = 'completed',
        actual_arrival = NOW(),
        revenue = v_revenue,
        cost = v_tax
    WHERE id = p_voyage_id;

    -- 7. Credit player
    UPDATE profiles SET money = money + v_net_revenue, updated_at = NOW() WHERE id = v_owner_id;

    -- 8. Award XP (1 XP per 1000 net revenue, minimum 1)
    UPDATE profiles
    SET xp = xp + GREATEST(1, FLOOR(v_net_revenue / 1000)),
        updated_at = NOW()
    WHERE id = v_owner_id;

    -- 9. Reset ship
    UPDATE ships
    SET status = 'idle',
        current_port_id = v_voyage.destination_port_id
    WHERE id = v_voyage.ship_id;

    -- 10. Get display names
    SELECT name INTO v_good_name FROM goods WHERE id = v_voyage.cargo_good_id;
    SELECT name INTO v_dest_name FROM ports WHERE id = v_voyage.destination_port_id;

    -- 11. Record transaction
    INSERT INTO transactions (player_id, type, amount, description, reference_type, reference_id)
    VALUES (v_owner_id, 'cargo_sale', v_net_revenue,
            'Sold ' || v_voyage.cargo_quantity || ' ' || v_good_name ||
            ' at ' || COALESCE(v_dest_name, 'port #' || v_voyage.destination_port_id) ||
            ' (gross: ' || v_revenue || ', tax: ' || v_tax || ')',
            'voyage', p_voyage_id);

    RETURN jsonb_build_object(
        'success', true,
        'revenue', v_revenue,
        'tax', v_tax,
        'net_revenue', v_net_revenue,
        'xp_gained', GREATEST(1, FLOOR(v_net_revenue / 1000)),
        'destination', COALESCE(v_dest_name, 'Unknown')
    );
END;
$$;

COMMENT ON FUNCTION complete_voyage IS 'Completes a voyage, sells cargo at destination, credits player with revenue minus tax';

-- ----------------------------------------------------------------------------
-- 6.9 process_loan_payment — Monthly payment processing for a player
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION process_loan_payment(p_player_id UUID)
RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
    v_loan      RECORD;
    v_total_paid NUMERIC(15,2) := 0;
    v_count      INTEGER := 0;
BEGIN
    FOR v_loan IN
        SELECT * FROM loans
        WHERE borrower_id = p_player_id AND status = 'active'
        ORDER BY taken_at
    LOOP
        -- Check if player has enough money
        IF (SELECT money FROM profiles WHERE id = p_player_id) < v_loan.monthly_payment THEN
            UPDATE loans SET status = 'defaulted' WHERE id = v_loan.id;
            INSERT INTO transactions (player_id, type, amount, description, reference_type, reference_id)
            VALUES (p_player_id, 'loan_payment', 0,
                    'Loan #' || v_loan.id || ' DEFAULTED — insufficient funds',
                    'loan', v_loan.id);
            CONTINUE;
        END IF;

        -- Process payment
        UPDATE profiles SET money = money - v_loan.monthly_payment, updated_at = NOW() WHERE id = p_player_id;

        UPDATE loans
        SET months_paid = months_paid + 1,
            remaining_balance = remaining_balance - v_loan.monthly_payment
        WHERE id = v_loan.id;

        INSERT INTO transactions (player_id, type, amount, description, reference_type, reference_id)
        VALUES (p_player_id, 'loan_payment', -v_loan.monthly_payment,
                'Monthly loan payment for loan #' || v_loan.id ||
                ' (' || v_loan.months_paid + 1 || '/' || v_loan.total_months || ')',
                'loan', v_loan.id);

        -- Check if fully paid off
        IF (SELECT months_paid FROM loans WHERE id = v_loan.id) >= (SELECT total_months FROM loans WHERE id = v_loan.id) THEN
            UPDATE loans SET status = 'paid_off' WHERE id = v_loan.id;
        END IF;

        v_total_paid := v_total_paid + v_loan.monthly_payment;
        v_count := v_count + 1;
    END LOOP;

    RETURN jsonb_build_object('success', true, 'loans_processed', v_count, 'total_paid', v_total_paid);
END;
$$;

COMMENT ON FUNCTION process_loan_payment IS 'Processes monthly loan payments for a player, handles defaults';

-- ----------------------------------------------------------------------------
-- 6.10 update_market_prices — Randomize prices slightly each cycle
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION update_market_prices()
RETURNS INTEGER
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
    v_updated INTEGER := 0;
    v_record  RECORD;
    v_new_buy NUMERIC(15,2);
    v_new_sell NUMERIC(15,2);
    v_new_qty  NUMERIC(12,2);
    v_base_price NUMERIC(15,2);
BEGIN
    FOR v_record IN SELECT * FROM port_market LOOP
        -- Get the base price for this good
        SELECT base_price INTO v_base_price FROM goods WHERE id = v_record.good_id;

        -- Random fluctuation: -15% to +15%
        v_new_buy := ROUND(v_record.buy_price * (1 + (random() * 0.30 - 0.15)), 2);
        v_new_sell := ROUND(v_record.sell_price * (1 + (random() * 0.30 - 0.15)), 2);

        -- Clamp to reasonable bounds relative to base price
        v_new_buy := LEAST(v_base_price * 3, GREATEST(v_base_price * 0.3, v_new_buy));
        v_new_sell := LEAST(v_base_price * 4, GREATEST(v_base_price * 0.5, v_new_sell));

        -- Sell must exceed buy
        IF v_new_sell <= v_new_buy THEN
            v_new_sell := ROUND(v_new_buy * 1.2, 2);
        END IF;

        -- Fluctuate available quantity
        v_new_qty := GREATEST(0, v_record.available_quantity + (random() * 500 - 250)::NUMERIC);
        -- Replenish low quantities, cap high quantities
        IF v_record.available_quantity < 100 THEN
            v_new_qty := v_new_qty + 1000;
        END IF;
        v_new_qty := LEAST(v_new_qty, 50000 / GREATEST(1, v_base_price / 100) + v_record.available_quantity * 0.3);

        UPDATE port_market
        SET buy_price = v_new_buy,
            sell_price = v_new_sell,
            available_quantity = v_new_qty,
            last_updated = NOW()
        WHERE port_id = v_record.port_id AND good_id = v_record.good_id;

        v_updated := v_updated + 1;
    END LOOP;

    -- Record price history snapshot
    INSERT INTO price_history (port_id, good_id, price, recorded_at)
    SELECT port_id, good_id, sell_price, NOW() FROM port_market;

    RETURN v_updated;
END;
$$;

COMMENT ON FUNCTION update_market_prices IS 'Randomly fluctuates all market prices and records history. Call every 30 min.';

-- ----------------------------------------------------------------------------
-- 6.11 age_ships — Increase age, decrease condition daily
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION age_ships()
RETURNS INTEGER
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
    v_updated INTEGER := 0;
    v_ship    RECORD;
BEGIN
    FOR v_ship IN SELECT * FROM ships LOOP
        -- Age by ~1 day = 1/365 years
        -- Condition degrades: faster for older ships
        UPDATE ships
        SET age = age + (1.0 / 365.0)::NUMERIC,
            condition_pct = GREATEST(0, condition_pct - (0.02 + random() * 0.02))
        WHERE id = v_ship.id;

        -- Mark as in_dock if exceeded max age or condition is 0
        IF EXISTS (
            SELECT 1 FROM ships s
            JOIN ship_types st ON s.ship_type_id = st.id
            WHERE s.id = v_ship.id
            AND (s.age >= st.max_age_years OR s.condition_pct <= 0)
        ) THEN
            UPDATE ships SET status = 'in_dock' WHERE id = v_ship.id;
        END IF;

        v_updated := v_updated + 1;
    END LOOP;

    RETURN v_updated;
END;
$$;

COMMENT ON FUNCTION age_ships IS 'Ages all ships by 1 day, decreases condition. Call daily via cron.';

-- ----------------------------------------------------------------------------
-- 6.12 process_factory_cycles — Run factory production for all active factories
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION process_factory_cycles()
RETURNS INTEGER
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
    v_factory    RECORD;
    v_inputs     JSONB;
    v_input_rec  JSONB;
    v_inv_qty    NUMERIC(12,2);
    v_can_run    BOOLEAN;
    v_output_qty NUMERIC(12,2);
    v_cycles     INTEGER := 0;
BEGIN
    FOR v_factory IN
        SELECT * FROM factories WHERE is_running = TRUE
    LOOP
        -- Check if enough time has passed since last cycle
        IF v_factory.last_cycle_time IS NOT NULL THEN
            IF NOW() < (v_factory.last_cycle_time + (v_factory.cycle_hours || ' hours')::INTERVAL) THEN
                CONTINUE;
            END IF;
        END IF;

        v_can_run := TRUE;

        -- Validate input materials availability
        v_inputs := v_factory.input_goods;
        FOR v_input_rec IN SELECT * FROM jsonb_array_elements(v_inputs) LOOP
            SELECT quantity INTO v_inv_qty
            FROM factory_inventory
            WHERE factory_id = v_factory.id
              AND good_id = (v_input_rec->>'good_id')::INTEGER;

            IF v_inv_qty IS NULL OR v_inv_qty < (v_input_rec->>'quantity_per_cycle')::NUMERIC(12,2) THEN
                v_can_run := FALSE;
                EXIT;
            END IF;
        END LOOP;

        IF NOT v_can_run THEN
            CONTINUE;
        END IF;

        -- Consume inputs
        FOR v_input_rec IN SELECT * FROM jsonb_array_elements(v_inputs) LOOP
            UPDATE factory_inventory
            SET quantity = quantity - (v_input_rec->>'quantity_per_cycle')::NUMERIC(12,2)
            WHERE factory_id = v_factory.id
              AND good_id = (v_input_rec->>'good_id')::INTEGER;
        END LOOP;

        -- Produce output (scaled by efficiency)
        v_output_qty := v_factory.output_quantity_per_cycle * (v_factory.efficiency_pct / 100.0);

        INSERT INTO factory_inventory (factory_id, good_id, quantity)
        VALUES (v_factory.id, v_factory.output_good_id, v_output_qty)
        ON CONFLICT (factory_id, good_id)
        DO UPDATE SET quantity = factory_inventory.quantity + v_output_qty;

        -- Update last cycle time
        UPDATE factories SET last_cycle_time = NOW() WHERE id = v_factory.id;

        v_cycles := v_cycles + 1;
    END LOOP;

    RETURN v_cycles;
END;
$$;

COMMENT ON FUNCTION process_factory_cycles IS 'Runs all active factory production cycles if enough time and materials';

-- ----------------------------------------------------------------------------
-- 6.13 process_daily_salaries — Deduct employee salaries
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION process_daily_salaries()
RETURNS INTEGER
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
    v_player_id   UUID;
    v_total_salary NUMERIC(15,2);
    v_emp_count   INTEGER;
    v_processed   INTEGER := 0;
BEGIN
    FOR v_player_id IN SELECT DISTINCT owner_id FROM employees LOOP
        SELECT COALESCE(SUM(salary_daily), 0), COUNT(*)
        INTO v_total_salary, v_emp_count
        FROM employees WHERE owner_id = v_player_id;

        IF v_total_salary > 0 THEN
            UPDATE profiles SET money = money - v_total_salary, updated_at = NOW() WHERE id = v_player_id;

            INSERT INTO transactions (player_id, type, amount, description)
            VALUES (v_player_id, 'salary', -v_total_salary,
                    'Daily salary for ' || v_emp_count || ' employee(s)');

            v_processed := v_processed + 1;
        END IF;
    END LOOP;

    RETURN v_processed;
END;
$$;

COMMENT ON FUNCTION process_daily_salaries IS 'Deducts daily salaries from all player accounts. Call daily.';

-- ----------------------------------------------------------------------------
-- 6.14 process_daily_port_fees — Charge port maintenance for docked ships
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION process_daily_port_fees()
RETURNS INTEGER
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
    v_record RECORD;
    v_fee    NUMERIC(15,2);
    v_processed INTEGER := 0;
BEGIN
    FOR v_record IN
        SELECT s.owner_id, s.current_port_id, p.daily_maintenance_cost, COUNT(*) as ship_count
        FROM ships s
        JOIN ports p ON s.current_port_id = p.id
        WHERE s.status IN ('idle', 'loading', 'unloading', 'in_dock')
        GROUP BY s.owner_id, s.current_port_id, p.daily_maintenance_cost
    LOOP
        v_fee := v_record.daily_maintenance_cost * v_record.ship_count;

        UPDATE profiles SET money = money - v_fee, updated_at = NOW() WHERE id = v_record.owner_id;

        INSERT INTO transactions (player_id, type, amount, description)
        VALUES (v_record.owner_id, 'tax', -v_fee,
                'Daily port fees at port #' || v_record.current_port_id ||
                ' for ' || v_record.ship_count || ' ship(s)');

        v_processed := v_processed + 1;
    END LOOP;

    RETURN v_processed;
END;
$$;

COMMENT ON FUNCTION process_daily_port_fees IS 'Charges daily port maintenance fees for docked ships. Call daily.';

-- ----------------------------------------------------------------------------
-- 6.15 record_transaction — Convenience function for creating ledger entries
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION record_transaction(
    p_player_id UUID,
    p_type transaction_type_enum,
    p_amount NUMERIC(15,2),
    p_description TEXT,
    p_ref_type TEXT DEFAULT NULL,
    p_ref_id UUID DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
    v_id UUID;
BEGIN
    INSERT INTO transactions (player_id, type, amount, description, reference_type, reference_id)
    VALUES (p_player_id, p_type, p_amount, p_description, p_ref_type, p_ref_id)
    RETURNING id INTO v_id;
    RETURN v_id;
END;
$$;

COMMENT ON FUNCTION record_transaction IS 'Convenience function to create a transaction ledger entry';

-- ============================================================================
-- PART 7: TRIGGERS
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 7.1 Auto-create profile on user signup
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql SECURITY DEFINER
AS $$
BEGIN
    INSERT INTO profiles (id, company_name)
    VALUES (
        NEW.id,
        COALESCE(
            NEW.raw_user_meta_data->>'company_name',
            'Shipping Co. ' || LEFT(NEW.id::TEXT, 8)
        )
    );
    RETURN NEW;
END;
$$;

COMMENT ON FUNCTION handle_new_user IS 'Trigger function to auto-create a profile when a new user signs up via Supabase Auth';

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION handle_new_user();

-- ----------------------------------------------------------------------------
-- 7.2 Auto-update updated_at timestamp
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS profiles_updated_at ON profiles;
CREATE TRIGGER profiles_updated_at
    BEFORE UPDATE ON profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();

-- ----------------------------------------------------------------------------
-- 7.3 Prevent negative money (safety net)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION check_money_nonnegative()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.money < 0 THEN
        NEW.money := 0;
        INSERT INTO transactions (player_id, type, amount, description)
        VALUES (NEW.id, 'credit', ABS(OLD.money - NEW.money),
                'Safety net: prevented negative balance');
    END IF;
    RETURN NEW;
END;
$$;

COMMENT ON FUNCTION check_money_nonnegative IS 'Prevents money from going below 0 as a safety net';

DROP TRIGGER IF EXISTS profiles_money_check ON profiles;
CREATE TRIGGER profiles_money_check
    BEFORE UPDATE ON profiles
    FOR EACH ROW
    WHEN (OLD.money IS DISTINCT FROM NEW.money)
    EXECUTE FUNCTION check_money_nonnegative();

-- ============================================================================
-- PART 8: SEED DATA
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 8.1 Ship Types (7 types)
-- ----------------------------------------------------------------------------
INSERT INTO ship_types (name, type, dwt_capacity, teu_capacity, speed_knots, fuel_per_nm, base_price, max_age_years, crew_size, description) VALUES
('Handysize Tanker', 'tanker', 38000, 0, 14.00, 0.0450, 15000000.00, 25, 15,
 'Versatile small tanker ideal for coastal and short-sea routes. Can access most ports.'),
('VLCC', 'tanker', 320000, 0, 15.00, 0.1200, 95000000.00, 20, 25,
 'Very Large Crude Carrier — the workhorse of long-haul crude oil transport.'),
('Handysize Bulk Carrier', 'dry_bulk', 35000, 0, 13.00, 0.0420, 14000000.00, 25, 14,
 'Small bulk carrier for grain, coal, and minerals on regional routes.'),
('Capesize Bulk Carrier', 'dry_bulk', 180000, 0, 14.50, 0.1000, 62000000.00, 22, 22,
 'Too large for Panama/Suez — must round the Cape. Moves massive volumes of iron ore and coal.'),
('Panamax Container Ship', 'container', 75000, 5000, 18.00, 0.0800, 55000000.00, 22, 20,
 'Maximum size that fits the Panama Canal. Efficient container transport for major routes.'),
('Feeder Container Ship', 'container', 25000, 1500, 16.00, 0.0350, 18000000.00, 25, 12,
 'Smaller container vessel that feeds major hubs from regional ports.'),
('Ro-Ro Vessel', 'ro_ro', 50000, 0, 17.00, 0.0550, 40000000.00, 23, 18,
 'Roll-on/Roll-off vessel designed for wheeled cargo — automobiles, trucks, heavy equipment.');

-- ----------------------------------------------------------------------------
-- 8.2 Ports (20 ports across all continents)
-- ----------------------------------------------------------------------------
INSERT INTO ports (name, country, region, has_fuel_station, has_dry_dock, tax_rate, daily_maintenance_cost, latitude, longitude, description) VALUES
('Singapore', 'Singapore', 'Asia', TRUE, TRUE, 0.0300, 800.00, 1.352100, 103.819800,
 'World''s busiest transshipment hub. Strategic chokepoint between Indian and Pacific Oceans.'),
('Rotterdam', 'Netherlands', 'Europe', TRUE, TRUE, 0.0500, 900.00, 51.924400, 4.477700,
 'Europe''s largest port. Gateway to the European market via Rhine river.'),
('Shanghai', 'China', 'Asia', TRUE, TRUE, 0.0400, 750.00, 31.230400, 121.473700,
 'World''s busiest container port. Heart of Chinese manufacturing export.'),
('Houston', 'United States', 'North America', TRUE, TRUE, 0.0450, 700.00, 29.760400, -95.369800,
 'Gulf Coast energy hub. Major oil refinery and petrochemical center.'),
('Dubai (Jebel Ali)', 'UAE', 'Middle East', TRUE, TRUE, 0.0200, 600.00, 25.020000, 55.080000,
 'Middle East logistics hub. Low taxes, modern facilities, oil export gateway.'),
('Santos', 'Brazil', 'South America', TRUE, FALSE, 0.0600, 500.00, -23.960800, -46.333600,
 'Brazil''s largest port. Coffee, sugar, soy, and iron ore exports.'),
('Mumbai', 'India', 'Asia', TRUE, FALSE, 0.0550, 450.00, 18.975000, 72.825800,
 'India''s commercial capital and busiest port on the west coast.'),
('Tokyo', 'Japan', 'Asia', TRUE, TRUE, 0.0400, 850.00, 35.676200, 139.650300,
 'Japan''s largest port. High-tech imports and automobile exports.'),
('Los Angeles', 'United States', 'North America', TRUE, TRUE, 0.0500, 900.00, 33.740000, -118.270000,
 'Major US West Coast port. Gateway for trans-Pacific container trade.'),
('Hamburg', 'Germany', 'Europe', TRUE, TRUE, 0.0550, 880.00, 53.551100, 9.993700,
 'Germany''s largest port. Key European hub for container and bulk cargo.'),
('Lagos', 'Nigeria', 'Africa', TRUE, FALSE, 0.0700, 350.00, 6.454100, 3.394700,
 'West Africa''s busiest port. Oil exports and consumer goods imports.'),
('Durban', 'South Africa', 'Africa', TRUE, FALSE, 0.0500, 400.00, -29.858700, 31.021800,
 'Africa''s largest container port. Gateway to southern and eastern Africa.'),
('Sydney', 'Australia', 'Oceania', TRUE, TRUE, 0.0450, 780.00, -33.946100, 151.177200,
 'Australia''s largest port. Mineral exports and container imports.'),
('Fujairah', 'UAE', 'Middle East', TRUE, FALSE, 0.0150, 500.00, 25.128800, 56.326400,
 'World''s largest bunker fuel port. Critical refueling stop in the Strait of Hormuz.'),
('Busan', 'South Korea', 'Asia', TRUE, TRUE, 0.0350, 700.00, 35.102800, 129.040300,
 'South Korea''s largest port. Shipbuilding center and transshipment hub.'),
('Antwerp', 'Belgium', 'Europe', TRUE, TRUE, 0.0500, 850.00, 51.219400, 4.402500,
 'Europe''s second-largest port. Major chemical and container hub.'),
('Richards Bay', 'South Africa', 'Africa', TRUE, FALSE, 0.0450, 380.00, -28.803900, 32.088900,
 'World''s largest coal export terminal. Major bulk port.'),
('Chennai', 'India', 'Asia', TRUE, FALSE, 0.0500, 420.00, 13.082700, 80.270700,
 'India''s east coast hub. Automobile, leather, and textile exports.'),
('Piraeus', 'Greece', 'Europe', TRUE, TRUE, 0.0400, 650.00, 37.942200, 23.646400,
 'Mediterranean gateway. Chinese-operated hub connecting Asia to Europe.'),
('Colombo', 'Sri Lanka', 'Asia', TRUE, FALSE, 0.0300, 380.00, 6.927100, 79.861200,
 'Indian Ocean transshipment hub. Strategic location on east-west shipping lanes.');

-- ----------------------------------------------------------------------------
-- 8.3 Goods (10 cargo types)
-- ----------------------------------------------------------------------------
INSERT INTO goods (name, category, unit, base_price, volume_per_unit, description) VALUES
('Crude Oil', 'liquid', 'tonnes', 450.00, 1.2000,
 'Unrefined petroleum. The lifeblood of global trade. Transported by tankers.'),
('Refined Fuel', 'liquid', 'tonnes', 680.00, 1.1000,
 'Processed petroleum products — diesel, gasoline, jet fuel.'),
('Coal', 'bulk', 'tonnes', 85.00, 0.9000,
 'Thermal and metallurgical coal. Major bulk commodity for power and steel.'),
('Iron Ore', 'bulk', 'tonnes', 120.00, 0.5000,
 'Raw iron ore. Dense cargo — primary input for steel production.'),
('Grain', 'bulk', 'tonnes', 280.00, 1.3000,
 'Wheat, corn, rice, soybeans. Essential food commodity transported in bulk.'),
('Steel', 'bulk', 'tonnes', 520.00, 0.4000,
 'Finished steel products — beams, coils, plates. Factory output.'),
('General Containers', 'container', 'TEU', 2500.00, 1.0000,
 'Mixed consumer goods in standard containers. The backbone of global trade.'),
('Automobiles', 'rollable', 'units', 22000.00, 0.0500,
 'Cars, trucks, and SUVs. High-value cargo transported by Ro-Ro vessels.'),
('Limestone', 'bulk', 'tonnes', 35.00, 0.7000,
 'Raw limestone for cement production and construction.'),
('Copper', 'bulk', 'tonnes', 8500.00, 0.3500,
 'Copper ore and refined copper. Valuable industrial metal for electronics.');

-- ----------------------------------------------------------------------------
-- 8.4 Port Market — Dynamic prices per port per good (20 ports × 10 goods = 200 rows)
-- ----------------------------------------------------------------------------
-- Port IDs: 1=Singapore  2=Rotterdam  3=Shanghai  4=Houston  5=Dubai
--            6=Santos     7=Mumbai     8=Tokyo    9=LosAngeles  10=Hamburg
--            11=Lagos     12=Durban    13=Sydney   14=Fujairah    15=Busan
--            16=Antwerp   17=RichardsBay  18=Chennai  19=Piraeus  20=Colombo
-- Good IDs: 1=CrudeOil  2=RefinedFuel  3=Coal  4=IronOre  5=Grain
--           6=Steel     7=Containers  8=Autos  9=Limestone  10=Copper

-- Crude Oil — cheap at producers (Houston, Dubai, Lagos, Fujairah), expensive at consumers
INSERT INTO port_market (port_id, good_id, buy_price, sell_price, available_quantity) VALUES
(1, 1, 430, 480, 15000),
(2, 1, 460, 510, 12000),
(3, 1, 445, 500, 13000),
(4, 1, 380, 420, 25000),
(5, 1, 370, 410, 30000),
(6, 1, 450, 490, 8000),
(7, 1, 420, 470, 10000),
(8, 1, 440, 490, 9000),
(9, 1, 420, 460, 14000),
(10, 1, 455, 505, 11000),
(11, 1, 390, 430, 20000),
(12, 1, 445, 495, 7000),
(13, 1, 460, 520, 6000),
(14, 1, 360, 400, 35000),
(15, 1, 440, 490, 10000),
(16, 1, 455, 510, 10500),
(17, 1, 435, 480, 9000),
(18, 1, 425, 475, 8500),
(19, 1, 445, 500, 9500),
(20, 1, 410, 460, 11000);

-- Refined Fuel
INSERT INTO port_market (port_id, good_id, buy_price, sell_price, available_quantity) VALUES
(1, 2, 650, 720, 10000),
(2, 2, 670, 750, 8000),
(3, 2, 660, 740, 9000),
(4, 2, 630, 700, 12000),
(5, 2, 620, 690, 15000),
(6, 2, 680, 750, 5000),
(7, 2, 640, 710, 7000),
(8, 2, 665, 745, 7500),
(9, 2, 650, 720, 9000),
(10, 2, 675, 755, 7500),
(11, 2, 660, 730, 4500),
(12, 2, 665, 740, 4000),
(13, 2, 690, 770, 5000),
(14, 2, 610, 680, 18000),
(15, 2, 660, 735, 7000),
(16, 2, 670, 750, 7500),
(17, 2, 650, 725, 5000),
(18, 2, 645, 720, 6000),
(19, 2, 660, 740, 6500),
(20, 2, 640, 715, 7000);

-- Coal
INSERT INTO port_market (port_id, good_id, buy_price, sell_price, available_quantity) VALUES
(1, 3, 90, 105, 12000),
(2, 3, 95, 115, 10000),
(3, 3, 92, 110, 11000),
(4, 3, 80, 95, 8000),
(5, 3, 85, 100, 6000),
(6, 3, 78, 92, 15000),
(7, 3, 88, 105, 9000),
(8, 3, 100, 130, 15000),
(9, 3, 90, 110, 7000),
(10, 3, 92, 112, 8500),
(11, 3, 82, 98, 7000),
(12, 3, 85, 100, 9000),
(13, 3, 95, 120, 13000),
(14, 3, 82, 98, 5000),
(15, 3, 98, 125, 14000),
(16, 3, 93, 113, 8000),
(17, 3, 70, 85, 25000),
(18, 3, 85, 102, 10000),
(19, 3, 90, 108, 7000),
(20, 3, 88, 105, 8000);

-- Iron Ore
INSERT INTO port_market (port_id, good_id, buy_price, sell_price, available_quantity) VALUES
(1, 4, 115, 130, 8000),
(2, 4, 120, 140, 6000),
(3, 4, 125, 155, 20000),
(4, 4, 110, 125, 5000),
(5, 4, 115, 135, 4000),
(6, 4, 100, 118, 22000),
(7, 4, 118, 138, 5000),
(8, 4, 125, 155, 18000),
(9, 4, 118, 140, 7000),
(10, 4, 120, 142, 5500),
(11, 4, 105, 120, 8000),
(12, 4, 108, 128, 10000),
(13, 4, 98, 115, 25000),
(14, 4, 112, 130, 3000),
(15, 4, 122, 150, 16000),
(16, 4, 118, 140, 5000),
(17, 4, 110, 130, 12000),
(18, 4, 116, 135, 6000),
(19, 4, 118, 138, 4000),
(20, 4, 112, 130, 7000);

-- Grain
INSERT INTO port_market (port_id, good_id, buy_price, sell_price, available_quantity) VALUES
(1, 5, 275, 310, 6000),
(2, 5, 285, 320, 5000),
(3, 5, 290, 330, 18000),
(4, 5, 255, 290, 16000),
(5, 5, 270, 305, 4000),
(6, 5, 245, 278, 20000),
(7, 5, 265, 300, 8000),
(8, 5, 295, 340, 15000),
(9, 5, 270, 305, 7000),
(10, 5, 280, 318, 4500),
(11, 5, 260, 295, 7000),
(12, 5, 258, 290, 9000),
(13, 5, 285, 320, 5000),
(14, 5, 268, 300, 3000),
(15, 5, 290, 330, 12000),
(16, 5, 282, 318, 4500),
(17, 5, 252, 285, 11000),
(18, 5, 262, 298, 7000),
(19, 5, 278, 315, 5000),
(20, 5, 270, 305, 6000);

-- Steel
INSERT INTO port_market (port_id, good_id, buy_price, sell_price, available_quantity) VALUES
(1, 6, 500, 560, 8000),
(2, 6, 520, 580, 7000),
(3, 6, 535, 600, 18000),
(4, 6, 510, 570, 6000),
(5, 6, 495, 555, 5000),
(6, 6, 480, 540, 7000),
(7, 6, 505, 565, 6000),
(8, 6, 540, 605, 12000),
(9, 6, 515, 575, 8000),
(10, 6, 525, 590, 7000),
(11, 6, 490, 550, 4000),
(12, 6, 495, 555, 5000),
(13, 6, 510, 575, 6000),
(14, 6, 488, 548, 3000),
(15, 6, 535, 598, 11000),
(16, 6, 522, 585, 6500),
(17, 6, 485, 545, 6000),
(18, 6, 500, 560, 5500),
(19, 6, 515, 580, 5000),
(20, 6, 498, 558, 5000);

-- General Containers
INSERT INTO port_market (port_id, good_id, buy_price, sell_price, available_quantity) VALUES
(1, 7, 2400, 2700, 4000),
(2, 7, 2500, 2850, 3500),
(3, 7, 2200, 2550, 8000),
(4, 7, 2450, 2750, 3000),
(5, 7, 2350, 2650, 2500),
(6, 7, 2300, 2600, 3500),
(7, 7, 2250, 2550, 3000),
(8, 7, 2600, 2950, 6000),
(9, 7, 2500, 2800, 4000),
(10, 7, 2550, 2900, 3500),
(11, 7, 2200, 2500, 2500),
(12, 7, 2280, 2580, 2000),
(13, 7, 2600, 2950, 3000),
(14, 7, 2300, 2600, 2000),
(15, 7, 2550, 2900, 5000),
(16, 7, 2520, 2880, 3000),
(17, 7, 2250, 2550, 2500),
(18, 7, 2280, 2580, 2500),
(19, 7, 2480, 2800, 2500),
(20, 7, 2320, 2620, 3000);

-- Automobiles
INSERT INTO port_market (port_id, good_id, buy_price, sell_price, available_quantity) VALUES
(1, 8, 21500, 24500, 2000),
(2, 8, 22500, 26000, 1500),
(3, 8, 21800, 25000, 5000),
(4, 8, 22000, 25200, 1000),
(5, 8, 21000, 24000, 800),
(6, 8, 22200, 25500, 1200),
(7, 8, 21500, 24500, 800),
(8, 8, 20500, 23500, 6000),
(9, 8, 22000, 25000, 2000),
(10, 8, 22800, 26200, 1500),
(11, 8, 21000, 24000, 500),
(12, 8, 21500, 24500, 600),
(13, 8, 22500, 25800, 1000),
(14, 8, 20800, 23800, 500),
(15, 8, 20800, 23800, 5500),
(16, 8, 22600, 26000, 1500),
(17, 8, 21200, 24200, 500),
(18, 8, 21000, 24000, 800),
(19, 8, 22000, 25200, 1000),
(20, 8, 21000, 24000, 700);

-- Limestone
INSERT INTO port_market (port_id, good_id, buy_price, sell_price, available_quantity) VALUES
(1, 9, 33, 38, 15000),
(2, 9, 35, 42, 12000),
(3, 9, 38, 45, 18000),
(4, 9, 30, 36, 10000),
(5, 9, 32, 38, 8000),
(6, 9, 28, 34, 18000),
(7, 9, 34, 40, 10000),
(8, 9, 38, 46, 12000),
(9, 9, 33, 40, 8000),
(10, 9, 36, 43, 10000),
(11, 9, 30, 36, 10000),
(12, 9, 31, 37, 12000),
(13, 9, 34, 40, 14000),
(14, 9, 30, 36, 8000),
(15, 9, 37, 44, 10000),
(16, 9, 35, 42, 9000),
(17, 9, 28, 34, 15000),
(18, 9, 32, 38, 10000),
(19, 9, 34, 41, 8000),
(20, 9, 32, 38, 10000);

-- Copper
INSERT INTO port_market (port_id, good_id, buy_price, sell_price, available_quantity) VALUES
(1, 10, 8200, 9200, 2000),
(2, 10, 8400, 9500, 1500),
(3, 10, 8600, 9800, 4000),
(4, 10, 8100, 9100, 1000),
(5, 10, 8000, 9000, 800),
(6, 10, 7800, 8800, 1500),
(7, 10, 8100, 9100, 1000),
(8, 10, 8700, 9900, 3000),
(9, 10, 8300, 9400, 1500),
(10, 10, 8500, 9600, 1200),
(11, 10, 7900, 8900, 800),
(12, 10, 8000, 9000, 1000),
(13, 10, 8100, 9200, 2000),
(14, 10, 7900, 8900, 600),
(15, 10, 8600, 9700, 3000),
(16, 10, 8450, 9550, 1200),
(17, 10, 7800, 8800, 1200),
(18, 10, 8200, 9300, 1000),
(19, 10, 8400, 9500, 800),
(20, 10, 8100, 9100, 1000);

-- ----------------------------------------------------------------------------
-- 8.5 Port Distances (real-world approximate great-circle, 120+ pairs)
-- Stored with smaller port_id as port_a_id to avoid duplicates
-- All distances in nautical miles
-- ----------------------------------------------------------------------------

-- Singapore(1) ↔ others
INSERT INTO port_distances (port_a_id, port_b_id, distance_nm) VALUES
(1, 2, 8340),   (1, 3, 2280),   (1, 4, 9330),   (1, 5, 3650),
(1, 6, 8570),   (1, 7, 2480),   (1, 8, 3280),   (1, 9, 6170),
(1, 10, 8290),  (1, 11, 4960),  (1, 12, 4640),  (1, 13, 4150),
(1, 14, 3530),  (1, 15, 2820),  (1, 16, 8380),  (1, 17, 4750),
(1, 18, 1890),  (1, 19, 5670),  (1, 20, 1580);

-- Rotterdam(2) ↔ others (skip 1 already done)
INSERT INTO port_distances (port_a_id, port_b_id, distance_nm) VALUES
(2, 3, 10630),  (2, 4, 4860),   (2, 5, 5780),   (2, 6, 5180),
(2, 7, 5050),   (2, 8, 9330),   (2, 9, 5570),   (2, 10, 250),
(2, 11, 3550),  (2, 12, 6280),  (2, 13, 11500), (2, 14, 5560),
(2, 15, 9050),  (2, 16, 120),   (2, 17, 6240),  (2, 18, 4900),
(2, 19, 1420),  (2, 20, 6340);

-- Shanghai(3) ↔ others
INSERT INTO port_distances (port_a_id, port_b_id, distance_nm) VALUES
(3, 4, 7030),   (3, 5, 5360),   (3, 6, 11500),  (3, 7, 3460),
(3, 8, 1090),   (3, 9, 5680),   (3, 10, 10350), (3, 11, 7870),
(3, 13, 4560),  (3, 14, 5310),  (3, 15, 530),   (3, 16, 10440),
(3, 17, 5880),  (3, 18, 2640),  (3, 19, 8150),  (3, 20, 2530);

-- Houston(4) ↔ others
INSERT INTO port_distances (port_a_id, port_b_id, distance_nm) VALUES
(4, 5, 8120),   (4, 6, 4760),   (4, 7, 8590),   (4, 8, 6590),
(4, 9, 1370),   (4, 10, 5100),  (4, 11, 5040),  (4, 12, 7170),
(4, 13, 7600),  (4, 14, 8050),  (4, 15, 6490),  (4, 16, 5120),
(4, 17, 7270),  (4, 18, 8820),  (4, 19, 6270),  (4, 20, 9220);

-- Dubai(5) ↔ others
INSERT INTO port_distances (port_a_id, port_b_id, distance_nm) VALUES
(5, 6, 7260),   (5, 7, 1190),   (5, 8, 5640),   (5, 9, 8340),
(5, 10, 5680),  (5, 11, 3410),  (5, 12, 3620),  (5, 13, 6730),
(5, 15, 5270),  (5, 16, 5740),  (5, 17, 3370),  (5, 18, 1760),
(5, 19, 4400),  (5, 20, 2100);

-- Santos(6) ↔ others
INSERT INTO port_distances (port_a_id, port_b_id, distance_nm) VALUES
(6, 7, 5640),   (6, 8, 11500),  (6, 9, 5850),   (6, 10, 5310),
(6, 11, 3100),  (6, 12, 4040),  (6, 13, 7390),  (6, 14, 7180),
(6, 15, 11800), (6, 16, 5360),  (6, 17, 3830),  (6, 18, 7280),
(6, 19, 5570),  (6, 20, 8160);

-- Mumbai(7) ↔ others
INSERT INTO port_distances (port_a_id, port_b_id, distance_nm) VALUES
(7, 8, 4200),   (7, 9, 8220),   (7, 10, 5190),  (7, 11, 4280),
(7, 12, 3180),  (7, 13, 5570),  (7, 14, 1290),  (7, 15, 3960),
(7, 16, 5210),  (7, 17, 3090),  (7, 18, 1060),  (7, 19, 3670),
(7, 20, 1030);

-- Tokyo(8) ↔ others
INSERT INTO port_distances (port_a_id, port_b_id, distance_nm) VALUES
(8, 9, 4530),   (8, 10, 9180),  (8, 11, 8530),  (8, 12, 7380),
(8, 13, 4260),  (8, 14, 5660),  (8, 15, 1080),  (8, 16, 9250),
(8, 17, 7880),  (8, 18, 3980),  (8, 19, 7900),  (8, 20, 3970);

-- Los Angeles(9) ↔ others
INSERT INTO port_distances (port_a_id, port_b_id, distance_nm) VALUES
(9, 10, 5700),  (9, 11, 5800),  (9, 12, 8200),  (9, 13, 6530),
(9, 14, 8220),  (9, 15, 5180),  (9, 16, 5630),  (9, 17, 8420),
(9, 18, 8600),  (9, 19, 6450),  (9, 20, 8580);

-- Hamburg(10) ↔ others
INSERT INTO port_distances (port_a_id, port_b_id, distance_nm) VALUES
(10, 11, 3400), (10, 12, 6190), (10, 13, 11280),(10, 14, 5620),
(10, 15, 8950), (10, 16, 270),  (10, 17, 6140), (10, 18, 4740),
(10, 19, 1190), (10, 20, 6190);

-- Lagos(11) ↔ others
INSERT INTO port_distances (port_a_id, port_b_id, distance_nm) VALUES
(11, 12, 2610), (11, 13, 8340), (11, 14, 3530), (11, 15, 7960),
(11, 16, 3630), (11, 17, 2400), (11, 18, 5120), (11, 19, 3390),
(11, 20, 5130);

-- Durban(12) ↔ others
INSERT INTO port_distances (port_a_id, port_b_id, distance_nm) VALUES
(12, 13, 5890), (12, 14, 3680), (12, 15, 7360), (12, 16, 6190),
(12, 17, 410),  (12, 18, 3580), (12, 19, 5420), (12, 20, 3560);

-- Sydney(13) ↔ others
INSERT INTO port_distances (port_a_id, port_b_id, distance_nm) VALUES
(13, 14, 6810), (13, 15, 4840), (13, 16, 11400),(13, 17, 6240),
(13, 18, 4920), (13, 19, 10700),(13, 20, 4290);

-- Fujairah(14) ↔ others
INSERT INTO port_distances (port_a_id, port_b_id, distance_nm) VALUES
(14, 15, 5320), (14, 16, 5670), (14, 17, 3410), (14, 18, 1810),
(14, 19, 4380), (14, 20, 2050);

-- Busan(15) ↔ others
INSERT INTO port_distances (port_a_id, port_b_id, distance_nm) VALUES
(15, 16, 9080), (15, 17, 7540), (15, 18, 3070), (15, 19, 7830),
(15, 20, 2900);

-- Antwerp(16) ↔ others
INSERT INTO port_distances (port_a_id, port_b_id, distance_nm) VALUES
(16, 17, 6180), (16, 18, 4850), (16, 19, 1330), (16, 20, 6280);

-- Richards Bay(17) ↔ others
INSERT INTO port_distances (port_a_id, port_b_id, distance_nm) VALUES
(17, 18, 3700), (17, 19, 5520), (17, 20, 3590);

-- Chennai(18) ↔ others
INSERT INTO port_distances (port_a_id, port_b_id, distance_nm) VALUES
(18, 19, 3510), (18, 20, 1150);

-- Piraeus(19) ↔ Colombo(20)
INSERT INTO port_distances (port_a_id, port_b_id, distance_nm) VALUES
(19, 20, 3870);

-- ============================================================================
-- PART 9: REALTIME SUBSCRIPTIONS (Supabase)
-- ============================================================================
-- Enable realtime for key tables so players get live updates in the game UI
-- ============================================================================

ALTER PUBLICATION supabase_realtime ADD TABLE profiles;
ALTER PUBLICATION supabase_realtime ADD TABLE ships;
ALTER PUBLICATION supabase_realtime ADD TABLE voyages;
ALTER PUBLICATION supabase_realtime ADD TABLE port_market;
ALTER PUBLICATION supabase_realtime ADD TABLE ship_market;

-- ============================================================================
-- PART 10: GRANTS & PERMISSIONS
-- ============================================================================

-- Allow authenticated users and service role to call all functions
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO authenticated, anon, service_role;

-- Grant SELECT on reference tables to all roles
GRANT SELECT ON ship_types TO authenticated, anon;
GRANT SELECT ON ports TO authenticated, anon;
GRANT SELECT ON goods TO authenticated, anon;
GRANT SELECT ON port_market TO authenticated, anon;
GRANT SELECT ON port_distances TO authenticated, anon;
GRANT SELECT ON price_history TO authenticated, anon;

-- Grant sequence usage for UUID generation
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- ============================================================================
-- DONE
-- ============================================================================

COMMIT;
