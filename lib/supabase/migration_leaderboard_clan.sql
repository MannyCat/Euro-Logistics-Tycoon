-- Migration: Add clan tag to leaderboard view
-- Joins clan_members and clans to include clan tag for each company

CREATE OR REPLACE VIEW public.leaderboard AS
SELECT
  c.id, c.name, c.level, c.xp, c.money, c.reputation,
  (SELECT count(*) FROM public.trucks WHERE company_id = c.id) AS truck_count,
  (SELECT count(*) FROM public.achievements WHERE company_id = c.id) AS achievement_count,
  (SELECT count(*) FROM public.contracts WHERE assigned_company_id = c.id AND status = 'completed') AS completed_contracts,
  cl.tag AS clan_tag
FROM public.companies c
LEFT JOIN public.clan_members cm ON cm.company_id = c.id
LEFT JOIN public.clans cl ON cl.id = cm.clan_id
ORDER BY c.level DESC, c.xp DESC, c.money DESC;
