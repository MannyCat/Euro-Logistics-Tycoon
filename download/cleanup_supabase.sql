-- ============================================================
-- EURO LOGISTICS TYCOON — Полная очистка Supabase
-- Запусти этот скрипт в Supabase SQL Editor:
-- https://supabase.com/dashboard/project/womtwysylililqudzaczne/sql
-- ============================================================

-- 1. Удалить realtime подписки
DO $$
BEGIN
  ALTER PUBLICATION supabase_realtime DROP TABLE IF EXISTS contracts;
  ALTER PUBLICATION supabase_realtime DROP TABLE IF EXISTS trucks;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

-- 2. Удалить cron jobs (если pg_cron включен)
SELECT cron.unschedule('complete_contracts')
WHERE EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'complete_contracts');

-- 3. Удалить все таблицы (CASCADE удалит все зависимости)
DROP TABLE IF EXISTS transactions CASCADE;
DROP TABLE IF EXISTS game_config CASCADE;
DROP TABLE IF EXISTS contracts CASCADE;
DROP TABLE IF EXISTS drivers CASCADE;
DROP TABLE IF EXISTS trucks CASCADE;
DROP TABLE IF EXISTS warehouses CASCADE;
DROP TABLE IF EXISTS companies CASCADE;
DROP TABLE IF EXISTS cities CASCADE;

-- 4. Удалить все функции
DROP FUNCTION IF EXISTS create_company_for_user() CASCADE;
DROP FUNCTION IF EXISTS generate_contracts() CASCADE;
DROP FUNCTION IF EXISTS accept_contract(UUID, UUID, UUID) CASCADE;
DROP FUNCTION IF EXISTS complete_expired_contracts() CASCADE;
DROP FUNCTION IF EXISTS find_nearest_idle_truck(UUID, INTEGER) CASCADE;
DROP FUNCTION IF EXISTS haversine_km(double precision, double precision, double precision, double precision) CASCADE;

-- 5. Удалить триггеры
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- 6. Проверить чистоту
SELECT 'Cleanup complete! Tables: ' || COUNT(*)::text AS result
FROM pg_tables WHERE schemaname = 'public';
