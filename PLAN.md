# DaNang SmartTour AI — Implementation Plan

## 1. Project Structure (Monorepo Flutter + Supabase)

```
DaNang_SmartTour/
├── lib/                          # Flutter App (FE)
│   ├── core/                     # Shared kernel
│   │   ├── config/               # Env, constants, supabase client
│   │   ├── errors/               # Failures, exceptions
│   │   ├── utils/                # Helpers, extensions
│   │   └── ai/                   # VokeAI client wrapper
│   ├── data/                     # Data layer
│   │   ├── models/               # DTOs (TravelerProfile, Dish, Attraction, Itinerary, SafetyTicket)
│   │   ├── repositories/         # Repository impls
│   │   ├── datasources/          # Remote (Supabase) + Local (SQLite/JSON)
│   │   └── services/             # Maps, Navigation, OCR, Camera
│   ├── domain/                   # Business logic (clean architecture)
│   │   ├── entities/             # Core entities
│   │   ├── repositories/         # Repository contracts
│   │   ├── usecases/             # 10 Agent tools as usecases
│   │   └── ai/                   # AI prompts, parsers, validators
│   ├── presentation/             # UI layer
│   │   ├── pages/                # Screens
│   │   ├── widgets/              # Reusable components
│   │   ├── providers/            # Riverpod/Bloc state
│   │   └── routes/               # GoRouter config
│   └── main.dart
├── supabase/                     # BE (Supabase)
│   ├── migrations/               # SQL migrations
│   ├── functions/                # Edge Functions (Deno) - optional for heavy AI
│   └── seed/                     # Seed data (40 dishes, 20 POIs)
├── assets/
│   ├── data/                     # Local JSON/SQLite fallback
│   └── images/
├── test/                         # Unit + Widget + Integration tests
├── PLAN.md                       # This file
├── AGENTS.md                     # Agent instructions
└── pubspec.yaml
```

**State Management**: Riverpod (compile-safe, testable)
**Routing**: GoRouter (deep-link ready)
**DI**: Riverpod providers / get_it

---

## 2. FE / BE Responsibility Split

| Layer | Responsibility | Tech |
|-------|---------------|------|
| **FE (Flutter)** | UI, Camera scanner, Map rendering (OSM/Leaflet via WebView or flutter_map), Offline cache, User session, Agent orchestration (calling 10 tools sequentially) | Flutter, Riverpod, flutter_map, camera, image_picker, tflite_flutter (optional for on-device OCR) |
| **BE (Supabase)** | Auth (email/phone), PostgreSQL DB (profiles, dishes, attractions, itineraries, safety_tickets), Storage (menu photos), Realtime (crowd updates), RLS policies | Supabase (PostgreSQL + Auth + Realtime + Storage) |
| **AI (VokeAPI)** | **All LLM reasoning**: Food analysis, Cultural storytelling, Itinerary generation, Crowd routing logic, Safety validation | VokeAPI (Gemini-compatible) via custom client |
| **Edge Functions (optional)** | Heavy preprocessing: OCR pipeline, Image compression, Batch safety checks | Deno on Supabase Edge Functions |

**Rule**: FE calls VokeAPI directly for latency-critical paths (scanner). BE only for auth/data/RLS. Edge Functions only if token limits / cost demand it.

---

## 3. VokeAPI Key Management

```
lib/core/config/
├── env.dart              # compile-time constants (non-secret)
└── secrets.dart          # gitignored, runtime injection
```

**`secrets.dart` (gitignored)**:
```dart
const String vokeApiKey = String.fromEnvironment('VOKE_API_KEY');
const String vokeBaseUrl = String.fromEnvironment('VOKE_BASE_URL', defaultValue: 'https://api.voke.ai/v1');
const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
```

**Injection at build/run**:
```bash
# Local dev
flutter run --dart-define=VOKE_API_KEY=sk-xxx --dart-define=VOKE_BASE_URL=https://api.voke.ai/v1 --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...

# CI/CD: GitHub Secrets → --dart-define
```

**Never commit keys**. `.gitignore` includes `lib/core/config/secrets.dart`.

---

## 4. AI Workflow — Which Part Uses VokeAPI

### 4.1 VokeAPI Used For (LLM Reasoning)

| Feature | VokeAPI Role | Prompt Type |
|---------|--------------|-------------|
| **Food Scanner** | Analyze OCR text + image → hidden ingredients, allergen flags, Halal/Vegan verdict, chef ticket | Structured output (JSON schema) |
| **Cultural Storytelling** | Monument/image → history, dress code, etiquette in user language | Few-shot + RAG (local knowledge base) |
| **Itinerary Planner** | Profile + attractions + crowd + weather → adaptive route with alternatives | Chain-of-thought + function calling (tools) |
| **Crowd Routing** | Real-time density + user constraints → reroute decision | Lightweight classification |
| **Safety Validation** | Verify ticket flags persisted correctly | Deterministic check (no LLM needed) |

### 4.2 NOT VokeAPI (Deterministic / Local)

| Feature | Implementation |
|---------|----------------|
| OCR text extraction | Tesseract / PaddleOCR (on-device or Edge Function) |
| Map rendering & routing | OSM + flutter_map / leaflet (no LLM) |
| Deep-link navigation | `url_launcher` to `google.navigation:` / `maps://` |
| DB CRUD, Auth, Realtime | Supabase client |
| Safety flag verification | SQL query + Dart logic (zero LLM) |
| Local data fallback | SQLite/JSON bundle |

---

## 5. VokeAPI Client Design (`lib/core/ai/voke_client.dart`)

```dart
class VokeClient {
  final Dio _dio;
  
  // Core methods
  Future<FoodAnalysis> analyzeFood(FoodScanInput input);           // Scanner
  Future<CulturalStory> tellStory(CulturalScanInput input);       // Storytelling
  Future<ItineraryPlan> planItinerary(ItineraryInput input);      // Planner
  Future<RouteDecision> decideReroute(RouteContext context);      // Crowd routing
  
  // Shared config
  static const String model = 'gemini-2.0-flash';  // or Voke's equivalent
  static const int maxTokens = 4096;
  static const double temperature = 0.1;  // Low for safety-critical
}
```

**Prompt Engineering Strategy**:
- System prompts in `lib/domain/ai/prompts/`
- JSON Schema validation for every structured output
- Retry + fallback (local rule-based) on API failure
- Token budget tracking (free tier limits)

---

## 6. Milestone Breakdown

### Milestone 0: Foundation (Week 1)
- [ ] Flutter init + Riverpod + GoRouter + Supabase client
- [ ] `secrets.dart` + `--dart-define` wiring
- [ ] VokeClient scaffold with health check endpoint
- [ ] Run app on device/emulator

### Milestone 1: Data Layer (Week 1-2)
- [ ] Supabase migrations: `traveler_profiles`, `dishes`, `attractions`, `itineraries`, `safety_tickets`
- [ ] RLS policies (user sees only own data)
- [ ] Seed 40 dishes (with hidden ingredients) + 20 POIs
- [ ] Local JSON fallback bundle
- [ ] Repository contracts + Supabase impl

### Milestone 2: Agent Tools — Core 3 (Week 2-3)
- [ ] `get_traveler_profile` (CRUD + onboarding flow)
- [ ] `fetch_danang_attractions` (filter by purpose: culture/sport/food)
- [ ] `check_route_crowd_and_safety` (Supabase Realtime + static difficulty)
- [ ] Unit tests with 8 ground-truth cases

### Milestone 3: Agent Tools — Planner + Persistence (Week 3)
- [ ] `generate_adaptive_itinerary` (VokeAPI + local constraints)
- [ ] `save_itinerary_ticket` + `verify_itinerary_status` (transactional)
- [ ] `launch_navigation_deeplink` (universal deep-link)
- [ ] Integration test: full 7-tool flow

### Milestone 4: AI Vision Pipeline (Week 3-4)
- [ ] Camera screen + image capture
- [ ] OCR (tflite_flutter Tesseract or PaddleOCR)
- [ ] `analyzeFood` via VokeAPI → parse → SafetyTicket UI
- [ ] `tellStory` for cultural POIs
- [ ] Offline fallback: local keyword matching

### Milestone 5: Crowd Routing & Polish (Week 4)
- [ ] `re_route_and_dispatch_alert` (Realtime crowd + VokeAPI reroute)
- [ ] `generate_chef_dietary_ticket` (bilingual PDF/image)
- [ ] `create_custom_safe_itinerary` (compose all tools)
- [ ] E2E test 8 ground-truth cases
- [ ] Performance: token usage, latency, offline mode

---

## 7. Token/Cost Optimization (VokeAPI Free Tier)

| Technique | Savings |
|-----------|---------|
| OCR pre-processing → send text only, not full image | ~80% vision tokens |
| Structured output (JSON schema) → no parsing retry | ~30% tokens |
| Cache attraction/dish embeddings locally | Avoid re-sending context |
| Batch safety verification in Edge Function | Reduce FE round-trips |
| Temperature 0.1 + max_tokens 2048 per call | Predictable usage |

---

## 8. Immediate Next Steps (This Session)

1. **Confirm VokeAPI specs**: Base URL, model names, rate limits, JSON schema support
2. **Create Supabase project** → get URL + anon key
3. **Run Milestone 0 tasks** → Flutter init + VokeClient health check

---

## 9. Questions for You (Confirm Before Coding)

1. **VokeAPI details**: Base URL? Model IDs? OpenAI-compatible `/v1/chat/completions`? Rate limits?
2. **Supabase**: Already created project? Or need guidance?
3. **Platform priority**: iOS + Android both? Or Android first?
4. **OCR preference**: On-device (tflite_flutter) or Supabase Edge Function (PaddleOCR)?
5. **Language**: Vietnamese-only UI first? i18n structure from start?

---

**Ready to start?** Reply with VokeAPI specs + Supabase status → I'll begin Milestone 0.