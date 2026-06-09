-- =============================================
-- Migration: Seasonal Events
-- Run via Supabase Dashboard SQL Editor
-- =============================================

-- Seasonal events table
CREATE TABLE IF NOT EXISTS seasonal_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_key TEXT UNIQUE NOT NULL, -- 'christmas_2025', 'euro_tour_2025', etc.
  title TEXT NOT NULL,
  description TEXT DEFAULT '',
  event_type TEXT NOT NULL, -- 'cargo_bonus', 'delivery_challenge', 'xp_boost'
  multiplier NUMERIC(3,2) DEFAULT 1.0, -- bonus multiplier
  cargo_type TEXT, -- specific cargo type for bonus, null = all
  target_deliveries INTEGER DEFAULT 0, -- for challenges
  reward_xp INTEGER DEFAULT 0,
  reward_money INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  starts_at TIMESTAMPTZ DEFAULT NOW(),
  ends_at TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '48 hours')
);

-- RLS
ALTER TABLE seasonal_events ENABLE ROW LEVEL SECURITY;
CREATE POLICY "seasonal_events_read" ON seasonal_events FOR SELECT USING (true);
CREATE POLICY "seasonal_events_insert" ON seasonal_events FOR INSERT WITH CHECK (true);
CREATE POLICY "seasonal_events_update" ON seasonal_events FOR UPDATE USING (true);

-- Insert some example events (inactive by default)
INSERT INTO seasonal_events (event_key, title, description, event_type, multiplier, cargo_type, is_active, ends_at) VALUES
  ('christmas_special', 'Рождественские рейсы', 'Двойная награда за доставку еды!', 'cargo_bonus', 2.0, 'Food', false, NOW() + INTERVAL '30 days'),
  ('euro_marathon', 'Марафон по Европе', 'Доставьте груз в 5 городов за неделю', 'delivery_challenge', 1.0, null, false, NOW() + INTERVAL '30 days'),
  ('xp_frenzy', 'XP Безумие', 'Весь XP x1.5!', 'xp_boost', 1.5, null, false, NOW() + INTERVAL '30 days')
ON CONFLICT (event_key) DO NOTHING;

-- Get active events function
CREATE OR REPLACE FUNCTION get_active_events()
RETURNS TABLE(
  id UUID, event_key TEXT, title TEXT, description TEXT,
  event_type TEXT, multiplier NUMERIC, cargo_type TEXT,
  target_deliveries INTEGER, reward_xp INTEGER, reward_money INTEGER,
  ends_at TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  SELECT id, event_key, title, description, event_type, multiplier, cargo_type,
    target_deliveries, reward_xp, reward_money, ends_at
  FROM seasonal_events
  WHERE is_active AND ends_at > NOW();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Enable realtime
ALTER PUBLICATION supabase_realtime ADD TABLE seasonal_events;
