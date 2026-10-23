"""
DaNang SmartTour AI — VokeAPI Official Active Models Catalog
Verified live against VokeAPI edge gateway (GET /v1/models).
Only contains models officially hosted and active on VokeAPI.
"""

from typing import Dict, List, Any


# ─── 1. ALL 19 ACTIVE MODELS ON VOKEAPI (LIVE VERIFIED) ──────────────
VOKE_ACTIVE_MODELS: Dict[str, Dict[str, Any]] = {
    # ─── Flagship Multimodal & Vision Models ────────────────────────
    "gemini-3.8-flash": {
        "display_name": "gemini-3.8-flash (flagship)",
        "provider": "google",
        "tier": "flagship",
        "multimodal": True,
        "vision": True,
        "description": "Google flagship multimodal intelligence with ultra-fast inference, vision, audio comprehension and agent tool use.",
        "best_for": "Food scanning, OCR deconstruction, fast adaptive itinerary reasoning",
    },
    "deepseek-v4-pro": {
        "display_name": "deepseek-v4-pro (flagship)",
        "provider": "deepseek",
        "tier": "flagship",
        "multimodal": True,
        "vision": True,
        "description": "Frontier reasoning and agentic coding for demanding workloads with deep chain-of-thought.",
        "best_for": "Deep Vietnamese culinary deconstruction, allergen & religious rule verification",
    },
    "step-5-preview": {
        "display_name": "step-5-preview (frontier)",
        "provider": "stepfun",
        "tier": "frontier",
        "multimodal": True,
        "vision": True,
        "description": "StepFun flagship model for agentic work. Natively supports text, image, and video input with 1M-token context window.",
        "best_for": "High-resolution dish image inspection, complex menu OCR",
    },
    "qwen3.8-flash": {
        "display_name": "qwen3.8-flash (fast)",
        "provider": "qwen",
        "tier": "fast",
        "multimodal": True,
        "vision": True,
        "description": "Fast multimodal intelligence with long context, coding and tool use.",
        "best_for": "Low-latency multimodal queries, quick menu reading",
    },
    "mimo-v2.6-flash": {
        "display_name": "mimo-v2.6-flash (fast)",
        "provider": "xiaomi",
        "tier": "fast",
        "multimodal": True,
        "vision": True,
        "description": "Fast multimodal agent intelligence across text, image, video and audio.",
        "best_for": "Edge multimodal reasoning",
    },

    # ─── Flagship Reasoning & Agentic Planning Models ────────────────
    "gemini-3.1-pro": {
        "display_name": "gemini-3.1-pro (flagship)",
        "provider": "google",
        "tier": "flagship",
        "multimodal": False,
        "vision": False,
        "description": "Frontier reasoning and agentic intelligence designed for complex codebases and advanced problem solving.",
        "best_for": "Complex adaptive multi-day itinerary generation, GIS crowd rerouting logic",
    },
    "gemini-3.5-flash-lite-thinking": {
        "display_name": "gemini-3.5-flash-lite-thinking (fast)",
        "provider": "google",
        "tier": "fast",
        "multimodal": False,
        "vision": False,
        "description": "High-speed reasoning model with extended chain-of-thought thinking for technical and coding workloads.",
        "best_for": "Zero false-safe verification gates, medical safety evaluation",
    },
    "gpt-6-luna": {
        "display_name": "gpt-6-luna (flagship)",
        "provider": "openai",
        "tier": "flagship",
        "multimodal": False,
        "vision": False,
        "description": "Advanced Luna intelligence with 1.05M–1.1M token context window, high precision reasoning, deep agentic coding.",
        "best_for": "Long-context tourist history and comprehensive travel guide generation",
    },
    "grok-4.7": {
        "display_name": "grok-4.7 (flagship)",
        "provider": "xai",
        "tier": "flagship",
        "multimodal": False,
        "vision": False,
        "description": "Flagship Grok model for advanced reasoning, analysis, and agentic workflows.",
        "best_for": "Real-time traffic pattern analysis, high-level travel decision making",
    },
    "nemotron-3-ultra-550b-a55b": {
        "display_name": "nemotron-3-ultra-550b-a55b (frontier)",
        "provider": "nvidia",
        "tier": "frontier",
        "multimodal": False,
        "vision": False,
        "description": "Large-scale 550B parameter reasoning and agentic intelligence for demanding workloads.",
        "best_for": "Complex multi-variable optimization",
    },

    # ─── Ultra-Fast & Edge Agentic Models ────────────────────────────
    "laguna-s-2.1": {
        "display_name": "laguna-s-2.1 (flagship)",
        "provider": "poolside",
        "tier": "flagship",
        "multimodal": False,
        "vision": False,
        "description": "Agentic coding intelligence designed for large codebases and autonomous workflows with blazing 1.5s latency.",
        "best_for": "Ultra-fast JSON extraction, instant safety status checks",
    },
    "deepseek-v4.1-flash": {
        "display_name": "deepseek-v4.1-flash (fast)",
        "provider": "deepseek",
        "tier": "fast",
        "multimodal": False,
        "vision": False,
        "description": "Fast DeepSeek coding and reasoning for agent workflows.",
        "best_for": "Quick agent tool-calling, rapid query routing",
    },
    "deepseek-v4-flash": {
        "display_name": "deepseek-v4-flash (fast)",
        "provider": "deepseek",
        "tier": "fast",
        "multimodal": False,
        "vision": False,
        "description": "Fast, efficient intelligence for coding, agents and long-context work.",
        "best_for": "Lightweight tourist query responses, quick translations",
    },
    "grok-4.6-fast": {
        "display_name": "grok-4.6-fast (fast)",
        "provider": "xai",
        "tier": "fast",
        "multimodal": False,
        "vision": False,
        "description": "Fast-tier Grok 4.6 with 500,000 token context window for low-latency agentic workflows.",
        "best_for": "Fast conversational assistant, real-time chat with tourists",
    },
    "grok-build-0.1": {
        "display_name": "grok-build-0.1 (coding)",
        "provider": "xai",
        "tier": "coding",
        "multimodal": False,
        "vision": False,
        "description": "Coding-focused Grok model for software development and agentic coding workflows.",
        "best_for": "Structured data generation, schema validation",
    },
    "glm-5.3-flash": {
        "display_name": "glm-5.3-flash (fast)",
        "provider": "zhipu",
        "tier": "fast",
        "multimodal": False,
        "vision": False,
        "description": "Fast reasoning and coding intelligence for production workloads.",
        "best_for": "Multilingual Vietnamese - English translation",
    },
    "dots-3-note-preview": {
        "display_name": "dots-3-note-preview (preview)",
        "provider": "llm360",
        "tier": "preview",
        "multimodal": False,
        "vision": False,
        "description": "Preview reasoning model for technical, coding and knowledge workloads.",
        "best_for": "Da Nang cultural heritage storytelling",
    },
    "north-mini-code": {
        "display_name": "north-mini-code (fast)",
        "provider": "north",
        "tier": "fast",
        "multimodal": False,
        "vision": False,
        "description": "A compact coding-focused model for fast everyday development.",
        "best_for": "Lightweight tasks",
    },
    "gpt-oss-120b": {
        "display_name": "gpt-oss-120b (fast)",
        "provider": "openai",
        "tier": "fast",
        "multimodal": False,
        "vision": False,
        "description": "Open-weight 120B general-purpose model for varied workloads.",
        "best_for": "General knowledge query fallback",
    },
}

# ─── 2. RECOMMENDED TOP-TIER MODELS FOR DANANG SMARTTOUR AI ──────────
TOP_MODELS_FOR_PROJECT = {
    # 1. Primary AI Vision Food Scanner:
    "PRIMARY_VISION": "deepseek-v4-pro",
    # 2. High-speed Multimodal Alternate:
    "FAST_VISION": "gemini-3.8-flash",
    # 3. Frontier Multi-Lingual Multimodal:
    "FRONTIER_VISION": "step-5-preview",
    # 4. Primary Itinerary Planner & Agentic Reasoning:
    "PRIMARY_PLANNER": "gemini-3.1-pro",
    # 5. Low-latency Chat & Tourist Guide:
    "FAST_CHAT": "deepseek-v4.1-flash",
    # 6. Ultra-Fast Structured JSON extractor:
    "FAST_EXTRACTOR": "laguna-s-2.1",
}

# ─── 3. LIST OF ALL VALID MODEL IDS FOR CLI & CONFIGURATION ──────────
VALID_MODEL_IDS: List[str] = list(VOKE_ACTIVE_MODELS.keys())
