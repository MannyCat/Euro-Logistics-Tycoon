-- Migration: add missing columns & fix enum values
-- Run this in Supabase SQL Editor

-- 1. Add missing columns to ships table
ALTER TABLE ships ADD COLUMN IF NOT EXISTS max_fuel NUMERIC(10,2) NOT NULL DEFAULT 0;
ALTER TABLE ships ADD COLUMN IF NOT EXISTS destination_port_id INTEGER REFERENCES ports(id) ON DELETE SET NULL;
ALTER TABLE ships ADD COLUMN IF NOT EXISTS last_voyage_at TIMESTAMPTZ;

-- 2. Add distance/estimated_hours to voyages (computed client-side, stored for convenience)
ALTER TABLE voyages ADD COLUMN IF NOT EXISTS distance_nm NUMERIC(10,2);
ALTER TABLE voyages ADD COLUMN IF NOT EXISTS estimated_hours NUMERIC(8,2);

-- 3. Add email column to profiles (for convenience display)
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS email TEXT DEFAULT '';

-- Done
