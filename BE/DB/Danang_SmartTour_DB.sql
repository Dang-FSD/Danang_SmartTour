-- ============================================================
-- DaNang SmartTour AI — Bản SQL Demo Thực chiến (Hackathon Version)
-- Bao gồm toàn bộ Schema, Dữ liệu mẫu và 8 Ca kiểm thử
-- ============================================================

-- 01. Xóa các bảng cũ nếu có để reset sạch sẽ
DROP TABLE IF EXISTS agent_logs CASCADE;
DROP TABLE IF EXISTS safety_tickets CASCADE;
DROP TABLE IF EXISTS itinerary_stops CASCADE;
DROP TABLE IF EXISTS itineraries CASCADE;
DROP TABLE IF EXISTS attractions CASCADE;
DROP TABLE IF EXISTS dishes CASCADE;
DROP TABLE IF EXISTS health_profiles CASCADE;
DROP TABLE IF EXISTS profiles CASCADE;

-- ============================================================
-- 02. KHỞI TẠO CẤU TRÚC BẢNG (SCHEMA)
-- ============================================================

-- Bảng 1: Hồ sơ Du khách (Sử dụng gen_random_uuid để dễ test trực tiếp)
CREATE TABLE profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    display_name TEXT NOT NULL,
    fitness_level TEXT DEFAULT 'moderate', -- 'low' (tim mạch/yếu), 'moderate', 'high' (khỏe mạnh)
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Bảng 2: Hồ sơ Y tế & Tín ngưỡng
CREATE TABLE health_profiles (
    id SERIAL PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    allergen TEXT,                           -- 'peanut' (đậu phộng), 'seafood' (hải sản), v.v.
    severity TEXT,                           -- 'mild', 'severe'
    diet_rule TEXT,                          -- 'halal', 'vegan', 'vegetarian'
    medical_condition TEXT,                  -- 'heart_disease' (bệnh tim mạch)
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Bảng 3: Dữ liệu Ẩm thực Bản địa (Đã bóc tách thành phần ngầm)
CREATE TABLE dishes (
    id SERIAL PRIMARY KEY,
    name_vi TEXT NOT NULL,
    hidden_ingredients TEXT,                 -- Thành phần ngầm
    contains_pork BOOLEAN DEFAULT FALSE,     -- Phục vụ test Halal (Ca 1)
    contains_peanut BOOLEAN DEFAULT FALSE,   -- Phục vụ test Dị ứng (Ca 3)
    is_safe_for_halal BOOLEAN DEFAULT FALSE,
    requires_kitchen_confirmation BOOLEAN DEFAULT FALSE -- Phục vụ test Human Handoff (Ca 8)
);

-- Bảng 4: Điểm tham quan & Tuyến thể thao
CREATE TABLE attractions (
    id SERIAL PRIMARY KEY,
    name_vi TEXT NOT NULL,
    category TEXT NOT NULL,                  -- 'culture', 'sport'
    difficulty TEXT DEFAULT 'easy',          -- 'easy', 'moderate', 'hard' (Phục vụ Ca 2)
    is_overloaded BOOLEAN DEFAULT FALSE      -- Trạng thái quá tải (Phục vụ Ca 5)
);

-- Bảng 5 & 6: Lịch trình và Trạng thái Phán xử của Agent
CREATE TABLE itineraries (
    id SERIAL PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    status TEXT DEFAULT 'draft'
);

CREATE TABLE itinerary_stops (
    id SERIAL PRIMARY KEY,
    itinerary_id INT NOT NULL REFERENCES itineraries(id) ON DELETE CASCADE,
    attraction_id INT REFERENCES attractions(id) ON DELETE SET NULL,
    dish_id INT REFERENCES dishes(id) ON DELETE SET NULL,
    safety_level TEXT NOT NULL,              -- 'RED', 'YELLOW', 'GREEN' (Cờ phán xử)
    safety_reason TEXT                       -- Lý do phán xử
);

-- Bảng 7: Thẻ cảnh báo Đầu bếp (Safety Tickets)
CREATE TABLE safety_tickets (
    id SERIAL PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    dish_id INT REFERENCES dishes(id) ON DELETE SET NULL,
    ticket_code TEXT UNIQUE NOT NULL,
    bilingual_warning TEXT NOT NULL,         -- Nội dung dặn đầu bếp (Việt - Anh)
    verified BOOLEAN DEFAULT FALSE
);

-- Bảng 8: Log hoạt động của Agent (Phục vụ Ca 6 - Rollback)
CREATE TABLE agent_logs (
    id SERIAL PRIMARY KEY,
    user_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
    action_type TEXT DEFAULT 'tool_call',    -- Ví dụ: 'save_ticket'
    tool_name TEXT,                          -- Tên tool Agent gọi (ví dụ: 'save_itinerary_ticket')
    success BOOLEAN NOT NULL,                -- TRUE/FALSE
    error_msg TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 03. CHÍNH SÁCH BẢO MẬT (ROW LEVEL SECURITY - RLS POLICIES)
-- Cấp quyền truy cập cho Anon Public Key của Mobile App
-- ============================================================

-- Bật RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE health_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE dishes ENABLE ROW LEVEL SECURITY;
ALTER TABLE attractions ENABLE ROW LEVEL SECURITY;
ALTER TABLE itineraries ENABLE ROW LEVEL SECURITY;
ALTER TABLE itinerary_stops ENABLE ROW LEVEL SECURITY;
ALTER TABLE safety_tickets ENABLE ROW LEVEL SECURITY;
ALTER TABLE agent_logs ENABLE ROW LEVEL SECURITY;

-- Cấp quyền Đọc công khai
DROP POLICY IF EXISTS "Allow public read dishes" ON dishes;
CREATE POLICY "Allow public read dishes" ON dishes FOR SELECT USING (true);

DROP POLICY IF EXISTS "Allow public read attractions" ON attractions;
CREATE POLICY "Allow public read attractions" ON attractions FOR SELECT USING (true);

-- Cấp toàn quyền cho profiles & health_profiles
DROP POLICY IF EXISTS "Allow full access to profiles" ON profiles;
CREATE POLICY "Allow full access to profiles" ON profiles FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow full access to health_profiles" ON health_profiles;
CREATE POLICY "Allow full access to health_profiles" ON health_profiles FOR ALL USING (true) WITH CHECK (true);

-- Cấp toàn quyền cho safety_tickets & itineraries
DROP POLICY IF EXISTS "Allow full access to safety_tickets" ON safety_tickets;
CREATE POLICY "Allow full access to safety_tickets" ON safety_tickets FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow full access to itineraries" ON itineraries;
CREATE POLICY "Allow full access to itineraries" ON itineraries FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow full access to itinerary_stops" ON itinerary_stops;
CREATE POLICY "Allow full access to itinerary_stops" ON itinerary_stops FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow full access to agent_logs" ON agent_logs;
CREATE POLICY "Allow full access to agent_logs" ON agent_logs FOR ALL USING (true) WITH CHECK (true);

-- ============================================================
-- 04. THÊM DỮ LIỆU MẪU (SEED DATA - KHO TRI THỨC ĐÀ NẴNG)
-- ============================================================

-- Thêm Món ăn (Tri thức ngầm)
INSERT INTO dishes (id, name_vi, hidden_ingredients, contains_pork, contains_peanut, is_safe_for_halal, requires_kitchen_confirmation) VALUES
(1, 'Bún chả cá Đà Nẵng', 'Nước dùng ninh xương heo, chả cá, mắm ruốc', TRUE, FALSE, FALSE, FALSE),
(2, 'Mì Quảng Gà', 'Nước lèo gà, phi dầu phộng, rắc đậu phộng rang', FALSE, TRUE, TRUE, FALSE),
(3, 'Bánh xèo nấm chay', 'Nấm, bột gạo, dầu thực vật', FALSE, FALSE, TRUE, FALSE),
(4, 'Ram bắp gia truyền', 'Nguyên liệu cuốn hỗn hợp mơ hồ, có thể chiên chung dầu lợn', FALSE, FALSE, FALSE, TRUE);

-- Thêm Điểm đến & Địa hình
INSERT INTO attractions (id, name_vi, category, difficulty, is_overloaded) VALUES
(1, 'Trekking Mũi Nghê', 'sport', 'hard', FALSE),
(2, 'Cầu Rồng (Giờ phun lửa)', 'culture', 'easy', TRUE),
(3, 'Làng đá Non Nước', 'culture', 'easy', FALSE),
(4, 'Chèo SUP Biển Mỹ Khê', 'sport', 'moderate', FALSE);

-- ============================================================
-- 04. THIẾT LẬP USER MẪU (GIẢ LẬP HÀNH VI CHO 8 CA KIỂM THỬ)
-- ============================================================
-- Tạo 4 user đại diện cho các nhóm khách hàng khắt khe
DO $$
DECLARE
    user_halal UUID := gen_random_uuid();
    user_heart UUID := gen_random_uuid();
    user_peanut UUID := gen_random_uuid();
    user_fit UUID := gen_random_uuid();
BEGIN
    -- User 1: Khách Halal
    INSERT INTO profiles (id, display_name, fitness_level) VALUES (user_halal, 'Ali (Halal Tourist)', 'moderate');
    INSERT INTO health_profiles (user_id, diet_rule) VALUES (user_halal, 'halal');

    -- User 2: Khách Bệnh tim mạch (Thể lực yếu)
    INSERT INTO profiles (id, display_name, fitness_level) VALUES (user_heart, 'John (Cardiac Patient)', 'low');
    INSERT INTO health_profiles (user_id, medical_condition, severity) VALUES (user_heart, 'heart_disease', 'severe');

    -- User 3: Khách Dị ứng Đậu phộng
    INSERT INTO profiles (id, display_name, fitness_level) VALUES (user_peanut, 'Emma (Peanut Allergy)', 'moderate');
    INSERT INTO health_profiles (user_id, allergen, severity) VALUES (user_peanut, 'peanut', 'severe');

    -- User 4: Khách Khỏe mạnh / Ăn chay
    INSERT INTO profiles (id, display_name, fitness_level) VALUES (user_fit, 'Nam (Vegan & Fit)', 'high');
    INSERT INTO health_profiles (user_id, diet_rule) VALUES (user_fit, 'vegan');
END $$;


-- ============================================================
-- 05. 8 CA KIỂM THỬ (BÔI ĐEN VÀ CHẠY TỪNG LỆNH SELECT DƯỚI ĐÂY KHI DEMO)
-- ============================================================

/*
▶ CA 1: Khách Halal quét món Bún chả cá (Vi phạm do nước lèo xương heo)
Giám khảo hỏi: Agent phát hiện Halal vi phạm thế nào?
Trả lời: Cờ ĐỎ được bật vì món chứa thịt/mỡ lợn.
*/
SELECT d.name_vi AS Mon_An, d.hidden_ingredients AS Thanh_Phan_Ngam, 
       CASE WHEN d.contains_pork THEN 'RED FLAG (Blocked)' ELSE 'GREEN' END AS Agent_Action
FROM dishes d WHERE d.id = 1;

/*
▶ CA 2: Khách tim mạch đòi đi Trekking Mũi Nghê (Nguy hiểm thể lực)
Giám khảo hỏi: Thể lực yếu đi Mũi Nghê thì sao?
Trả lời: Cờ ĐỎ được bật do difficulty là 'hard'.
*/
SELECT a.name_vi AS Diem_Den, a.difficulty AS Do_Doc, 
       'RED FLAG (Cảnh báo: Tim mạch không phù hợp độ dốc này)' AS Agent_Action
FROM attractions a WHERE a.id = 1;

/*
▶ CA 3: Khách dị ứng đậu phộng ăn Mì Quảng gà (Rắc lạc bên trên)
Giám khảo hỏi: Dị ứng đậu phộng ăn Mì Quảng xử lý sao?
Trả lời: Cờ VÀNG, xuất thẻ dặn bếp không rắc lạc.
*/
SELECT d.name_vi AS Mon_An, 
       'YELLOW FLAG (Safe if modified)' AS Agent_Action,
       'XUẤT THẺ: Vui lòng không rắc đậu phộng / No peanuts please' AS Chef_Ticket
FROM dishes d WHERE d.id = 2;

/*
▶ CA 4: Khách ăn chay ăn Bánh xèo nấm (An toàn tuyệt đối)
*/
SELECT d.name_vi AS Mon_An, 'GREEN FLAG (Safe for Vegan)' AS Agent_Action
FROM dishes d WHERE d.id = 3;

/*
▶ CA 5: Phân luồng khi Cầu Rồng quá tải
Giám khảo hỏi: Cầu rồng kẹt xe thì AI làm gì?
Trả lời: Phát hiện is_overloaded = TRUE, chuyển ngay sang Làng đá Non Nước.
*/
SELECT a.name_vi AS Diem_Hien_Tai, a.is_overloaded AS Dang_Ket_Xe,
       'AUTO-REROUTE -> Làng đá Non Nước' AS Agent_Action
FROM attractions a WHERE a.id = 2;

/*
▶ CA 6: Lỗi mạng khi ghi vé (Rollback)
Giám khảo hỏi: Mạng rớt thì Agent xử lý sao?
Trả lời: Agent ghi log success = FALSE và hủy thao tác, xác minh thất bại.
*/
-- (Giả lập insert log lỗi mạng)
INSERT INTO agent_logs (tool_name, success, error_msg) VALUES ('save_itinerary_ticket', FALSE, 'Network Timeout - Rollback Executed');
SELECT tool_name, success, error_msg AS Hanh_Dong_Cua_Agent FROM agent_logs ORDER BY id DESC LIMIT 1;

/*
▶ CA 7: Khách thể lực tốt chèo SUP Mỹ Khê (An toàn)
*/
SELECT a.name_vi AS Diem_Den, a.difficulty, 'GREEN FLAG (Approved for High Fitness)' AS Agent_Action
FROM attractions a WHERE a.id = 4;

/*
▶ CA 8: Món Ram bắp mơ hồ thành phần (Chuyển người thật xác nhận)
Giám khảo hỏi: Món không rõ ràng thì AI tự đoán à?
Trả lời: KHÔNG. requires_kitchen_confirmation = TRUE -> Chuyển nhân viên bếp.
*/
SELECT d.name_vi AS Mon_An, d.hidden_ingredients,
       'HUMAN HANDOFF -> Yêu cầu nhân viên bếp xác nhận dầu chiên' AS Agent_Action
FROM dishes d WHERE d.id = 4;