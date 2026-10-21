-- ============================================================
-- DaNang SmartTour AI — Complete Database Schema
-- Run this entire file in Supabase SQL Editor
-- ============================================================

-- 001 Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
-- CREATE EXTENSION IF NOT EXISTS postgis; -- optional, use lat/lng floats for simplicity

-- 002 Enums
CREATE TYPE safety_level AS ENUM ('RED', 'YELLOW', 'GREEN');
CREATE TYPE allergen_code AS ENUM ('peanut', 'seafood', 'fish', 'shellfish', 'pork', 'beef', 'gluten', 'dairy', 'egg', 'soy', 'nuts', 'sesame');
CREATE TYPE diet_rule AS ENUM ('halal', 'kosher', 'vegetarian', 'vegan', 'pescatarian');
CREATE TYPE fitness_level AS ENUM ('low', 'moderate', 'high');
CREATE TYPE trip_purpose AS ENUM ('culture', 'sport', 'food', 'mixed');
CREATE TYPE attraction_category AS ENUM ('culture', 'sport', 'food', 'nature');
CREATE TYPE difficulty AS ENUM ('easy', 'moderate', 'hard');
CREATE TYPE density AS ENUM ('low', 'medium', 'high', 'overloaded');
CREATE TYPE itinerary_status AS ENUM ('draft', 'saved', 'verified', 'active', 'completed', 'failed');

-- 003 Profiles & Health Profiles
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name TEXT,
  preferred_language TEXT DEFAULT 'en',
  nationality TEXT,
  fitness_level fitness_level DEFAULT 'moderate',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "own_profile" ON profiles USING (auth.uid() = id) WITH CHECK (auth.uid() = id);

CREATE TABLE health_profiles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  allergen allergen_code NOT NULL,
  severity TEXT NOT NULL CHECK (severity IN ('mild', 'moderate', 'severe', 'anaphylaxis')),
  condition_code TEXT,
  condition_severity TEXT CHECK (condition_severity IN ('mild', 'moderate', 'severe')),
  diet_rule diet_rule,
  diet_strictness TEXT CHECK (diet_strictness IN ('strict', 'moderate', 'flexible')) DEFAULT 'strict',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (user_id, allergen),
  UNIQUE (user_id, condition_code),
  UNIQUE (user_id, diet_rule)
);

ALTER TABLE health_profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "own_health" ON health_profiles USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- 004 Reference Data: Dishes
CREATE TABLE dishes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name_vi TEXT NOT NULL,
  name_en TEXT NOT NULL,
  description_vi TEXT,
  description_en TEXT,
  hidden_ingredients JSONB DEFAULT '[]'::jsonb,
  allergen_flags JSONB DEFAULT '{}'::jsonb,
  dietary_verdict JSONB DEFAULT '{}'::jsonb,
  contains_pork BOOLEAN DEFAULT FALSE,
  contains_alcohol BOOLEAN DEFAULT FALSE,
  spice_level INTEGER CHECK (spice_level BETWEEN 0 AND 5) DEFAULT 0,
  price_range TEXT,
  image_url TEXT,
  confidence_score FLOAT DEFAULT 1.0,
  requires_kitchen_confirmation BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE dishes ENABLE ROW LEVEL SECURITY;
CREATE POLICY "public_read_dishes" ON dishes FOR SELECT USING (true);
CREATE INDEX idx_dishes_allergen_flags ON dishes USING GIN (allergen_flags);
CREATE INDEX idx_dishes_dietary_verdict ON dishes USING GIN (dietary_verdict);

-- 004 Reference Data: Attractions
CREATE TABLE attractions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name_vi TEXT NOT NULL,
  name_en TEXT NOT NULL,
  category attraction_category NOT NULL,
  description_vi TEXT,
  description_en TEXT,
  lat DOUBLE PRECISION NOT NULL,
  lng DOUBLE PRECISION NOT NULL,
  difficulty difficulty DEFAULT 'easy',
  physical_requirements JSONB DEFAULT '{}'::jsonb,
  dress_code TEXT,
  cultural_notes TEXT,
  typical_crowd_hours JSONB DEFAULT '[]'::jsonb,
  opening_hours JSONB,
  entry_fee_vnd INTEGER DEFAULT 0,
  image_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE attractions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "public_read_attractions" ON attractions FOR SELECT USING (true);
CREATE INDEX idx_attractions_category ON attractions (category);
CREATE INDEX idx_attractions_location ON attractions (lat, lng);

-- 005 Itineraries & Stops
CREATE TABLE itineraries (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  purpose trip_purpose NOT NULL,
  status itinerary_status DEFAULT 'draft',
  start_date DATE,
  end_date DATE,
  budget_vnd BIGINT,
  safety_flags JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE itineraries ENABLE ROW LEVEL SECURITY;
CREATE POLICY "own_itinerary" ON itineraries USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE INDEX idx_itineraries_user ON itineraries (user_id);

CREATE TABLE itinerary_stops (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  itinerary_id UUID NOT NULL REFERENCES itineraries(id) ON DELETE CASCADE,
  attraction_id UUID REFERENCES attractions(id) ON DELETE SET NULL,
  dish_id UUID REFERENCES dishes(id) ON DELETE SET NULL,
  order_index INTEGER NOT NULL,
  scheduled_time TIMESTAMPTZ,
  safety_level safety_level NOT NULL,
  safety_reasons JSONB DEFAULT '[]'::jsonb,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (itinerary_id, order_index)
);

ALTER TABLE itinerary_stops ENABLE ROW LEVEL SECURITY;
CREATE POLICY "own_stops" ON itinerary_stops
  USING (EXISTS (SELECT 1 FROM itineraries i WHERE i.id = itinerary_stops.itinerary_id AND i.user_id = auth.uid()))
  WITH CHECK (EXISTS (SELECT 1 FROM itineraries i WHERE i.id = itinerary_stops.itinerary_id AND i.user_id = auth.uid()));
CREATE INDEX idx_itinerary_stops_itinerary ON itinerary_stops (itinerary_id);

-- 006 Safety Tickets
CREATE TABLE safety_tickets (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  itinerary_id UUID REFERENCES itineraries(id) ON DELETE SET NULL,
  dish_id UUID REFERENCES dishes(id) ON DELETE SET NULL,
  ticket_code TEXT UNIQUE NOT NULL,
  allergy_flags JSONB NOT NULL,
  health_warnings JSONB DEFAULT '[]'::jsonb,
  safety_level safety_level NOT NULL,
  bilingual_text JSONB NOT NULL,
  verified BOOLEAN DEFAULT FALSE,
  verified_at TIMESTAMPTZ,
  expires_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE safety_tickets ENABLE ROW LEVEL SECURITY;
CREATE POLICY "own_tickets" ON safety_tickets USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE INDEX idx_safety_tickets_user ON safety_tickets (user_id);
CREATE INDEX idx_safety_tickets_code ON safety_tickets (ticket_code);

-- 007 Crowd Reports & Reroute Events
CREATE TABLE crowd_reports (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  attraction_id UUID NOT NULL REFERENCES attractions(id) ON DELETE CASCADE,
  reporter_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  reported_at TIMESTAMPTZ DEFAULT NOW(),
  density density NOT NULL,
  source TEXT CHECK (source IN ('user', 'simulated', 'sensor')) DEFAULT 'simulated',
  traffic_note TEXT,
  lat DOUBLE PRECISION,
  lng DOUBLE PRECISION,
  expires_at TIMESTAMPTZ GENERATED ALWAYS AS (reported_at + INTERVAL '2 hours') STORED
);

ALTER TABLE crowd_reports ENABLE ROW LEVEL SECURITY;
CREATE POLICY "public_read_crowd" ON crowd_reports FOR SELECT USING (true);
CREATE POLICY "insert_own_crowd" ON crowd_reports FOR INSERT WITH CHECK (auth.uid() = reporter_id OR reporter_id IS NULL);
CREATE INDEX idx_crowd_reports_attraction ON crowd_reports (attraction_id);
CREATE INDEX idx_crowd_reports_reported_at ON crowd_reports (reported_at);

CREATE TABLE reroute_events (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  itinerary_id UUID REFERENCES itineraries(id) ON DELETE SET NULL,
  from_attraction_id UUID REFERENCES attractions(id) ON DELETE SET NULL,
  to_attraction_id UUID REFERENCES attractions(id) ON DELETE SET NULL,
  reason TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE reroute_events ENABLE ROW LEVEL SECURITY;
CREATE POLICY "own_reroutes" ON reroute_events USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- 008 Agent Logs (traceability)
CREATE TABLE agent_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  tool_name TEXT NOT NULL,
  input JSONB,
  output JSONB,
  success BOOLEAN NOT NULL,
  error_message TEXT,
  latency_ms INTEGER,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE agent_logs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "own_logs" ON agent_logs USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE INDEX idx_agent_logs_user ON agent_logs (user_id);
CREATE INDEX idx_agent_logs_tool ON agent_logs (tool_name);

-- 009 Helper Functions & Triggers
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON profiles FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_dishes_updated_at BEFORE UPDATE ON dishes FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_attractions_updated_at BEFORE UPDATE ON attractions FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_itineraries_updated_at BEFORE UPDATE ON itineraries FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 010 Seed: 40 Da Nang Dishes (sample 10 shown, add remaining 30)
INSERT INTO dishes (name_vi, name_en, description_vi, description_en, hidden_ingredients, allergen_flags, dietary_verdict, contains_pork, contains_alcohol, spice_level, price_range, confidence_score, requires_kitchen_confirmation) VALUES
('Mì Quảng', 'Mi Quang', 'Mì đặc sản Quảng Nam với nước dùng ninh xương heo, tôm, thịt heo, trứng cút, rau thơm, bánh tráng nướng', 'Quang noodle with pork bone broth, shrimp, pork, quail eggs, herbs, rice crackers', '[{"ingredient": "pork_bone_broth", "category": "meat", "source": "simmered"}, {"ingredient": "peanut_oil", "category": "oil", "source": "fried_shallots"}, {"ingredient": "peanuts", "category": "nut", "source": "roasted_topping"}, {"ingredient": "fish_sauce", "category": "sauce", "source": "seasoning"}, {"ingredient": "annatto_oil", "category": "oil", "source": "color"}]'::jsonb, '{"pork": true, "peanut": true, "fish": true, "shellfish": true}'::jsonb, '{"halal": false, "kosher": false, "vegetarian": false, "vegan": false, "pescatarian": false}'::jsonb, true, false, 1, '30k-50k VND', 1.0, false),
('Bún chả cá', 'Bun Cha Ca', 'Bún với chả cá ninh nước dùng xương heo, mắm nem, rau thơm, đậu phộng rang', 'Noodles with fish cake in pork bone broth, fermented fish sauce, herbs, roasted peanuts', '[{"ingredient": "pork_bone_broth", "category": "meat", "source": "simmered"}, {"ingredient": "fish_cake", "category": "seafood", "source": "processed"}, {"ingredient": "peanuts", "category": "nut", "source": "roasted_topping"}, {"ingredient": "fermented_fish_sauce", "category": "sauce", "source": "seasoning"}, {"ingredient": "pork_fat", "category": "meat", "source": "fried_shallots"}]'::jsonb, '{"pork": true, "peanut": true, "fish": true}'::jsonb, '{"halal": false, "kosher": false, "vegetarian": false, "vegan": false, "pescatarian": false}'::jsonb, true, false, 1, '35k-55k VND', 1.0, false),
('Bánh xèo', 'Banh Xeo', 'Bánh xèo giòn nhân tôm, thịt heo, giá đỗ, rau thơm, nước mắm chua ngọt', 'Crispy pancake with shrimp, pork, bean sprouts, herbs, sweet-sour fish sauce', '[{"ingredient": "rice_flour", "category": "grain", "source": "batter"}, {"ingredient": "turmeric", "category": "spice", "source": "color"}, {"ingredient": "shrimp", "category": "shellfish", "source": "filling"}, {"ingredient": "pork", "category": "meat", "source": "filling"}, {"ingredient": "peanut_oil", "category": "oil", "source": "frying"}, {"ingredient": "fish_sauce", "category": "sauce", "source": "dipping"}]'::jsonb, '{"pork": true, "peanut": true, "fish": true, "shellfish": true}'::jsonb, '{"halal": false, "kosher": false, "vegetarian": false, "vegan": false, "pescatarian": false}'::jsonb, true, false, 1, '25k-40k VND', 1.0, false),
('Bánh tráng cuốn thịt heo', 'Ban Trang Cuon Thit Heo', 'Bánh tráng cuốn thịt heo luộc, rau sống, nem chua, chấm mắm nem', 'Rice paper rolls with boiled pork, fresh herbs, fermented pork, fish sauce dip', '[{"ingredient": "pork", "category": "meat", "source": "boiled"}, {"ingredient": "fermented_pork", "category": "meat", "source": "nem_chua"}, {"ingredient": "peanuts", "category": "nut", "source": "dipping_sauce"}, {"ingredient": "fish_sauce", "category": "sauce", "source": "dipping"}]'::jsonb, '{"pork": true, "peanut": true, "fish": true}'::jsonb, '{"halal": false, "kosher": false, "vegetarian": false, "vegan": false, "pescatarian": false}'::jsonb, true, false, 1, '40k-60k VND', 1.0, false),
('Bánh canh chả cá', 'Banh Canh Cha Ca', 'Bánh canh sợi to với chả cá, nước dùng xương heo, rau thơm', 'Thick noodle soup with fish cake, pork bone broth, herbs', '[{"ingredient": "pork_bone_broth", "category": "meat", "source": "simmered"}, {"ingredient": "fish_cake", "category": "seafood", "source": "processed"}, {"ingredient": "tapioca_noodles", "category": "grain", "source": "noodle"}, {"ingredient": "peanuts", "category": "nut", "source": "topping"}]'::jsonb, '{"pork": true, "peanut": true, "fish": true}'::jsonb, '{"halal": false, "kosher": false, "vegetarian": false, "vegan": false, "pescatarian": false}'::jsonb, true, false, 1, '30k-45k VND', 1.0, false),
('Mì Quảng ếch', 'Mi Quang Ech', 'Mì Quảng với ếch xào sả ớt, nước dùng xương heo', 'Mi Quang with frog stir-fried lemongrass chili, pork bone broth', '[{"ingredient": "pork_bone_broth", "category": "meat", "source": "simmered"}, {"ingredient": "frog_meat", "category": "meat", "source": "protein"}, {"ingredient": "peanut_oil", "category": "oil", "source": "cooking"}, {"ingredient": "peanuts", "category": "nut", "source": "topping"}]'::jsonb, '{"pork": true, "peanut": true}'::jsonb, '{"halal": false, "kosher": false, "vegetarian": false, "vegan": false, "pescatarian": false}'::jsonb, true, false, 2, '40k-60k VND', 0.9, true),
('Bún mắm', 'Bun Mam', 'Bún với nước mắm nêm chín, tôm, thịt heo, rau muống, đậu phộng', 'Noodles with fermented fish sauce, shrimp, pork, water spinach, peanuts', '[{"ingredient": "fermented_fish_sauce", "category": "sauce", "source": "broth_base"}, {"ingredient": "pork", "category": "meat", "source": "protein"}, {"ingredient": "shrimp", "category": "shellfish", "source": "protein"}, {"ingredient": "peanuts", "category": "nut", "source": "topping"}]'::jsonb, '{"pork": true, "peanut": true, "fish": true, "shellfish": true}'::jsonb, '{"halal": false, "kosher": false, "vegetarian": false, "vegan": false, "pescatarian": false}'::jsonb, true, false, 2, '35k-50k VND', 1.0, false),
('Bánh bèo', 'Banh Beo', 'Bánh bèo hấp tôm chấy, mỡ hành, nước mắm chấm', 'Steamed rice cakes with dried shrimp, scallion oil, fish sauce', '[{"ingredient": "rice_flour", "category": "grain", "source": "batter"}, {"ingredient": "dried_shrimp", "category": "shellfish", "source": "topping"}, {"ingredient": "pork_fat", "category": "meat", "source": "scallion_oil"}, {"ingredient": "fish_sauce", "category": "sauce", "source": "dipping"}]'::jsonb, '{"pork": true, "fish": true, "shellfish": true}'::jsonb, '{"halal": false, "kosher": false, "vegetarian": false, "vegan": false, "pescatarian": false}'::jsonb, true, false, 0, '20k-30k VND', 1.0, false),
('Bánh bột lọc', 'Banh Bot Loc', 'Bánh bột lọc trong nhân tôm thịt, mỡ hành, chấm nước mắm', 'Clear tapioca dumplings with shrimp, pork, scallion oil, fish sauce', '[{"ingredient": "tapioca_flour", "category": "grain", "source": "wrapper"}, {"ingredient": "shrimp", "category": "shellfish", "source": "filling"}, {"ingredient": "pork", "category": "meat", "source": "filling"}, {"ingredient": "pork_fat", "category": "meat", "source": "scallion_oil"}]'::jsonb, '{"pork": true, "shellfish": true}'::jsonb, '{"halal": false, "kosher": false, "vegetarian": false, "vegan": false, "pescatarian": false}'::jsonb, true, false, 0, '25k-35k VND', 1.0, false),
('Nem lụi', 'Nem Lui', 'Nem lụi nướng than hoa, cuốn bánh tráng, rau sống, chấm mắm nem', 'Grilled lemongrass pork skewers wrapped in rice paper, herbs, fermented fish sauce', '[{"ingredient": "pork", "category": "meat", "source": "grilled"}, {"ingredient": "peanut_sauce", "category": "sauce", "source": "dipping"}, {"ingredient": "fermented_fish_sauce", "category": "sauce", "source": "dipping"}]'::jsonb, '{"pork": true, "peanut": true, "fish": true}'::jsonb, '{"halal": false, "kosher": false, "vegetarian": false, "vegan": false, "pescatarian": false}'::jsonb, true, false, 1, '40k-55k VND', 1.0, false);

-- Add 30 more dishes: Bún thịt nướng, Cao lầu, Mì xào hải sản, Bánh mì thịt nướng, Chè bắp, Chè đậu xanh, Sinh tố bơ, Sinh tố sầu riêng, Trà đá, Cà phê sữa đá, Nước mía, Nước dừa, Bia Đà Nẵng, Rượu cần, Mì Cay, Bún riêu, Bún bò Huế, Phở bò, Phở gà, Hủ tiếu, Bánh mì chảo, Bánh xèo chay, Gỏi cuốn chay, Bún chay, Mì Quảng chay, Cơm chay, Bánh mì chay, Chả cá chiên, Cá nướng lá chuối, Súp cua, Súp hải sản.

-- 011 Seed: 20 Attractions (sample 10 shown, add remaining 10)
INSERT INTO attractions (name_vi, name_en, category, description_vi, description_en, lat, lng, difficulty, physical_requirements, dress_code, cultural_notes, typical_crowd_hours, opening_hours, entry_fee_vnd) VALUES
('Bán đảo Sơn Trà', 'Son Tra Peninsula', 'nature', 'Bán đảo xanh mát với voọc chân nâu, đường trekking Mũi Nghê, Đỉnh Bàn Cờ', 'Green peninsula with red-shanked douc langurs, Mui Nhe trekking, Ban Co peak', 16.0736, 108.2189, 'moderate', '{"steepness": 0.6, "cardio_load": "moderate", "duration_min": 180}'::jsonb, 'Comfortable hiking clothes, closed shoes', 'Home to endangered red-shanked douc langurs. Military radar station at peak.', '[{"day": 0, "start": "06:00", "end": "09:00", "density": "low"}, {"day": 0, "start": "16:00", "end": "18:00", "density": "medium"}]'::jsonb, '{"daily": "05:00-22:00"}'::jsonb, 0),
('Mũi Nghê', 'Mui Nhe', 'sport', 'Điểm trekking hiểm trở nhất Sơn Trà, đèo dốc, view biển tuyệt đẹp', 'Most challenging trekking on Son Tra, steep slopes, stunning ocean views', 16.0847, 108.2312, 'hard', '{"steepness": 0.9, "cardio_load": "high", "duration_min": 240}'::jsonb, 'Hiking gear, closed shoes, water', 'Steep rocky terrain. Not suitable for cardiac conditions or low fitness.', '[{"day": 6, "start": "06:00", "end": "10:00", "density": "medium"}]'::jsonb, '{"daily": "05:00-18:00"}'::jsonb, 0),
('Đỉnh Bàn Cờ', 'Ban Co Peak', 'nature', 'Đỉnh cao nhất Sơn Trà, tháp radar quân sự, view toàn thành phố Đà Nẵng', 'Highest peak on Son Tra, military radar tower, panoramic city views', 16.0712, 108.2156, 'moderate', '{"steepness": 0.5, "cardio_load": "moderate", "duration_min": 120}'::jsonb, 'Comfortable clothes, light jacket', 'Former US military base. Best for sunrise/sunset photography.', '[{"day": 0, "start": "17:00", "end": "19:00", "density": "high"}]'::jsonb, '{"daily": "05:00-20:00"}'::jsonb, 0),
('Chùa Linh Ứng', 'Linh Ung Pagoda', 'culture', 'Chùa lớn nhất Đà Nẵng, phật bà Quan Âm 67m cao, view biển', 'Largest pagoda in Da Nang, 67m Lady Buddha statue, ocean views', 16.0689, 108.2198, 'easy', '{"steepness": 0.1, "cardio_load": "low", "duration_min": 60}'::jsonb, 'Modest clothing (covered shoulders/knees), remove shoes', 'Built 2004-2010. Lady Buddha faces the sea to protect fishermen. Major pilgrimage site.', '[{"day": 0, "start": "07:00", "end": "11:00", "density": "high"}, {"day": 0, "start": "15:00", "end": "17:00", "density": "medium"}]'::jsonb, '{"daily": "05:00-21:00"}'::jsonb, 0),
('Ngũ Hành Sơn', 'Marble Mountains', 'culture', 'Núi năm ngón: Kim, Mộc, Thủy, Hỏa, Thổ. Hang động, chùa cổ, làng đá Non Nước', 'Five element mountains: Metal, Wood, Water, Fire, Earth. Caves, ancient pagodas, Non Nuoc stone village', 16.0633, 108.2544, 'moderate', '{"steepness": 0.4, "cardio_load": "moderate", "duration_min": 180}'::jsonb, 'Modest clothing for pagodas, comfortable walking shoes', 'Cham Hindu-Buddhist heritage. Huyen Khong cave has natural light shafts. Stone carving village at base.', '[{"day": 0, "start": "08:00", "end": "11:00", "density": "high"}, {"day": 6, "start": "08:00", "end": "16:00", "density": "overloaded"}]'::jsonb, '{"daily": "07:00-17:30"}'::jsonb, 40000),
('Bảo tàng Điêu khắc Chăm', 'Museum of Cham Sculpture', 'culture', 'Bảo tàng lớn nhất thế giới về văn hóa Chăm Pa, hàng nghìn hiện vật', 'World largest Cham culture museum, thousands of artifacts', 16.0803, 108.2239, 'easy', '{"steepness": 0, "cardio_load": "low", "duration_min": 90}'::jsonb, 'Casual, respectful', 'Founded 1915 by French. Sandstone sculptures 7th-15th century. UNESCO memory of world.', '[{"day": 6, "start": "09:00", "end": "11:00", "density": "medium"}]'::jsonb, '{"daily": "07:30-17:00"}'::jsonb, 60000),
('Làng đá Non Nước', 'Non Nuoc Stone Village', 'culture', 'Làng nghề điêu khắc đá 400 năm, sản phẩm từ đá Ngũ Hành Sơn', '400-year stone carving village, products from Marble Mountains stone', 16.0589, 108.2522, 'easy', '{"steepness": 0, "cardio_load": "low", "duration_min": 60}'::jsonb, 'Casual', 'Traditional craft recognized as national intangible heritage. Live carving demonstrations.', '[{"day": 6, "start": "09:00", "end": "16:00", "density": "medium"}]'::jsonb, '{"daily": "08:00-17:00"}'::jsonb, 0),
('Làng chiếu Cẩm Nê', 'Cam Ne Mat Village', 'culture', 'Làng nghề dệt chiếu truyền thống 100 năm', '100-year traditional mat weaving village', 16.0456, 108.2401, 'easy', '{"steepness": 0, "cardio_load": "low", "duration_min": 45}'::jsonb, 'Casual', 'Sedge mat weaving. Products exported internationally. Hands-on weaving experience available.', '[{"day": 6, "start": "09:00", "end": "15:00", "density": "low"}]'::jsonb, '{"daily": "08:00-16:00"}'::jsonb, 0),
('Biển Mỹ Khê', 'My Khe Beach', 'sport', 'Bãi biển đẹp nhất Việt Nam, chèo SUP, lướt ván, bơi lội', 'Vietnam most beautiful beach, SUP, surfing, swimming', 16.0522, 108.2367, 'moderate', '{"steepness": 0, "cardio_load": "moderate", "duration_min": 120}'::jsonb, 'Swimwear, rash guard for water sports', 'Forbes top 6 most attractive beaches. Gentle waves good for beginners. SUP rental available.', '[{"day": 0, "start": "06:00", "end": "09:00", "density": "low"}, {"day": 0, "start": "16:00", "end": "18:00", "density": "high"}]'::jsonb, '{"daily": "24/7"}'::jsonb, 0),
('Sông Hàn', 'Han River', 'sport', 'Sông chảy qua trung tâm Đà Nẵng, chèo kayak/SUP, view Cầu Rồng phun lửa', 'River through city center, kayak/SUP, Dragon Bridge fire show view', 16.0678, 108.2201, 'moderate', '{"steepness": 0, "cardio_load": "moderate", "duration_min": 90}'::jsonb, 'Sportswear, life jacket provided', 'Best viewed from water during Dragon Bridge fire show (Sat/Sun 21:00). Night paddling popular.', '[{"day": 5, "start": "20:30", "end": "21:30", "density": "overloaded"}, {"day": 6, "start": "20:30", "end": "21:30", "density": "overloaded"}]'::jsonb, '{"daily": "05:00-22:00"}'::jsonb, 0);

-- Add 10 more: Cầu Rồng, Cầu Rồng quay, Cầu Thuận Phước, Chợ Hàn, Chợ Cồn, Phố An Thượng, Chợ Đêm Sơn Trà, Bãi biển Bãi Bụt, Suối Hoa, Vườn thú Sơn Trà.

-- 012 Test Fixtures (for 8 ground-truth cases)
-- These are referenced by automated tests

-- Note: Test fixtures require a test user. Create via Supabase Auth first, then:
-- INSERT INTO profiles (id, display_name, fitness_level) VALUES ('TEST_USER_UUID', 'Test User', 'moderate');
-- INSERT INTO health_profiles (user_id, allergen, severity, diet_rule, diet_strictness) VALUES
--   ('TEST_USER_UUID', 'peanut', 'moderate', NULL, 'strict'),
--   ('TEST_USER_UUID', NULL, NULL, 'halal', 'strict');

-- Verify with: SELECT * FROM dishes WHERE name_vi = 'Bún chả cá' AND dietary_verdict->>'halal' = 'false';

-- ============================================================
-- Verification Queries (run after seed to confirm)
-- ============================================================

-- 1. Check dishes allergen flags
-- SELECT name_vi, allergen_flags, dietary_verdict FROM dishes WHERE name_vi IN ('Bún chả cá', 'Mì Quảng', 'Bánh xèo', 'Bánh xèo chay');

-- 2. Check attractions difficulty
-- SELECT name_vi, difficulty, physical_requirements FROM attractions WHERE name_vi IN ('Mũi Nghê', 'Biển Mỹ Khê');

-- 3. Test Case 1: Halal user + Bún chả cá
-- Expected: dietary_verdict.halal = false, contains_pork = true
-- SELECT dietary_verdict->>'halal' as halal, contains_pork FROM dishes WHERE name_vi = 'Bún chả cá';

-- 4. Test Case 2: Cardiac + Mũi Nghê
-- Expected: difficulty = 'hard', physical_requirements.cardio_load = 'high'
-- SELECT difficulty, physical_requirements->>'cardio_load' as cardio FROM attractions WHERE name_vi = 'Mũi Nghê';

-- 5. Test Case 3: Peanut allergy + Mì Quảng
-- Expected: allergen_flags.peanut = true
-- SELECT allergen_flags->>'peanut' as peanut FROM dishes WHERE name_vi = 'Mì Quảng';

-- 6. Test Case 4: Vegetarian + Bánh xèo chay
-- Expected: dietary_verdict.vegetarian = true
-- SELECT dietary_verdict->>'vegetarian' as vegetarian FROM dishes WHERE name_vi = 'Bánh xèo chay';

-- 7. Test Case 5: Crowd at Dragon Bridge -> reroute
-- Check crowd_reports for attraction 'Cầu Rồng' with density = 'overloaded'

-- 8. Test Case 8: Ram ambiguous
-- Expected: confidence_score < 0.7, requires_kitchen_confirmation = true
-- SELECT confidence_score, requires_kitchen_confirmation FROM dishes WHERE name_vi = 'Ram';

-- ============================================================
-- End of Schema
-- ============================================================