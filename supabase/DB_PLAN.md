# DaNang SmartTour — Database Design Plan

## Overview
PostgreSQL on Supabase (Free Tier). Uses RLS for data isolation, JSONB for flexible structured data, PostGIS optional for geo queries.

---

## Extensions
```sql
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
-- CREATE EXTENSION IF NOT EXISTS postgis; -- optional, use lat/lng floats for simplicity
```

---

## Enums
```sql
CREATE TYPE safety_level AS ENUM ('RED', 'YELLOW', 'GREEN');
CREATE TYPE allergen_code AS ENUM ('peanut', 'seafood', 'fish', 'shellfish', 'pork', 'beef', 'gluten', 'dairy', 'egg', 'soy', 'nuts', 'sesame');
CREATE TYPE diet_rule AS ENUM ('halal', 'kosher', 'vegetarian', 'vegan', 'pescatarian');
CREATE TYPE fitness_level AS ENUM ('low', 'moderate', 'high');
CREATE TYPE trip_purpose AS ENUM ('culture', 'sport', 'food', 'mixed');
CREATE TYPE attraction_category AS ENUM ('culture', 'sport', 'food', 'nature');
CREATE TYPE difficulty AS ENUM ('easy', 'moderate', 'hard');
CREATE TYPE density AS ENUM ('low', 'medium', 'high', 'overloaded');
CREATE TYPE itinerary_status AS ENUM ('draft', 'saved', 'verified', 'active', 'completed', 'failed');
```

---

## Tables

### 1. profiles (1:1 with auth.users)
```sql
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name TEXT,
  preferred_language TEXT DEFAULT 'en',
  nationality TEXT,
  fitness_level fitness_level DEFAULT 'moderate',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
-- RLS: user sees/edits only own row
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "own_profile" ON profiles USING (auth.uid() = id) WITH CHECK (auth.uid() = id);
```

### 2. health_profiles (normalized for severity-aware logic)
```sql
CREATE TABLE health_profiles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  -- Allergies with severity
  allergen allergen_code NOT NULL,
  severity TEXT NOT NULL CHECK (severity IN ('mild', 'moderate', 'severe', 'anaphylaxis')),
  -- Medical conditions
  condition_code TEXT, -- e.g. 'cardiac', 'asthma', 'diabetes', 'pregnancy'
  condition_severity TEXT CHECK (condition_severity IN ('mild', 'moderate', 'severe')),
  -- Dietary rules
  diet_rule diet_rule,
  diet_strictness TEXT CHECK (diet_strictness IN ('strict', 'moderate', 'flexible')) DEFAULT 'strict',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (user_id, allergen),
  UNIQUE (user_id, condition_code),
  UNIQUE (user_id, diet_rule)
);
ALTER TABLE health_profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "own_health" ON health_profiles USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
```

### 3. dishes (40 Da Nang dishes — reference data, public read)
```sql
CREATE TABLE dishes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name_vi TEXT NOT NULL,
  name_en TEXT NOT NULL,
  description_vi TEXT,
  description_en TEXT,
  -- Structured hidden ingredients
  hidden_ingredients JSONB DEFAULT '[]'::jsonb,
  -- Allergen flags (auto-computed from hidden_ingredients or manual)
  allergen_flags JSONB DEFAULT '{}'::jsonb, -- {"peanut": true, "fish": true, "pork": false, ...}
  -- Dietary verdict (boolean per rule)
  dietary_verdict JSONB DEFAULT '{}'::jsonb, -- {"halal": false, "vegetarian": true, ...}
  contains_pork BOOLEAN DEFAULT FALSE,
  contains_alcohol BOOLEAN DEFAULT FALSE,
  spice_level INTEGER CHECK (spice_level BETWEEN 0 AND 5) DEFAULT 0,
  price_range TEXT, -- e.g. "30k-50k VND"
  image_url TEXT,
  confidence_score FLOAT DEFAULT 1.0, -- for ambiguous dishes (Case 8)
  requires_kitchen_confirmation BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
-- Public read, admin write
ALTER TABLE dishes ENABLE ROW LEVEL SECURITY;
CREATE POLICY "public_read_dishes" ON dishes FOR SELECT USING (true);
-- Index for allergen filtering
CREATE INDEX idx_dishes_allergen_flags ON dishes USING GIN (allergen_flags);
CREATE INDEX idx_dishes_dietary_verdict ON dishes USING GIN (dietary_verdict);
```

### 4. attractions (20 POIs — reference data, public read)
```sql
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
  physical_requirements JSONB DEFAULT '{}'::jsonb, -- {"steepness": 0.8, "cardio_load": "high", "duration_min": 120}
  dress_code TEXT,
  cultural_notes TEXT,
  typical_crowd_hours JSONB DEFAULT '[]'::jsonb, -- [{"day": 0-6, "start": "18:00", "end": "20:00", "density": "high"}, ...]
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
```

### 5. itineraries (user trip plans)
```sql
CREATE TABLE itineraries (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  purpose trip_purpose NOT NULL,
  status itinerary_status DEFAULT 'draft',
  start_date DATE,
  end_date DATE,
  budget_vnd BIGINT,
  -- Aggregated safety flags for quick overview
  safety_flags JSONB DEFAULT '{}'::jsonb, -- {"allergy_peanut": true, "cardiac_risk": false, ...}
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE itineraries ENABLE ROW LEVEL SECURITY;
CREATE POLICY "own_itinerary" ON itineraries USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE INDEX idx_itineraries_user ON itineraries (user_id);
```

### 6. itinerary_stops (ordered stops in a trip)
```sql
CREATE TABLE itinerary_stops (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  itinerary_id UUID NOT NULL REFERENCES itineraries(id) ON DELETE CASCADE,
  attraction_id UUID REFERENCES attractions(id) ON DELETE SET NULL,
  dish_id UUID REFERENCES dishes(id) ON DELETE SET NULL,
  order_index INTEGER NOT NULL,
  scheduled_time TIMESTAMPTZ,
  -- Per-stop safety evaluation
  safety_level safety_level NOT NULL,
  safety_reasons JSONB DEFAULT '[]'::jsonb, -- [{"type": "allergen", "code": "peanut"}, {"type": "cardiac", "attraction": "Mui Nhe"}]
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (itinerary_id, order_index)
);
ALTER TABLE itinerary_stops ENABLE ROW LEVEL SECURITY;
CREATE POLICY "own_stops" ON itinerary_stops
  USING (EXISTS (SELECT 1 FROM itineraries i WHERE i.id = itinerary_stops.itinerary_id AND i.user_id = auth.uid()))
  WITH CHECK (EXISTS (SELECT 1 FROM itineraries i WHERE i.id = itinerary_stops.itinerary_id AND i.user_id = auth.uid()));
CREATE INDEX idx_itinerary_stops_itinerary ON itinerary_stops (itinerary_id);
```

### 7. safety_tickets (chef dietary ticket / allergy warning)
```sql
CREATE TABLE safety_tickets (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  itinerary_id UUID REFERENCES itineraries(id) ON DELETE SET NULL,
  dish_id UUID REFERENCES dishes(id) ON DELETE SET NULL,
  ticket_code TEXT UNIQUE NOT NULL, -- e.g. "DST-HALAL-7X9K2M"
  allergy_flags JSONB NOT NULL, -- {"peanut": true, "fish": true}
  health_warnings JSONB DEFAULT '[]'::jsonb, -- [{"type": "cardiac", "message": "Avoid steep trekking"}]
  safety_level safety_level NOT NULL,
  bilingual_text JSONB NOT NULL, -- {"vi": "Không đậu phộng...", "en": "No peanuts..."}
  verified BOOLEAN DEFAULT FALSE,
  verified_at TIMESTAMPTZ,
  expires_at TIMESTAMPTZ, -- valid for single meal/day
  created_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE safety_tickets ENABLE ROW LEVEL SECURITY;
CREATE POLICY "own_tickets" ON safety_tickets USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE INDEX idx_safety_tickets_user ON safety_tickets (user_id);
CREATE INDEX idx_safety_tickets_code ON safety_tickets (ticket_code);
```

### 8. crowd_reports (real-time density for dynamic routing)
```sql
CREATE TABLE crowd_reports (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  attraction_id UUID NOT NULL REFERENCES attractions(id) ON DELETE CASCADE,
  reporter_id UUID REFERENCES profiles(id) ON DELETE SET NULL, -- null = simulated/system
  reported_at TIMESTAMPTZ DEFAULT NOW(),
  density density NOT NULL,
  source TEXT CHECK (source IN ('user', 'simulated', 'sensor')) DEFAULT 'simulated',
  traffic_note TEXT,
  lat DOUBLE PRECISION,
  lng DOUBLE PRECISION,
  -- TTL: auto-expire old reports
  expires_at TIMESTAMPTZ GENERATED ALWAYS AS (reported_at + INTERVAL '2 hours') STORED
);
ALTER TABLE crowd_reports ENABLE ROW LEVEL SECURITY;
CREATE POLICY "public_read_crowd" ON crowd_reports FOR SELECT USING (true);
CREATE POLICY "insert_own_crowd" ON crowd_reports FOR INSERT WITH CHECK (auth.uid() = reporter_id OR reporter_id IS NULL);
CREATE INDEX idx_crowd_reports_attraction ON crowd_reports (attraction_id);
CREATE INDEX idx_crowd_reports_reported_at ON crowd_reports (reported_at);
```

### 9. reroute_events (audit trail for dynamic routing)
```sql
CREATE TABLE reroute_events (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  itinerary_id UUID REFERENCES itineraries(id) ON DELETE SET NULL,
  from_attraction_id UUID REFERENCES attractions(id) ON DELETE SET NULL,
  to_attraction_id UUID REFERENCES attractions(id) ON DELETE SET NULL,
  reason TEXT NOT NULL, -- "overcrowded", "safety", "weather", "user_preference"
  created_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE reroute_events ENABLE ROW LEVEL SECURITY;
CREATE POLICY "own_reroutes" ON reroute_events USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
```

### 10. agent_logs (traceability for tool calls — optional but recommended)
```sql
CREATE TABLE agent_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  tool_name TEXT NOT NULL, -- e.g. "generate_adaptive_itinerary", "verify_itinerary_status"
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
```

---

## Ground-Truth Test Data (8 Cases)

Seed these as fixtures for automated testing:

| Case | User Profile | Input | Expected |
|------|--------------|-------|----------|
| 1 | halal | Bún chả cá (pork broth) | dish.dietary_verdict.halal=false → RED |
| 2 | cardiac | Mũi Nghê trekking | attraction.difficulty=hard + physical_requirements.cardio_load=high → RED |
| 3 | peanut allergy | Mì Quảng gà | dish.allergen_flags.peanut=true → YELLOW + chef ticket |
| 4 | vegetarian | Bánh xèo nấm | dish.dietary_verdict.vegetarian=true → GREEN |
| 5 | — | Dragon Bridge overloaded | crowd_reports.density=overloaded → reroute to Non Nuoc |
| 6 | — | Network error on ticket write | safety_tickets.verified=false, itinerary status=failed |
| 7 | fit | SUP Mỹ Khê | attraction.difficulty=moderate, user fitness=high → GREEN |
| 8 | — | Ram (ambiguous) | dish.confidence_score < 0.7, requires_kitchen_confirmation=true |

---

## Migration Order
1. `001_extensions.sql` — uuid-ossp, (postgis)
2. `002_enums.sql` — all CREATE TYPE
3. `003_profiles.sql` — profiles + health_profiles
4. `004_reference_data.sql` — dishes, attractions
5. `005_itineraries.sql` — itineraries, itinerary_stops
6. `006_safety_tickets.sql` — safety_tickets
7. `007_crowd_routing.sql` — crowd_reports, reroute_events
8. `008_agent_logs.sql` — agent_logs
9. `009_rls_policies.sql` — all policies
10. `010_seed_dishes.sql` — 40 dishes
11. `011_seed_attractions.sql` — 20 POIs
12. `012_test_fixtures.sql` — 8 ground-truth cases

---

## Seed Data Notes
- **40 dishes**: from `Documment_Project/extracted_content.txt` + local research (Mì Quảng, Bún chả cá, Bánh xèo, Bánh tráng cuốn, Bánh canh, Ram, etc.)
- **20 attractions**: Sơn Trà (Mũi Nghê, Đỉnh Bàn Cờ, Chùa Linh Ứng), Ngũ Hành Sơn, Bảo tàng Chăm, Làng đá Non Nước, Làng chiếu Cẩm Nê, Biển Mỹ Khê (SUP), Sông Hàn, Cầu Rồng, Chợ Hàn, Chợ Cồn, Phố An Thượng, etc.

---

## VokeAI Prompt Integration Points
| Table | AI Use |
|-------|--------|
| dishes.hidden_ingredients | OCR + VokeAI extracts → populate JSONB |
| dishes.allergen_flags | VokeAI classifies from ingredients |
| dishes.dietary_verdict | VokeAI evaluates per diet_rule |
| attractions.cultural_notes | VokeAI generates storytelling from image/text |
| itineraries.safety_flags | Aggregated from stops via VokeAI reasoning |
| safety_tickets.bilingual_text | VokeAI translates to user language |

---

## Next Steps
1. Create Supabase project → get URL + anon key
2. Run migrations 1-9 via Supabase CLI or dashboard
3. Seed dishes/attractions (migrations 10-11)
4. Write test fixtures (migration 12)
5. Verify 8 ground-truth cases pass with VokeAPI integration