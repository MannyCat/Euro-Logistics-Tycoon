import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'

serve(async (req) => {
  try {
    if (req.method !== 'POST') {
      return new Response(JSON.stringify({ error: 'Method not allowed' }), { status: 405 })
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const { createClient } = await import('https://esm.sh/@supabase/supabase-js@2')
    const supabase = createClient(supabaseUrl, supabaseKey)

    // The fix: we cannot run raw SQL via the JS client, but we can use the pg admin API
    // Instead, let's use the internal /rpc endpoint approach
    // Actually, the best approach is to use the Supabase Management API

    // Alternative: Use Deno PostgreSQL client
    const dbHost = Deno.env.get('SUPABASE_DB_HOST') || ''
    const dbPassword = Deno.env.get('SUPABASE_DB_PASSWORD') || ''

    if (!dbHost || !dbPassword) {
      return new Response(JSON.stringify({ 
        error: 'Missing DB credentials. Need SUPABASE_DB_HOST and SUPABASE_DB_PASSWORD env vars.' 
      }), { status: 500 })
    }

    const { postgres } = await import('https://deno.land/x/postgres@v0.17.0/mod.ts')
    const db = postgres({
      hostname: dbHost,
      port: 5432,
      database: 'postgres',
      user: 'postgres',
      password: dbPassword,
      ssl: true,
    })

    await db.queryObject`
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
        SELECT * INTO v_contract FROM contracts WHERE id = p_contract_id AND status = 'available';
        IF NOT FOUND THEN RETURN false; END IF;

        IF p_truck_id IS NULL THEN
          v_truck_id := find_nearest_idle_truck(p_company_id, v_contract.origin_city_id);
          IF v_truck_id IS NULL THEN RETURN false; END IF;
        ELSE
          v_truck_id := p_truck_id;
        END IF;

        SELECT * INTO v_truck FROM trucks WHERE id = v_truck_id AND status = 'idle' AND company_id = p_company_id;
        IF NOT FOUND THEN RETURN false; END IF;

        SELECT truck_types INTO v_truck_type FROM game_config WHERE id = 1;
        v_speed := 80;
        IF v_truck_type IS NOT NULL THEN
          SELECT (elem->>'speed')::INT INTO v_speed
          FROM jsonb_array_elements(v_truck_type) AS elem
          WHERE elem->>'type' = v_truck.truck_type
          LIMIT 1;
          IF v_speed IS NULL THEN v_speed := 80; END IF;
        END IF;

        SELECT haversine_km(o.latitude, o.longitude, d.latitude, d.longitude) INTO v_dist
        FROM cities o, cities d WHERE o.id = v_contract.origin_city_id AND d.id = v_contract.destination_city_id;

        v_eta := NOW() + (v_dist / v_speed) * INTERVAL '1 hour';
        v_fuel_cost := v_dist * 2;

        UPDATE contracts SET
          status = 'accepted',
          assigned_company_id = p_company_id,
          assigned_truck_id = v_truck_id
        WHERE id = p_contract_id;

        UPDATE trucks SET
          status = 'loading',
          origin_city_id = v_contract.origin_city_id,
          destination_city_id = v_contract.destination_city_id,
          contract_id = p_contract_id,
          departure_time = NOW(),
          estimated_arrival = v_eta,
          fuel_level = GREATEST(fuel_level - v_fuel_cost * 0.1, 0)
        WHERE id = v_truck_id;

        INSERT INTO transactions (company_id, type, description, amount)
        VALUES (p_company_id, 'contract_accepted',
          'Контракт: ' || v_contract.cargo_type || ' (' || ROUND(v_dist) || 'km)',
          -(ROUND(v_fuel_cost))::BIGINT
        );

        RETURN true;
      END;
      $$ LANGUAGE plpgsql SECURITY DEFINER;
    `

    await db.end()

    return new Response(JSON.stringify({ success: true, message: 'accept_contract function fixed!' }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
    })
  } catch (err) {
    return new Response(JSON.stringify({ error: String(err) }), { status: 500 })
  }
})
