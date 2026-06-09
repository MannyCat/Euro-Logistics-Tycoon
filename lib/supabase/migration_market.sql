-- Player market listings
CREATE TABLE IF NOT EXISTS market_listings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  seller_id UUID NOT NULL REFERENCES companies(id),
  listing_type TEXT NOT NULL, -- 'truck', 'driver'
  item_id UUID NOT NULL, -- truck.id or driver.id
  item_name TEXT NOT NULL,
  item_details JSONB DEFAULT '{}', -- truck_type, skill_level etc
  price INTEGER NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '72 hours')
);

-- RLS
ALTER TABLE market_listings ENABLE ROW LEVEL SECURITY;
CREATE POLICY "market_read" ON market_listings FOR SELECT USING (true);
CREATE POLICY "market_insert" ON market_listings FOR INSERT WITH CHECK (
  seller_id IN (SELECT id FROM companies WHERE owner_id = auth.uid())
);
CREATE POLICY "market_delete" ON market_listings FOR DELETE USING (
  seller_id IN (SELECT id FROM companies WHERE owner_id = auth.uid())
);

CREATE INDEX IF NOT EXISTS idx_market_created ON market_listings(created_at DESC);

-- List truck for sale
CREATE OR REPLACE FUNCTION list_truck_on_market(p_truck_id UUID, p_company_id UUID, p_price INTEGER)
RETURNS UUID AS $$
DECLARE
  v_truck RECORD;
  v_listing_id UUID;
BEGIN
  SELECT * INTO v_truck FROM trucks WHERE id = p_truck_id AND company_id = p_company_id;
  IF v_truck.id IS NULL THEN RAISE EXCEPTION 'Грузовик не найден'; END IF;
  IF v_truck.status != 'idle' THEN RAISE EXCEPTION 'Только свободные грузовики'; END IF;
  
  INSERT INTO market_listings (seller_id, listing_type, item_id, item_name, item_details, price)
  VALUES (p_company_id, 'truck', p_truck_id, v_truck.name, 
    jsonb_build_object('truck_type', v_truck.truck_type, 'condition', v_truck.condition_pct),
    p_price)
  RETURNING id INTO v_listing_id;
  
  -- Remove truck from company
  DELETE FROM trucks WHERE id = p_truck_id;
  
  RETURN v_listing_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Buy from market
CREATE OR REPLACE FUNCTION buy_from_market(p_listing_id UUID, p_buyer_id UUID)
RETURNS boolean AS $$
DECLARE
  v_listing RECORD;
BEGIN
  SELECT * INTO v_listing FROM market_listings WHERE id = p_listing_id FOR UPDATE;
  IF v_listing.id IS NULL THEN RAISE EXCEPTION 'Лот не найден'; END IF;
  IF v_listing.seller_id = p_buyer_id THEN RAISE EXCEPTION 'Нельзя купить свой лот'; END IF;
  IF v_listing.expires_at < NOW() THEN RAISE EXCEPTION 'Лот истёк'; END IF;
  
  -- Check buyer money
  IF (SELECT money FROM companies WHERE id = p_buyer_id) < v_listing.price THEN
    RAISE EXCEPTION 'Недостаточно средств';
  END IF;
  
  -- Transfer money
  UPDATE companies SET money = money - v_listing.price WHERE id = p_buyer_id;
  UPDATE companies SET money = money + v_listing.price WHERE id = v_listing.seller_id;
  
  -- Create item for buyer
  IF v_listing.listing_type = 'truck' THEN
    INSERT INTO trucks (company_id, truck_type, name, status, condition_pct, fuel_level, max_fuel, current_city_id, purchase_price)
    SELECT p_buyer_id, 
      (v_listing.item_details->>'truck_type')::TEXT,
      v_listing.item_name,
      'idle',
      (v_listing.item_details->>'condition')::INTEGER,
      100, 100,
      (SELECT COALESCE(current_city_id, 1) FROM companies WHERE id = p_buyer_id LIMIT 1),
      v_listing.price;
  END IF;
  
  -- Log transactions
  INSERT INTO transactions (company_id, type, description, amount)
  VALUES (p_buyer_id, 'market_buy', 'Покупка: ' || v_listing.item_name, -v_listing.price);
  INSERT INTO transactions (company_id, type, description, amount)
  VALUES (v_listing.seller_id, 'market_sell', 'Продажа: ' || v_listing.item_name, v_listing.price);
  
  -- Remove listing
  DELETE FROM market_listings WHERE id = p_listing_id;
  
  RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
