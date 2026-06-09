-- ============================================================
-- EURO LOGISTICS TYCOON — Clan System Migration
-- ============================================================

-- ===== CLANS =====
CREATE TABLE IF NOT EXISTS clans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  tag TEXT NOT NULL,
  description TEXT DEFAULT '',
  leader_id UUID REFERENCES companies(id) ON DELETE SET NULL,
  level INTEGER DEFAULT 1,
  xp INTEGER DEFAULT 0,
  max_members INTEGER DEFAULT 10,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(tag)
);

-- ===== CLAN MEMBERS =====
CREATE TABLE IF NOT EXISTS clan_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  clan_id UUID REFERENCES clans(id) ON DELETE CASCADE,
  company_id UUID REFERENCES companies(id) ON DELETE CASCADE,
  role TEXT NOT NULL DEFAULT 'member',  -- 'leader', 'officer', 'member'
  joined_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(company_id)
);

-- ===== RLS =====
ALTER TABLE clans ENABLE ROW LEVEL SECURITY;
ALTER TABLE clan_members ENABLE ROW LEVEL SECURITY;

-- Clans: readable by all, manage only by leader
CREATE POLICY "clans_read" ON clans FOR SELECT USING (true);
CREATE POLICY "clans_insert" ON clans FOR INSERT WITH CHECK (
  auth.uid() = (SELECT owner_id FROM companies WHERE id = leader_id)
);
CREATE POLICY "clans_update" ON clans FOR UPDATE USING (
  auth.uid() IN (
    SELECT cm.company_id FROM clan_members cm
    JOIN companies c ON c.id = cm.company_id
    WHERE cm.clan_id = clans.id AND cm.role IN ('leader', 'officer')
    AND c.owner_id = auth.uid()
  )
  OR auth.uid() = (SELECT owner_id FROM companies WHERE id = leader_id)
);
CREATE POLICY "clans_delete" ON clans FOR DELETE USING (
  auth.uid() = (SELECT owner_id FROM companies WHERE id = leader_id)
);

-- Clan members: readable by all
CREATE POLICY "clan_members_read" ON clan_members FOR SELECT USING (true);
CREATE POLICY "clan_members_insert" ON clan_members FOR INSERT WITH CHECK (
  -- Leader/officer can add members, or anyone can join if open
  auth.uid() IN (
    SELECT c.owner_id FROM companies c
    JOIN clan_members cm ON cm.company_id = c.id
    WHERE cm.clan_id = clan_members.clan_id AND cm.role IN ('leader', 'officer')
  )
);
CREATE POLICY "clan_members_update" ON clan_members FOR UPDATE USING (
  auth.uid() IN (
    SELECT c.owner_id FROM companies c
    JOIN clan_members cm ON cm.company_id = c.id
    WHERE cm.clan_id = clan_members.clan_id AND cm.role IN ('leader', 'officer')
  )
);
CREATE POLICY "clan_members_delete" ON clan_members FOR DELETE USING (
  -- Can leave own membership, or leader can kick
  auth.uid() = (SELECT owner_id FROM companies WHERE id = company_id)
  OR auth.uid() IN (
    SELECT c.owner_id FROM companies c
    JOIN clan_members cm ON cm.company_id = c.id
    WHERE cm.clan_id = clan_members.clan_id AND cm.role = 'leader'
  )
);

-- ============================================================
-- CLAN FUNCTIONS
-- ============================================================

-- Create a new clan (costs 50000 money)
CREATE OR REPLACE FUNCTION create_clan(p_company_id UUID, p_name TEXT, p_tag TEXT, p_description TEXT)
RETURNS UUID AS $$
DECLARE
  v_clan_id UUID;
  v_cost INTEGER := 50000;
BEGIN
  -- Check company money
  IF (SELECT money FROM companies WHERE id = p_company_id) < v_cost THEN
    RAISE EXCEPTION 'Недостаточно средств';
  END IF;

  -- Check not already in a clan
  IF EXISTS (SELECT 1 FROM clan_members WHERE company_id = p_company_id) THEN
    RAISE EXCEPTION 'Вы уже состоите в клане';
  END IF;

  -- Deduct money
  UPDATE companies SET money = money - v_cost WHERE id = p_company_id;

  -- Create clan
  INSERT INTO clans (name, tag, leader_id, description)
  VALUES (p_name, UPPER(p_tag), p_company_id, COALESCE(p_description, ''))
  RETURNING id INTO v_clan_id;

  -- Add creator as leader
  INSERT INTO clan_members (clan_id, company_id, role)
  VALUES (v_clan_id, p_company_id, 'leader');

  -- Transaction
  INSERT INTO transactions (company_id, type, description, amount)
  VALUES (p_company_id, 'clan_create', 'Создание клана: ' || p_name, -v_cost);

  RETURN v_clan_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Join a clan (anyone can join, if they're not already in one)
CREATE OR REPLACE FUNCTION join_clan(p_company_id UUID, p_clan_id UUID)
RETURNS boolean AS $$
BEGIN
  -- Check not already in a clan
  IF EXISTS (SELECT 1 FROM clan_members WHERE company_id = p_company_id) THEN
    RAISE EXCEPTION 'Вы уже состоите в клане';
  END IF;

  -- Check clan exists
  IF NOT EXISTS (SELECT 1 FROM clans WHERE id = p_clan_id) THEN
    RAISE EXCEPTION 'Клан не найден';
  END IF;

  -- Check max members
  IF (SELECT COUNT(*) FROM clan_members WHERE clan_id = p_clan_id) >=
     (SELECT max_members FROM clans WHERE id = p_clan_id) THEN
    RAISE EXCEPTION 'Клан заполнен';
  END IF;

  INSERT INTO clan_members (clan_id, company_id, role)
  VALUES (p_clan_id, p_company_id, 'member');

  RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Leave a clan
CREATE OR REPLACE FUNCTION leave_clan(p_company_id UUID)
RETURNS boolean AS $$
DECLARE
  v_clan_id UUID;
  v_is_leader BOOLEAN;
BEGIN
  SELECT clan_id INTO v_clan_id FROM clan_members WHERE company_id = p_company_id;
  IF v_clan_id IS NULL THEN
    RAISE EXCEPTION 'Вы не в клане';
  END IF;

  SELECT (role = 'leader') INTO v_is_leader FROM clan_members WHERE company_id = p_company_id;

  -- If leader, check there are other members to transfer leadership to
  IF v_is_leader THEN
    IF EXISTS (SELECT 1 FROM clan_members WHERE clan_id = v_clan_id AND company_id != p_company_id) THEN
      -- Transfer leadership to the first officer, or first member
      UPDATE clan_members SET role = 'leader'
      WHERE company_id = (
        SELECT company_id FROM clan_members
        WHERE clan_id = v_clan_id AND company_id != p_company_id
        ORDER BY CASE role WHEN 'officer' THEN 1 WHEN 'member' THEN 2 END
        LIMIT 1
      );
      -- Update clan leader
      UPDATE clans SET leader_id = (
        SELECT company_id FROM clan_members
        WHERE clan_id = v_clan_id AND company_id != p_company_id
        ORDER BY CASE role WHEN 'officer' THEN 1 WHEN 'member' THEN 2 END
        LIMIT 1
      ) WHERE id = v_clan_id;
    ELSE
      -- Last member — delete the clan
      DELETE FROM clans WHERE id = v_clan_id;
      RETURN true;
    END IF;
  END IF;

  DELETE FROM clan_members WHERE company_id = p_company_id;
  RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Promote/demote clan member (leader/officer only)
CREATE OR REPLACE FUNCTION set_clan_role(p_company_id UUID, p_target_company_id UUID, p_new_role TEXT)
RETURNS boolean AS $$
DECLARE
  v_clan_id UUID;
BEGIN
  -- Check caller is leader/officer
  SELECT clan_id INTO v_clan_id FROM clan_members WHERE company_id = p_company_id;
  IF v_clan_id IS NULL THEN RAISE EXCEPTION 'Вы не в клане'; END IF;

  IF (SELECT role FROM clan_members WHERE company_id = p_company_id) = 'member' THEN
    RAISE EXCEPTION 'Недостаточно прав';
  END IF;

  -- Can't change own role
  IF p_company_id = p_target_company_id THEN
    RAISE EXCEPTION 'Нельзя изменить свою роль';
  END IF;

  UPDATE clan_members SET role = p_new_role
  WHERE company_id = p_target_company_id AND clan_id = v_clan_id;

  RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Kick member (leader/officer only)
CREATE OR REPLACE FUNCTION kick_clan_member(p_company_id UUID, p_target_company_id UUID)
RETURNS boolean AS $$
DECLARE
  v_clan_id UUID;
BEGIN
  SELECT clan_id INTO v_clan_id FROM clan_members WHERE company_id = p_company_id;
  IF v_clan_id IS NULL THEN RAISE EXCEPTION 'Вы не в клане'; END IF;

  IF (SELECT role FROM clan_members WHERE company_id = p_company_id) = 'member' THEN
    RAISE EXCEPTION 'Недостаточно прав';
  END IF;

  -- Can't kick leader
  IF (SELECT role FROM clan_members WHERE company_id = p_target_company_id AND clan_id = v_clan_id) = 'leader' THEN
    RAISE EXCEPTION 'Нельзя исключить лидера';
  END IF;

  DELETE FROM clan_members WHERE company_id = p_target_company_id AND clan_id = v_clan_id;
  RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update clan info (leader only)
CREATE OR REPLACE FUNCTION update_clan_info(p_company_id UUID, p_new_name TEXT, p_new_description TEXT)
RETURNS boolean AS $$
BEGIN
  UPDATE clans SET
    name = COALESCE(p_new_name, name),
    description = COALESCE(p_new_description, description)
  WHERE id = (SELECT clan_id FROM clan_members WHERE company_id = p_company_id)
    AND leader_id = p_company_id;
  RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get clan leaderboard (ranked by total member money)
CREATE OR REPLACE FUNCTION clan_leaderboard()
RETURNS TABLE(
  clan_id UUID,
  clan_name TEXT,
  clan_tag TEXT,
  total_money BIGINT,
  member_count BIGINT,
  avg_level NUMERIC,
  leader_name TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    cl.id AS clan_id,
    cl.name AS clan_name,
    cl.tag AS clan_tag,
    COALESCE(SUM(c.money), 0)::BIGINT AS total_money,
    COUNT(cm.company_id)::BIGINT AS member_count,
    COALESCE(AVG(c.level), 0)::NUMERIC AS avg_level,
    lc.name AS leader_name
  FROM clans cl
  LEFT JOIN clan_members cm ON cm.clan_id = cl.id
  LEFT JOIN companies c ON c.id = cm.company_id
  LEFT JOIN companies lc ON lc.id = cl.leader_id
  GROUP BY cl.id, cl.name, cl.tag, lc.name
  ORDER BY total_money DESC
  LIMIT 20;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get clan details with members
CREATE OR REPLACE FUNCTION get_clan_details(p_clan_id UUID)
RETURNS JSON AS $$
DECLARE
  v_result JSON;
BEGIN
  SELECT json_build_object(
    'clan', row_to_json(cl.*),
    'members', COALESCE((
      SELECT json_agg(json_build_object(
        'company_id', cm.company_id,
        'company_name', c.name,
        'role', cm.role,
        'level', c.level,
        'money', c.money,
        'truck_count', (SELECT COUNT(*) FROM trucks WHERE company_id = cm.company_id),
        'joined_at', cm.joined_at
      ))
      FROM clan_members cm
      JOIN companies c ON c.id = cm.company_id
      WHERE cm.clan_id = p_clan_id
      ORDER BY CASE cm.role WHEN 'leader' THEN 1 WHEN 'officer' THEN 2 ELSE 3 END
    ), '[]'::json)
  ) INTO v_result
  FROM clans cl
  WHERE cl.id = p_clan_id;

  RETURN COALESCE(v_result, '{}'::json);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Enable realtime for clan_members
ALTER PUBLICATION supabase_realtime ADD TABLE clan_members;
