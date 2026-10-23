import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:danang_smarttour/core/constants/app_colors.dart';
import 'package:danang_smarttour/data/models/attraction_model.dart';
import 'package:danang_smarttour/data/models/heritage_guide_model.dart';
import 'package:danang_smarttour/presentation/providers/app_providers.dart';

class HeritageStorySheet extends ConsumerStatefulWidget {
  final Attraction attraction;

  const HeritageStorySheet({
    super.key,
    required this.attraction,
  });

  static Future<void> show(BuildContext context, Attraction attraction) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => HeritageStorySheet(attraction: attraction),
    );
  }

  @override
  ConsumerState<HeritageStorySheet> createState() => _HeritageStorySheetState();
}

class _HeritageStorySheetState extends ConsumerState<HeritageStorySheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isEnglish = true; // Default to English for international travelers
  final TextEditingController _questionController = TextEditingController();
  bool _isAskingAi = false;
  String? _aiResponse;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _questionController.dispose();
    super.dispose();
  }

  Future<void> _askAiGuide(HeritageGuide guide) async {
    final question = _questionController.text.trim();
    if (question.isEmpty) return;

    setState(() {
      _isAskingAi = true;
      _aiResponse = null;
    });

    try {
      final vokeClient = ref.read(vokeClientProvider);
      final prompt = '''
You are the Da Nang Cultural Heritage Expert and Storyteller for DaNang SmartTour AI.
Site: ${widget.attraction.nameVi} (${guide.historicalEra}).
User Question: "$question".
Respond warmly, accurately, and concisely (under 120 words) in English with deep cultural folklore and practical tourist respect.
''';

      final response = await vokeClient.chatCompletion(
        prompt: prompt,
        temperature: 0.7,
      );

      setState(() {
        _aiResponse = response.content;
      });
    } catch (e) {
      setState(() {
        _aiResponse = 'AI Guide connection error: $e. You can review the curated heritage notes above.';
      });
    } finally {
      setState(() => _isAskingAi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final guide = HeritageGuide.getGuideForAttraction(widget.attraction.id);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.temple_buddhist_rounded,
                    color: AppColors.primaryBlue,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.attraction.nameVi,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.goldenSand.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          guide.historicalEra,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF9A6B00),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Tabs
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primaryBlue,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primaryBlue,
              indicatorSize: TabBarIndicatorSize.tab,
              tabs: const [
                Tab(icon: Icon(Icons.menu_book, size: 18), text: 'Story'),
                Tab(icon: Icon(Icons.rule, size: 18), text: 'Sacred Etiquette'),
                Tab(icon: Icon(Icons.auto_awesome, size: 18), text: 'Ask AI Guide'),
              ],
            ),
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildStoryTab(guide),
                _buildEtiquetteTab(guide),
                _buildAiGuideTab(guide),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoryTab(HeritageGuide guide) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Language Switcher Banner
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Heritage Story & Cultural Roots',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: const Size(60, 32),
                ),
                icon: const Icon(Icons.translate, size: 14),
                label: Text(_isEnglish ? 'VIE' : 'ENG', style: const TextStyle(fontSize: 12)),
                onPressed: () => setState(() => _isEnglish = !_isEnglish),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Main Story Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFBF9F5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE8DFD1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_stories, color: Color(0xFF8A5D22), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      _isEnglish ? 'Cultural Significance' : 'Ý nghĩa Lịch sử & Tâm linh',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF8A5D22),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  _isEnglish ? guide.storyEn : guide.storyVi,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Key Highlights
          Text(
            _isEnglish ? 'Key Highlights:' : 'Điểm nhấn không thể bỏ qua:',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: guide.highlights.map((h) {
              return Chip(
                avatar: const Icon(Icons.stars, color: AppColors.goldenSand, size: 16),
                label: Text(h, style: const TextStyle(fontSize: 12)),
                backgroundColor: AppColors.background,
                side: BorderSide(color: Colors.grey.shade300),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // SDG Note
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.public, color: AppColors.primaryBlue, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    guide.sdgContribution,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEtiquetteTab(HeritageGuide guide) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.flagYellowBackground,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.flagYellow.withValues(alpha: 0.5)),
          ),
          child: const Row(
            children: [
              Icon(Icons.shield_outlined, color: Color(0xFFB78103), size: 22),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Sacred behavioral and dress code etiquette to respect local beliefs and preserve ancient heritage.',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B4B00),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Rules List
        ...guide.etiquetteRules.map((rule) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: rule.isStrict ? AppColors.flagRed.withValues(alpha: 0.3) : AppColors.divider,
                width: rule.isStrict ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: rule.isStrict ? AppColors.flagRedBackground : AppColors.background,
                    shape: BoxShape.circle,
                  ),
                  child: Text(rule.icon, style: const TextStyle(fontSize: 20)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _isEnglish ? rule.titleEn : rule.titleVi,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          if (rule.isStrict)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.flagRed,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'MANDATORY',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isEnglish ? rule.descEn : rule.descVi,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildAiGuideTab(HeritageGuide guide) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F4C81), Color(0xFF1E88E5)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              children: [
                Icon(Icons.psychology, color: Colors.white, size: 28),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Da Nang Heritage AI Guide',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Ask questions about folklore, temple architecture, and rituals.',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Suggestion Chips
          const Text(
            'Quick suggestions:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildPromptChip('What is the founding legend of this site?'),
              _buildPromptChip('What National Treasures are preserved here?'),
              _buildPromptChip('Best visiting hours and photography etiquette?'),
            ],
          ),
          const SizedBox(height: 16),

          // Text Input
          TextField(
            controller: _questionController,
            decoration: InputDecoration(
              hintText: 'Ask AI Guide about this heritage site...',
              hintStyle: const TextStyle(fontSize: 13),
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              suffixIcon: IconButton(
                icon: _isAskingAi
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded, color: AppColors.primaryBlue),
                onPressed: _isAskingAi ? null : () => _askAiGuide(guide),
              ),
            ),
            onSubmitted: (_) => _askAiGuide(guide),
          ),
          const SizedBox(height: 16),

          // Response Box
          if (_aiResponse != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.3)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryBlue.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.auto_awesome, color: AppColors.primaryBlue, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Answer from AI Local Guide:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _aiResponse!,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPromptChip(String text) {
    return ActionChip(
      label: Text(text, style: const TextStyle(fontSize: 11)),
      backgroundColor: AppColors.background,
      side: BorderSide(color: Colors.grey.shade300),
      onPressed: () {
        _questionController.text = text;
        _askAiGuide(HeritageGuide.getGuideForAttraction(widget.attraction.id));
      },
    );
  }
}
