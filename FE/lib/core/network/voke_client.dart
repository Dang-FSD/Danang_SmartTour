import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:danang_smarttour/core/config/env_config.dart';

class VokeAIResponse {
  final bool success;
  final String content;
  final Map<String, dynamic>? jsonPayload;
  final String? error;
  final int elapsedMs;

  VokeAIResponse({
    required this.success,
    required this.content,
    this.jsonPayload,
    this.error,
    this.elapsedMs = 0,
  });
}

class VokeClient {
  final String baseUrl;
  final String apiKey;
  final String model;
  final http.Client _client;

  VokeClient({
    String? baseUrl,
    String? apiKey,
    String? model,
    http.Client? client,
  })  : baseUrl = (baseUrl ?? EnvConfig.vokeBaseUrl).replaceAll(RegExp(r'/+$'), ''),
        apiKey = apiKey ?? EnvConfig.vokeApiKey,
        model = model ?? EnvConfig.vokeModel,
        _client = client ?? http.Client();

  /// Gửi prompt suy luận thông thường tới VokeAPI
  Future<VokeAIResponse> chatCompletion({
    required String prompt,
    String? systemPrompt,
    double temperature = 0.1,
    int maxTokens = 1000,
  }) async {
    final stopwatch = Stopwatch()..start();
    final url = Uri.parse('$baseUrl/chat/completions');

    final messages = <Map<String, dynamic>>[];
    if (systemPrompt != null && systemPrompt.isNotEmpty) {
      messages.add({'role': 'system', 'content': systemPrompt});
    }
    messages.add({'role': 'user', 'content': prompt});

    try {
      final response = await _client.post(
        url,
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': model,
          'messages': messages,
          'temperature': temperature,
          'max_tokens': maxTokens,
        }),
      ).timeout(const Duration(seconds: 30));

      stopwatch.stop();

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final content = data['choices']?[0]?['message']?['content']?.toString() ?? '';
        
        Map<String, dynamic>? parsedJson;
        try {
          // Trích xuất JSON nếu phản hồi nằm trong markdown codeblock
          final cleanJson = _extractJsonString(content);
          if (cleanJson != null) {
            parsedJson = jsonDecode(cleanJson);
          }
        } catch (_) {}

        return VokeAIResponse(
          success: true,
          content: content,
          jsonPayload: parsedJson,
          elapsedMs: stopwatch.elapsedMilliseconds,
        );
      } else {
        return VokeAIResponse(
          success: false,
          content: '',
          error: 'VokeAPI Error (${response.statusCode}): ${response.body}',
          elapsedMs: stopwatch.elapsedMilliseconds,
        );
      }
    } catch (e) {
      stopwatch.stop();
      return VokeAIResponse(
        success: false,
        content: '',
        error: 'Network error: $e',
        elapsedMs: stopwatch.elapsedMilliseconds,
      );
    }
  }

  /// Phân tích hình ảnh (Multimodal Vision) qua VokeAPI
  Future<VokeAIResponse> analyzeImage({
    required String imageBase64,
    required String prompt,
    String mimeType = 'image/jpeg',
  }) async {
    final stopwatch = Stopwatch()..start();
    final url = Uri.parse('$baseUrl/chat/completions');

    final dataUrl = 'data:$mimeType;base64,$imageBase64';

    final messages = [
      {
        'role': 'user',
        'content': [
          {'type': 'text', 'text': prompt},
          {
            'type': 'image_url',
            'image_url': {'url': dataUrl}
          }
        ]
      }
    ];

    try {
      final response = await _client.post(
        url,
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': model,
          'messages': messages,
          'max_tokens': 1200,
          'temperature': 0.1,
        }),
      ).timeout(const Duration(seconds: 45));

      stopwatch.stop();

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final content = data['choices']?[0]?['message']?['content']?.toString() ?? '';
        
        Map<String, dynamic>? parsedJson;
        try {
          final cleanJson = _extractJsonString(content);
          if (cleanJson != null) {
            parsedJson = jsonDecode(cleanJson);
          }
        } catch (_) {}

        return VokeAIResponse(
          success: true,
          content: content,
          jsonPayload: parsedJson,
          elapsedMs: stopwatch.elapsedMilliseconds,
        );
      } else {
        return VokeAIResponse(
          success: false,
          content: '',
          error: 'VokeAPI Vision Error (${response.statusCode}): ${response.body}',
          elapsedMs: stopwatch.elapsedMilliseconds,
        );
      }
    } catch (e) {
      stopwatch.stop();
      return VokeAIResponse(
        success: false,
        content: '',
        error: 'Vision Network Error: $e',
        elapsedMs: stopwatch.elapsedMilliseconds,
      );
    }
  }

  /// Phân tích chuyên sâu món ăn Đà Nẵng
  Future<VokeAIResponse> analyzeFoodSafety({
    required String dishName,
    required Map<String, dynamic> travelerProfile,
  }) async {
    const systemPrompt = '''
You are the DaNang SmartTour AI Food & Cultural Safety Expert.
Task: Deconstruct hidden ingredients in Central Vietnamese cuisine based on the traveler's medical and religious profile.
Flag rules:
- RED: Strict Halal violation (stewed pork bone broth / lard) or severe irreversible anaphylactic allergen.
- YELLOW: Manageable risk with modifications (e.g. peanut allergy in Mi Quang -> omit peanuts and peanut oil), or ambiguous ingredients requiring kitchen verification.
- GREEN: 100% safe.

Return ONLY a valid JSON object matching this schema:
{
  "dish_name": "Dish name",
  "hidden_ingredients": ["ingredient 1", "ingredient 2"],
  "safety_level": "RED" | "YELLOW" | "GREEN",
  "reason": "Clear concise English explanation",
  "requires_kitchen_confirmation": true | false,
  "chef_ticket_vi": "Instruction for local Vietnamese chef in Vietnamese",
  "chef_ticket_en": "Instruction for tourist in English"
}
''';

    final prompt = '''
Dish: "$dishName"
Traveler Profile:
- Faith / Diet: ${travelerProfile['diet_rule'] ?? 'Standard'}
- Allergy: ${travelerProfile['allergen'] ?? 'None'} (Severity: ${travelerProfile['allergen_severity'] ?? 'N/A'})
- Medical condition: ${travelerProfile['medical_condition'] ?? 'None'}
''';

    return chatCompletion(
      prompt: prompt,
      systemPrompt: systemPrompt,
      temperature: 0.1,
      maxTokens: 800,
    );
  }

  String? _extractJsonString(String raw) {
    raw = raw.trim();
    if (raw.startsWith('{') && raw.endsWith('}')) return raw;
    final codeBlockMatch = RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```').firstMatch(raw);
    if (codeBlockMatch != null) {
      return codeBlockMatch.group(1)?.trim();
    }
    final braceMatch = RegExp(r'\{[\s\S]*\}').firstMatch(raw);
    return braceMatch?.group(0);
  }
}
