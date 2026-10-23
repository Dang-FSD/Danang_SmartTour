class VokeModelMeta {
  final String id;
  final String displayName;
  final String provider;
  final String tier;
  final bool isMultimodal;
  final String description;
  final String bestFor;

  const VokeModelMeta({
    required this.id,
    required this.displayName,
    required this.provider,
    required this.tier,
    required this.isMultimodal,
    required this.description,
    required this.bestFor,
  });
}

/// Official list of all 19 active models available on VokeAPI.
/// Verified live against VokeAPI edge gateway (GET /v1/models).
class VokeModelsCatalog {
  // ─── Primary Recommended Models for Da Nang SmartTour AI ───────────
  static const String primaryVision = 'deepseek-v4-pro';
  static const String fastVision = 'gemini-3.8-flash';
  static const String frontierVision = 'step-5-preview';
  static const String primaryPlanner = 'gemini-3.1-pro';
  static const String fastChat = 'deepseek-v4.1-flash';
  static const String fastExtractor = 'laguna-s-2.1';

  // ─── All 19 Active Models on VokeAPI ────────────────────────────────
  static const List<VokeModelMeta> allModels = [
    // Flagship Multimodal & Vision
    VokeModelMeta(
      id: 'deepseek-v4-pro',
      displayName: 'deepseek-v4-pro (flagship)',
      provider: 'DeepSeek',
      tier: 'flagship',
      isMultimodal: true,
      description: 'Frontier reasoning and agentic coding for demanding workloads with deep chain-of-thought.',
      bestFor: 'Culinary ingredient deconstruction, allergen & religious rule verification',
    ),
    VokeModelMeta(
      id: 'gemini-3.8-flash',
      displayName: 'gemini-3.8-flash (flagship)',
      provider: 'Google',
      tier: 'flagship',
      isMultimodal: true,
      description: 'Google flagship multimodal intelligence with ultra-fast inference, vision, audio comprehension and agent tool use.',
      bestFor: 'High-speed food scanning and live OCR',
    ),
    VokeModelMeta(
      id: 'step-5-preview',
      displayName: 'step-5-preview (frontier)',
      provider: 'StepFun',
      tier: 'frontier',
      isMultimodal: true,
      description: 'StepFun flagship model for agentic work with native text, image, video and 1M-token context.',
      bestFor: 'High-resolution dish image inspection, complex menu OCR',
    ),
    VokeModelMeta(
      id: 'qwen3.8-flash',
      displayName: 'qwen3.8-flash (fast)',
      provider: 'Qwen',
      tier: 'fast',
      isMultimodal: true,
      description: 'Fast multimodal intelligence with long context, coding and tool use.',
      bestFor: 'Fast menu text & visual query',
    ),
    VokeModelMeta(
      id: 'mimo-v2.6-flash',
      displayName: 'mimo-v2.6-flash (fast)',
      provider: 'Xiaomi',
      tier: 'fast',
      isMultimodal: true,
      description: 'Fast multimodal agent intelligence across text, image, video and audio.',
      bestFor: 'Edge multimodal reasoning',
    ),

    // Flagship Reasoning & Agentic Planning
    VokeModelMeta(
      id: 'gemini-3.1-pro',
      displayName: 'gemini-3.1-pro (flagship)',
      provider: 'Google',
      tier: 'flagship',
      isMultimodal: false,
      description: 'Frontier reasoning and agentic intelligence designed for complex codebases and advanced problem solving.',
      bestFor: 'Complex adaptive multi-day itinerary generation, GIS crowd rerouting logic',
    ),
    VokeModelMeta(
      id: 'gemini-3.5-flash-lite-thinking',
      displayName: 'gemini-3.5-flash-lite-thinking (fast)',
      provider: 'Google',
      tier: 'fast',
      isMultimodal: false,
      description: 'High-speed reasoning model with extended chain-of-thought thinking for technical and coding workloads.',
      bestFor: 'Zero false-safe verification gates, medical safety evaluation',
    ),
    VokeModelMeta(
      id: 'gpt-6-luna',
      displayName: 'gpt-6-luna (flagship)',
      provider: 'OpenAI',
      tier: 'flagship',
      isMultimodal: false,
      description: 'Advanced Luna intelligence with 1.05M–1.1M token context window, high precision reasoning, deep agentic coding.',
      bestFor: 'Long-context tourist history and comprehensive travel guide generation',
    ),
    VokeModelMeta(
      id: 'grok-4.7',
      displayName: 'grok-4.7 (flagship)',
      provider: 'xAI',
      tier: 'flagship',
      isMultimodal: false,
      description: 'Flagship Grok model for advanced reasoning, analysis, and agentic workflows.',
      bestFor: 'Real-time traffic pattern analysis, high-level travel decision making',
    ),
    VokeModelMeta(
      id: 'nemotron-3-ultra-550b-a55b',
      displayName: 'nemotron-3-ultra-550b-a55b (frontier)',
      provider: 'NVIDIA',
      tier: 'frontier',
      isMultimodal: false,
      description: 'Large-scale 550B parameter reasoning and agentic intelligence for demanding workloads.',
      bestFor: 'Complex multi-variable optimization',
    ),

    // Ultra-Fast & Edge Agentic Models
    VokeModelMeta(
      id: 'laguna-s-2.1',
      displayName: 'laguna-s-2.1 (flagship)',
      provider: 'Poolside',
      tier: 'flagship',
      isMultimodal: false,
      description: 'Agentic coding intelligence designed for large codebases and autonomous workflows with blazing 1.5s latency.',
      bestFor: 'Ultra-fast JSON extraction, instant safety status checks',
    ),
    VokeModelMeta(
      id: 'deepseek-v4.1-flash',
      displayName: 'deepseek-v4.1-flash (fast)',
      provider: 'DeepSeek',
      tier: 'fast',
      isMultimodal: false,
      description: 'Fast DeepSeek coding and reasoning for agent workflows.',
      bestFor: 'Quick agent tool-calling, rapid query routing',
    ),
    VokeModelMeta(
      id: 'deepseek-v4-flash',
      displayName: 'deepseek-v4-flash (fast)',
      provider: 'DeepSeek',
      tier: 'fast',
      isMultimodal: false,
      description: 'Fast, efficient intelligence for coding, agents and long-context work.',
      bestFor: 'Lightweight tourist query responses, quick translations',
    ),
    VokeModelMeta(
      id: 'grok-4.6-fast',
      displayName: 'grok-4.6-fast (fast)',
      provider: 'xAI',
      tier: 'fast',
      isMultimodal: false,
      description: 'Fast-tier Grok 4.6 with 500,000 token context window for low-latency agentic workflows.',
      bestFor: 'Fast conversational assistant, real-time chat with tourists',
    ),
    VokeModelMeta(
      id: 'grok-build-0.1',
      displayName: 'grok-build-0.1 (coding)',
      provider: 'xAI',
      tier: 'coding',
      isMultimodal: false,
      description: 'Coding-focused Grok model for software development and agentic coding workflows.',
      bestFor: 'Structured data generation, schema validation',
    ),
    VokeModelMeta(
      id: 'glm-5.3-flash',
      displayName: 'glm-5.3-flash (fast)',
      provider: 'Zhipu',
      tier: 'fast',
      isMultimodal: false,
      description: 'Fast reasoning and coding intelligence for production workloads.',
      bestFor: 'Multilingual Vietnamese - English translation',
    ),
    VokeModelMeta(
      id: 'dots-3-note-preview',
      displayName: 'dots-3-note-preview (preview)',
      provider: 'LLM360',
      tier: 'preview',
      isMultimodal: false,
      description: 'Preview reasoning model for technical, coding and knowledge workloads.',
      bestFor: 'Da Nang cultural heritage storytelling',
    ),
    VokeModelMeta(
      id: 'north-mini-code',
      displayName: 'north-mini-code (fast)',
      provider: 'North',
      tier: 'fast',
      isMultimodal: false,
      description: 'A compact coding-focused model for fast everyday development.',
      bestFor: 'Lightweight tasks',
    ),
    VokeModelMeta(
      id: 'gpt-oss-120b',
      displayName: 'gpt-oss-120b (fast)',
      provider: 'OpenAI',
      tier: 'fast',
      isMultimodal: false,
      description: 'Open-weight 120B general-purpose model for varied workloads.',
      bestFor: 'General knowledge query fallback',
    ),
  ];

  static bool isValidModel(String modelId) {
    return allModels.any((m) => m.id == modelId);
  }
}
