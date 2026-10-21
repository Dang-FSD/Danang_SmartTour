# DaNang SmartTour AI — Agent Instructions

## Project Overview
Smart tourism companion app for Da Nang, Vietnam. Core value: **Dual-Layer Protection** — personal health/faith safety + cultural discovery + dynamic crowd routing. Targets 3 SDGs: 11 (sustainable cities), 8 (local economy), 10 (inclusive access).

## Planned Tech Stack (from design doc)
| Layer | Choice | Rationale |
|-------|--------|-----------|
| **Frontend** | Flutter (iOS/Android) | Camera scanner, map, chat UI in one codebase |
| **AI Vision/Reasoning** | Gemini API (Free Tier) + Tesseract/PaddleOCR pre-processing | Multimodal food/menu analysis, cultural storytelling; OCR cuts vision tokens ~80% |
| **Maps/GIS** | OpenStreetMap + Leaflet (no Google Maps fees) | Free tile rendering; turn-by-turn via universal deep-link to device default maps app |
| **Backend/DB** | Supabase Free Tier (PostgreSQL + Auth + Storage) | Traveler profiles, allergen/health flags, 40 Da Nang dishes + 20 attractions, low latency |
| **Local Data** | SQLite/JSON (bundled) | 40 dishes with hidden ingredients, 20 cultural/sport POIs — works offline |

## Key Architectural Decisions
- **No Google Maps Platform** — avoid per-call fees; deep-link to Apple/Google Maps for navigation
- **No paid serverless** — Supabase free tier covers auth, DB, storage
- **Agent tools (must implement)**: `get_traveler_profile`, `fetch_danang_attractions`, `check_route_crowd_and_safety`, `generate_adaptive_itinerary`, `save_itinerary_ticket`, `verify_itinerary_status`, `launch_navigation_deeplink`, `create_custom_safe_itinerary`, `re_route_and_dispatch_alert`, `generate_chef_dietary_ticket`
- **Safety boundaries**: Agent NEVER auto-approves high-risk (anaphylaxis history, severe cardiac) for trekking/shared-oil foods; NEVER processes payments; NEVER shares raw health data with third parties
- **Verification required**: After `save_itinerary_ticket` or `generate_chef_dietary_ticket`, MUST call `verify_itinerary_status(ticket_id)` to confirm safety flags persisted

## Test Cases (Ground Truth — 8 Binary Cases)
1. Halal user + Bún chả cá (pork broth) → **RED** (violation)
2. Cardiac history + Mũi Nghê trekking → **RED** (unsafe), suggest Voọc walking trail
3. Peanut allergy + Mì Quảng gà → **YELLOW**, trigger "no peanuts" chef ticket
4. Vegetarian + Bánh xèo nấm → **GREEN**
5. Dragon Bridge overloaded at fire-breathing hour → auto reroute to Non Nuoc Stone Village
6. Network error on ticket write → rollback + verification failure notice
7. Fit user + SUP My Khe → **GREEN**
8. Ambiguous Ram (corn soup) ingredients → require kitchen staff confirmation

**Success metrics**: ≥95% hidden allergen/health risk recall; 100% verified safety rate (zero false-safe)

## Development Phases
1. **Short-term**: AI Vision integration, beta with international tourists & dietary-restricted users
2. **Mid-term**: B2B2C dashboard for local businesses (restaurants, craft villages, tour operators) to push verified data (Halal/Vegan certs, trail difficulty)
3. **Long-term**: AR navigation in night markets/alleys; expand to Hoi An, Hue, internationally

## Getting Started
```bash
# Di chuyển vào thư mục Frontend
cd FE

# Lấy thư viện và chạy ứng dụng
flutter pub get
flutter run
```
Supabase project schema đã có tại `BE/DB/Danang_SmartTour_DB.sql`.

## References
- Full spec: `Documment_Project/extracted_content.txt`
- Original docx: `Documment_Project/DaNang SmartTour AI.docx`