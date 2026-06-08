-- =============================================
-- ELT: Achievements + Multiplayer Rankings
-- =============================================

-- Achievements table
CREATE TABLE IF NOT EXISTS public.achievements (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  achievement_id TEXT NOT NULL,
  unlocked_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(company_id, achievement_id)
);

-- Enable RLS
ALTER TABLE public.achievements ENABLE ROW LEVEL SECURITY;

-- Company can read own achievements
CREATE POLICY "Companies read own achievements"
  ON public.achievements FOR SELECT
  USING (company_id = (SELECT id FROM public.companies WHERE owner_id = auth.uid() LIMIT 1));

-- Service role can insert (for RPC)
CREATE POLICY "Service role insert"
  ON public.achievements FOR INSERT
  WITH CHECK (true);

-- Index for fast lookup
CREATE INDEX IF NOT EXISTS idx_achievements_company ON public.achievements(company_id);

-- Leaderboard view: all companies ranked by level, XP, money
CREATE OR REPLACE VIEW public.leaderboard AS
SELECT
  c.id,
  c.name,
  c.level,
  c.xp,
  c.money,
  c.reputation,
  (SELECT count(*) FROM public.trucks WHERE company_id = c.id) AS truck_count,
  (SELECT count(*) FROM public.achievements WHERE company_id = c.id) AS achievement_count,
  (SELECT count(*) FROM public.contracts WHERE assigned_company_id = c.id AND status = 'completed') AS completed_contracts
FROM public.companies c
ORDER BY c.level DESC, c.xp DESC, c.money DESC;

-- RPC: check and unlock achievements for a company
CREATE OR REPLACE FUNCTION public.check_achievements(p_company_id UUID)
RETURNS TABLE(achievement_id TEXT, is_new BOOLEAN) AS $$
DECLARE
  v_money INT;
  v_level INT;
  v_reputation INT;
  v_truck_count INT;
  v_driver_count INT;
  v_warehouse_count INT;
  v_completed_contracts INT;
  v_earned_total INT;
  v_cities_delivered INT;
  v_total_cities INT;
  v_existing TEXT[];
  v_aid TEXT;
  v_xp_reward INT;
BEGIN
  -- Get company stats
  SELECT money, level, reputation INTO v_money, v_level, v_reputation
  FROM public.companies WHERE id = p_company_id;

  SELECT count(*) INTO v_truck_count FROM public.trucks WHERE company_id = p_company_id;
  SELECT count(*) INTO v_driver_count FROM public.drivers WHERE company_id = p_company_id;
  SELECT count(*) INTO v_warehouse_count FROM public.warehouses WHERE company_id = p_company_id;
  SELECT count(*) INTO v_completed_contracts FROM public.contracts
    WHERE assigned_company_id = p_company_id AND status = 'completed';

  -- Total earned from completed contracts
  SELECT COALESCE(SUM(reward), 0) INTO v_earned_total FROM public.contracts
    WHERE assigned_company_id = p_company_id AND status = 'completed';

  -- Cities delivered to
  SELECT count(DISTINCT destination_city_id) INTO v_cities_delivered FROM public.contracts
    WHERE assigned_company_id = p_company_id AND status = 'completed';

  -- Total cities
  SELECT count(*) INTO v_total_cities FROM public.cities;

  -- Get existing achievements
  SELECT array_agg(achievement_id) INTO v_existing FROM public.achievements WHERE company_id = p_company_id;

  -- Check each achievement
  FOR v_aid IN SELECT unnest(ARRAY[
    'first_truck', 'fleet_3', 'fleet_5', 'fleet_10', 'fleet_20',
    'first_delivery', 'deliveries_10', 'deliveries_50', 'deliveries_100',
    'cities_5', 'cities_all',
    'earned_100k', 'earned_1m', 'earned_10m', 'money_5m',
    'first_warehouse', 'warehouses_3',
    'first_driver', 'drivers_5',
    'level_5', 'level_10', 'reputation_max'
  ]) LOOP
    IF NOT (v_existing IS NOT NULL AND v_aid = ANY(v_existing)) THEN
      v_xp_reward := 50; -- default
      CONTINUE WHEN NOT (
        (v_aid = 'first_truck' AND v_truck_count >= 1) OR
        (v_aid = 'fleet_3' AND v_truck_count >= 3) OR
        (v_aid = 'fleet_5' AND v_truck_count >= 5) OR
        (v_aid = 'fleet_10' AND v_truck_count >= 10) OR
        (v_aid = 'fleet_20' AND v_truck_count >= 20) OR
        (v_aid = 'first_delivery' AND v_completed_contracts >= 1) OR
        (v_aid = 'deliveries_10' AND v_completed_contracts >= 10) OR
        (v_aid = 'deliveries_50' AND v_completed_contracts >= 50) OR
        (v_aid = 'deliveries_100' AND v_completed_contracts >= 100) OR
        (v_aid = 'cities_5' AND v_cities_delivered >= 5) OR
        (v_aid = 'cities_all' AND v_cities_delivered >= v_total_cities) OR
        (v_aid = 'earned_100k' AND v_earned_total >= 100000) OR
        (v_aid = 'earned_1m' AND v_earned_total >= 1000000) OR
        (v_aid = 'earned_10m' AND v_earned_total >= 10000000) OR
        (v_aid = 'money_5m' AND v_money >= 5000000) OR
        (v_aid = 'first_warehouse' AND v_warehouse_count >= 1) OR
        (v_aid = 'warehouses_3' AND v_warehouse_count >= 3) OR
        (v_aid = 'first_driver' AND v_driver_count >= 1) OR
        (v_aid = 'drivers_5' AND v_driver_count >= 5) OR
        (v_aid = 'level_5' AND v_level >= 5) OR
        (v_aid = 'level_10' AND v_level >= 10) OR
        (v_aid = 'reputation_max' AND v_reputation >= 100)
      );
      -- Achievement condition met, insert
      INSERT INTO public.achievements (company_id, achievement_id)
      VALUES (p_company_id, v_aid);

      -- Return the newly unlocked achievement
      achievement_id := v_aid;
      is_new := true;
      RETURN NEXT;

      -- Award XP
      v_xp_reward := CASE v_aid
        WHEN 'fleet_3' THEN 50 WHEN 'fleet_5' THEN 100 WHEN 'fleet_10' THEN 200 WHEN 'fleet_20' THEN 500
        WHEN 'deliveries_10' THEN 75 WHEN 'deliveries_50' THEN 200 WHEN 'deliveries_100' THEN 500
        WHEN 'cities_5' THEN 75 WHEN 'cities_all' THEN 500
        WHEN 'earned_100k' THEN 25 WHEN 'earned_1m' THEN 100 WHEN 'earned_10m' THEN 300
        WHEN 'money_5m' THEN 200
        WHEN 'warehouses_3' THEN 100
        WHEN 'drivers_5' THEN 100
        WHEN 'level_5' THEN 100 WHEN 'level_10' THEN 300 WHEN 'reputation_max' THEN 200
        ELSE 25
      END;

      -- Add XP
      UPDATE public.companies
      SET xp = xp + v_xp_reward,
          level = GREATEST(level, (xp + v_xp_reward) / 1000 + 1)
      WHERE id = p_company_id;
    END IF;
  END LOOP;

  RETURN;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
