// lib/screens/disease_roadmap_screen.dart
//
// Vertical interactive timeline of a disease's progression. Caregivers tap
// each stage to expand its details (signs, prep, doctor questions, tips).
// Optional "Where are we?" lets the caregiver mark the current stage; that
// selection is persisted per elder + disease via SharedPreferences.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cecelia_care_flutter/models/disease_roadmap.dart';
import 'package:cecelia_care_flutter/providers/active_elder_provider.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';

class DiseaseRoadmapScreen extends StatefulWidget {
  const DiseaseRoadmapScreen({super.key, required this.roadmap});
  final DiseaseRoadmap roadmap;

  @override
  State<DiseaseRoadmapScreen> createState() => _DiseaseRoadmapScreenState();
}

class _DiseaseRoadmapScreenState extends State<DiseaseRoadmapScreen> {
  int? _currentStage;
  String? _elderId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadStage());
  }

  String _key(String elderId) =>
      'roadmap_stage_${elderId}_${widget.roadmap.id}';

  Future<void> _loadStage() async {
    final elder = context.read<ActiveElderProvider>().activeElder;
    if (elder == null) return;
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _elderId = elder.id;
      _currentStage = prefs.getInt(_key(elder.id));
    });
  }

  Future<void> _setStage(int? stage) async {
    if (_elderId == null) return;
    final prefs = await SharedPreferences.getInstance();
    if (stage == null) {
      await prefs.remove(_key(_elderId!));
    } else {
      await prefs.setInt(_key(_elderId!), stage);
    }
    setState(() => _currentStage = stage);
  }

  Color _stageColor(int index, int total) {
    // Green → amber → red gradient by stage index.
    final t = total <= 1 ? 0.0 : index / (total - 1);
    if (t < 0.4) return const Color(0xFF43A047);
    if (t < 0.75) return const Color(0xFFF57C00);
    return const Color(0xFFE53935);
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.roadmap;
    return Scaffold(
      appBar: AppBar(
        title: Text(r.name),
        backgroundColor: r.color,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          // Overview card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  r.color.withValues(alpha: 0.12),
                  r.color.withValues(alpha: 0.04),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: r.color.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: r.color.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(r.icon, color: r.color, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: r.color,
                          )),
                      const SizedBox(height: 4),
                      Text(r.overview,
                          style: const TextStyle(
                              fontSize: 12, height: 1.4)),
                      const SizedBox(height: 6),
                      Text('${r.stages.length} stages',
                          style: TextStyle(
                              fontSize: 11,
                              color: r.color.withValues(alpha: 0.8),
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // "Where are we?" picker
          _StagePicker(
            stages: r.stages,
            current: _currentStage,
            onChanged: _setStage,
            color: r.color,
          ),
          const SizedBox(height: 18),

          // Vertical timeline
          for (int i = 0; i < r.stages.length; i++)
            _StageTimelineRow(
              stage: r.stages[i],
              color: _stageColor(i, r.stages.length),
              isFirst: i == 0,
              isLast: i == r.stages.length - 1,
              isCurrent: _currentStage == r.stages[i].number,
              dimmed: _currentStage != null &&
                  r.stages[i].number > _currentStage!,
            ),

          const SizedBox(height: 16),
          Center(
            child: Text(
              'Educational reference only — not medical advice.\nAlways consult your care team.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StagePicker extends StatelessWidget {
  const _StagePicker({
    required this.stages,
    required this.current,
    required this.onChanged,
    required this.color,
  });

  final List<DiseaseStage> stages;
  final int? current;
  final ValueChanged<int?> onChanged;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundGray,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.place_outlined, size: 16),
              const SizedBox(width: 6),
              const Expanded(
                child: Text('Where are we?',
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700)),
              ),
              if (current != null)
                TextButton(
                  onPressed: () => onChanged(null),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: const Text('Clear',
                      style: TextStyle(fontSize: 11)),
                ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Mark the stage that best describes your situation. Stays on this device.',
            style: TextStyle(
                fontSize: 11, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: stages.map((s) {
              final selected = current == s.number;
              return GestureDetector(
                onTap: () => onChanged(selected ? null : s.number),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: selected
                        ? color.withValues(alpha: 0.18)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: selected ? color : Colors.grey.shade300,
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: Text(
                    'Stage ${s.number}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight:
                          selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? color : Colors.grey.shade700,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _StageTimelineRow extends StatelessWidget {
  const _StageTimelineRow({
    required this.stage,
    required this.color,
    required this.isFirst,
    required this.isLast,
    required this.isCurrent,
    required this.dimmed,
  });

  final DiseaseStage stage;
  final Color color;
  final bool isFirst;
  final bool isLast;
  final bool isCurrent;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline gutter
          SizedBox(
            width: 36,
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    width: 2,
                    color: isFirst
                        ? Colors.transparent
                        : color.withValues(alpha: 0.4),
                  ),
                ),
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: dimmed ? Colors.grey.shade300 : color,
                    shape: BoxShape.circle,
                    border: isCurrent
                        ? Border.all(color: Colors.white, width: 3)
                        : null,
                    boxShadow: isCurrent
                        ? [
                            BoxShadow(
                              color: color.withValues(alpha: 0.5),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  child: Text('${stage.number}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      )),
                ),
                Expanded(
                  child: Container(
                    width: 2,
                    color: isLast
                        ? Colors.transparent
                        : color.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10, top: 4),
              child: Opacity(
                opacity: dimmed ? 0.55 : 1.0,
                child: _StageCard(
                  stage: stage,
                  color: color,
                  highlighted: isCurrent,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StageCard extends StatelessWidget {
  const _StageCard({
    required this.stage,
    required this.color,
    required this.highlighted,
  });

  final DiseaseStage stage;
  final Color color;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: highlighted ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: highlighted ? color : Colors.transparent,
          width: highlighted ? 2 : 0,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: highlighted,
          tilePadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          title: Text(stage.title,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w800)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Row(
              children: [
                Icon(Icons.schedule, size: 12, color: color),
                const SizedBox(width: 4),
                Text(stage.duration,
                    style: TextStyle(
                        fontSize: 11,
                        color: color,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(stage.whatToExpect,
                  style: const TextStyle(fontSize: 12, height: 1.4)),
            ),
            const SizedBox(height: 12),
            _Section(
              icon: Icons.visibility_outlined,
              title: 'Watch for these signs',
              items: stage.signs,
              color: color,
            ),
            _Section(
              icon: Icons.event_note_outlined,
              title: 'Prepare for this stage',
              items: stage.prepareFor,
              color: color,
            ),
            _Section(
              icon: Icons.help_outline,
              title: 'Ask your doctor',
              items: stage.doctorQuestions,
              color: color,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withValues(alpha: 0.25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.tips_and_updates_outlined,
                          size: 14, color: color),
                      const SizedBox(width: 6),
                      Text('Caregiver tips',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: color)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ...stage.caregiverTips.map((t) => Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text('• $t',
                            style:
                                const TextStyle(fontSize: 12, height: 1.35)),
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.icon,
    required this.title,
    required this.items,
    required this.color,
  });

  final IconData icon;
  final String title;
  final List<String> items;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(title.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: color,
                  )),
            ],
          ),
          const SizedBox(height: 4),
          ...items.map((s) => Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text('• $s',
                    style: const TextStyle(fontSize: 12, height: 1.4)),
              )),
        ],
      ),
    );
  }
}
