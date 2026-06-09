-- ============================================================
-- EURO LOGISTICS TYCOON — Clan Missions & Clan Chat Migration
-- ============================================================

-- ===== CLAN MISSIONS =====
CREATE TABLE IF NOT EXISTS clan_missions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  clan_id UUID NOT NULL REFERENCES clans(id) ON DELETE CASCADE,
  mission_type TEXT NOT NULL, -- 'deliver_cargo', 'earn_money', 'deliver_cities'
  title TEXT NOT NULL,
  description TEXT DEFAULT '',
  target_value INTEGER NOT NULL, -- target number
  current_progress INTEGER DEFAULT 0,
  reward_xp INTEGER DEFAULT 500,
  reward_money INTEGER DEFAULT 0,
  expires_at TIMESTAMPTZ NOT NULL,
  completed BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS
ALTER TABLE clan_missions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "clan_missions_read" ON clan_missions FOR SELECT USING (true);
CREATE POLICY "clan_missions_insert" ON clan_missions FOR INSERT WITH CHECK (true);
CREATE POLICY "clan_missions_update" ON clan_missions FOR UPDATE USING (true);

-- Generate clan missions (called periodically or on demand)
CREATE OR REPLACE FUNCTION generate_clan_missions()
RETURNS void AS $$
BEGIN
  -- Generate missions for clans that have fewer than 3 active missions
  INSERT INTO clan_missions (clan_id, mission_type, title, description, target_value, reward_xp, reward_money, expires_at)
  SELECT
    cl.id,
    CASE (random() * 3)::int
      WHEN 0 THEN 'deliver_cargo'
      WHEN 1 THEN 'earn_money'
      ELSE 'deliver_cities'
    END,
    CASE (random() * 3)::int
      WHEN 0 THEN 'Массовая доставка'
      WHEN 1 THEN 'Клановый бюджет'
      ELSE 'Евро-тур'
    END,
    CASE (random() * 3)::int
      WHEN 0 THEN 'Доставьте ' || (5 + (random() * 15)::int) || ' тонн груза'
      WHEN 1 THEN 'Заработайте €' || (100 + (random() * 400)::int) || 'K'
      ELSE 'Доставьте груз в ' || (3 + (random() * 5)::int) || ' разных городов'
    END,
    CASE (random() * 3)::int
      WHEN 0 THEN 5 + (random() * 15)::int * 10  -- 50-200 tons
      WHEN 1 THEN (100 + (random() * 400)::int) * 1000  -- 100K-500K
      ELSE 3 + (random() * 5)::int  -- 3-8 cities
    END,
    500 + (random() * 500)::int,
    CASE (random() * 3)::int
      WHEN 0 THEN 0
      WHEN 1 THEN (50 + (random() * 200)::int) * 1000
      ELSE (20 + (random() * 80)::int) * 1000
    END,
    NOW() + INTERVAL '48 hours'
  FROM clans cl
  WHERE cl.id NOT IN (
    SELECT DISTINCT clan_id FROM clan_missions
    WHERE completed = false AND expires_at > NOW()
  )
  AND (
    SELECT COUNT(*) FROM clan_missions
    WHERE clan_id = cl.id AND completed = false AND expires_at > NOW()
  ) < 3;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get clan missions
CREATE OR REPLACE FUNCTION get_clan_missions(p_clan_id UUID)
RETURNS TABLE(
  id UUID, mission_type TEXT, title TEXT, description TEXT,
  target_value INTEGER, current_progress INTEGER,
  reward_xp INTEGER, reward_money INTEGER,
  expires_at TIMESTAMPTZ, completed BOOLEAN
) AS $$
BEGIN
  RETURN QUERY
  SELECT cm.id, cm.mission_type, cm.title, cm.description,
    cm.target_value, cm.current_progress, cm.reward_xp, cm.reward_money,
    cm.expires_at, cm.completed
  FROM clan_missions cm
  WHERE cm.clan_id = p_clan_id
  ORDER BY cm.completed, cm.expires_at ASC
  LIMIT 5;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Enable realtime for clan_missions
ALTER PUBLICATION supabase_realtime ADD TABLE clan_missions;

-- ===== CLAN CHAT =====
CREATE TABLE IF NOT EXISTS clan_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  clan_id UUID NOT NULL REFERENCES clans(id) ON DELETE CASCADE,
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS
ALTER TABLE clan_messages ENABLE ROW LEVEL SECURITY;
CREATE POLICY "clan_messages_read" ON clan_messages FOR SELECT USING (true);
CREATE POLICY "clan_messages_insert" ON clan_messages FOR INSERT WITH CHECK (
  company_id IN (SELECT id FROM companies WHERE owner_id = auth.uid())
  AND clan_id IN (SELECT clan_id FROM clan_members WHERE company_id = company_id)
);
CREATE POLICY "clan_messages_delete" ON clan_messages FOR DELETE USING (
  company_id IN (SELECT id FROM companies WHERE owner_id = auth.uid())
);

-- Index
CREATE INDEX IF NOT EXISTS idx_clan_messages_clan_created ON clan_messages(clan_id, created_at DESC);

-- Enable realtime for clan_messages
ALTER PUBLICATION supabase_realtime ADD TABLE clan_messages;

-- Function to send clan message
CREATE OR REPLACE FUNCTION send_clan_message(p_company_id UUID, p_content TEXT)
RETURNS UUID AS $$
DECLARE
  v_clan_id UUID;
  v_msg_id UUID;
BEGIN
  SELECT clan_id INTO v_clan_id FROM clan_members WHERE company_id = p_company_id;
  IF v_clan_id IS NULL THEN RAISE EXCEPTION 'Вы не в клане'; END IF;
  IF LENGTH(p_content) > 500 THEN RAISE EXCEPTION 'Сообщение слишком длинное'; END IF;

  INSERT INTO clan_messages (clan_id, company_id, content)
  VALUES (v_clan_id, p_company_id, TRIM(p_content))
  RETURNING id INTO v_msg_id;

  RETURN v_msg_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get clan messages with sender names
CREATE OR REPLACE FUNCTION get_clan_messages(p_clan_id UUID)
RETURNS TABLE(
  id UUID, clan_id UUID, company_id UUID, content TEXT,
  created_at TIMESTAMPTZ, sender_name TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT cm.id, cm.clan_id, cm.company_id, cm.content,
    cm.created_at, c.name AS sender_name
  FROM clan_messages cm
  JOIN companies c ON c.id = cm.company_id
  WHERE cm.clan_id = p_clan_id
  ORDER BY cm.created_at DESC
  LIMIT 50;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;