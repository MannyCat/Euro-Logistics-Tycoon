-- Event log table
CREATE TABLE IF NOT EXISTS event_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  event_type TEXT NOT NULL, -- 'contract_completed', 'contract_accepted', 'truck_purchased', 'truck_sold', 'driver_hired', 'driver_fired', 'warehouse_bought', 'refuel', 'repair', 'money_earned', 'level_up', 'achievement_unlocked', 'clan_joined', 'clan_created', 'clan_left'
  title TEXT NOT NULL,      -- Short description e.g. "Рейс завершён"
  description TEXT DEFAULT '', -- Detailed description
  icon_name TEXT DEFAULT 'info', -- Icon identifier
  color_hex TEXT DEFAULT '66BB6A', -- Color for the icon
  metadata JSONB DEFAULT '{}', -- Extra data (amount, truck_name, city_name etc.)
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS
ALTER TABLE event_log ENABLE ROW LEVEL SECURITY;
CREATE POLICY "event_log_read" ON event_log FOR SELECT USING (
  company_id IN (SELECT id FROM companies WHERE owner_id = auth.uid())
);
CREATE POLICY "event_log_insert" ON event_log FOR INSERT WITH CHECK (
  company_id IN (SELECT id FROM companies WHERE owner_id = auth.uid())
);

-- Index for fast queries
CREATE INDEX IF NOT EXISTS idx_event_log_company_created ON event_log(company_id, created_at DESC);

-- Function to log events
CREATE OR REPLACE FUNCTION log_event(
  p_company_id UUID,
  p_event_type TEXT,
  p_title TEXT,
  p_description TEXT DEFAULT '',
  p_icon_name TEXT DEFAULT 'info',
  p_color_hex TEXT DEFAULT '66BB6A',
  p_metadata JSONB DEFAULT '{}'
) RETURNS UUID AS $$
DECLARE
  v_id UUID;
BEGIN
  INSERT INTO event_log (company_id, event_type, title, description, icon_name, color_hex, metadata)
  VALUES (p_company_id, p_event_type, p_title, p_description, p_icon_name, p_color_hex, p_metadata)
  RETURNING id INTO v_id;
  RETURN v_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
