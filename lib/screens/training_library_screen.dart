// lib/screens/training_library_screen.dart
//
// Categorized caregiver training hub. Replaces the flat resource list with
// learning modules, progress tracking, and search.

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:cecelia_care_flutter/models/disease_roadmap.dart';
import 'package:cecelia_care_flutter/models/glossary_term.dart';
import 'package:cecelia_care_flutter/models/training_resource.dart';
import 'package:cecelia_care_flutter/screens/disease_roadmap_screen.dart';
import 'package:cecelia_care_flutter/screens/medical_glossary_screen.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';

class TrainingLibraryScreen extends StatefulWidget {
  final TrainingCategory? initialCategory;
  const TrainingLibraryScreen({super.key, this.initialCategory});

  @override
  State<TrainingLibraryScreen> createState() => _TrainingLibraryScreenState();
}

class _TrainingLibraryScreenState extends State<TrainingLibraryScreen> {
  static const String _prefsKey = 'viewed_training_resources';
  Set<String> _viewedIds = {};
  String _searchQuery = '';
  TrainingCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
    _loadViewed();
  }

  Future<void> _loadViewed() async {
    final sp = await SharedPreferences.getInstance();
    final list = sp.getStringList(_prefsKey) ?? [];
    setState(() => _viewedIds = list.toSet());
  }

  Future<void> _markViewed(String id) async {
    _viewedIds.add(id);
    final sp = await SharedPreferences.getInstance();
    await sp.setStringList(_prefsKey, _viewedIds.toList());
    setState(() {});
  }

  Future<void> _openResource(TrainingResource r) async {
    await _markViewed(r.id);
    final uri = Uri.parse(r.url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open link.')),
      );
    }
  }

  List<TrainingResource> get _filteredResources {
    var resources = _selectedCategory != null
        ? TrainingResource.forCategory(_selectedCategory!)
        : TrainingResource.all;

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      resources = resources
          .where((r) =>
              r.title.toLowerCase().contains(q) ||
              r.description.toLowerCase().contains(q) ||
              r.source.toLowerCase().contains(q))
          .toList();
    }
    return resources;
  }

  int _viewedInCategory(TrainingCategory cat) {
    final ids = TrainingResource.forCategory(cat).map((r) => r.id);
    return ids.where((id) => _viewedIds.contains(id)).length;
  }

  @override
  Widget build(BuildContext context) {
    final totalViewed = _viewedIds.length;
    final totalResources = TrainingResource.all.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Training Library'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Search ─────────────────────────────────────────
          TextField(
            decoration: InputDecoration(
              hintText: 'Search resources...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
              isDense: true,
            ),
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
          const SizedBox(height: 12),

          // ── Progress banner ────────────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.tileTeal.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppTheme.tileTeal.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 40,
                  height: 40,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: totalResources > 0
                            ? totalViewed / totalResources
                            : 0,
                        strokeWidth: 4,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            AppTheme.tileTeal),
                      ),
                      Text('$totalViewed',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'You\'ve explored $totalViewed of $totalResources resources',
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      Text('Keep learning \u2014 every bit helps.',
                          style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Disease Progression Guides ────────────────────
          if (_selectedCategory == null && _searchQuery.isEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text('Disease Progression Guides',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textSecondary,
                  )),
            ),
            SizedBox(
              height: 130,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: DiseaseRoadmap.all.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, i) {
                  final r = DiseaseRoadmap.all[i];
                  return GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) =>
                              DiseaseRoadmapScreen(roadmap: r)),
                    ),
                    child: Container(
                      width: 150,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            r.color.withValues(alpha: 0.18),
                            r.color.withValues(alpha: 0.06),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: r.color.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color:
                                  r.color.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(r.icon,
                                color: r.color, size: 22),
                          ),
                          Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                r.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: r.color,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${r.stages.length} stages',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: r.color
                                      .withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
          ],

          // ── Medical Glossary entry ────────────────────────
          if (_selectedCategory == null && _searchQuery.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const MedicalGlossaryScreen()),
                ),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryColor.withValues(alpha: 0.12),
                        AppTheme.primaryColor.withValues(alpha: 0.04),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: AppTheme.primaryColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.menu_book_outlined,
                            color: AppTheme.primaryColor, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Medical Glossary',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primaryColor,
                                )),
                            const SizedBox(height: 2),
                            Text(
                              'Plain-language definitions for ${kGlossaryTerms.length} medical terms',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.primaryColor
                                      .withValues(alpha: 0.75)),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right,
                          color: AppTheme.primaryColor),
                    ],
                  ),
                ),
              ),
            ),

          // ── Category cards ─────────────────────────────────
          if (_selectedCategory == null && _searchQuery.isEmpty) ...[
            ...TrainingResource.categories.entries.map((e) {
              final cat = e.key;
              final info = e.value;
              final catResources = TrainingResource.forCategory(cat);
              final viewed = _viewedInCategory(cat);

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GestureDetector(
                  onTap: () =>
                      setState(() => _selectedCategory = cat),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: info.color.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: info.color.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: info.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child:
                              Icon(info.icon, color: info.color, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(info.label,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: info.color,
                                  )),
                              Text(info.description,
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: info.color
                                          .withValues(alpha: 0.7))),
                            ],
                          ),
                        ),
                        Column(
                          children: [
                            Text('$viewed/${catResources.length}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: viewed == catResources.length
                                      ? AppTheme.statusGreen
                                      : AppTheme.textSecondary,
                                )),
                            if (viewed == catResources.length)
                              const Icon(Icons.check_circle,
                                  size: 14,
                                  color: AppTheme.statusGreen),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ] else ...[
            // ── Back to categories ────────────────────────────
            if (_selectedCategory != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () =>
                          setState(() => _selectedCategory = null),
                      child: Row(
                        children: [
                          Icon(Icons.arrow_back,
                              size: 16, color: AppTheme.primaryColor),
                          const SizedBox(width: 4),
                          Text('All Categories',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.primaryColor)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      TrainingResource
                          .categories[_selectedCategory]!.label,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),

            // ── Resource list ─────────────────────────────────
            ..._filteredResources.map((r) {
              final isViewed = _viewedIds.contains(r.id);
              final catInfo =
                  TrainingResource.categories[r.category]!;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  onTap: () => _openResource(r),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isViewed
                          ? AppTheme.statusGreen.withValues(alpha: 0.04)
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isViewed
                            ? AppTheme.statusGreen
                                .withValues(alpha: 0.2)
                            : Colors.grey.shade200,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                            TrainingResource.typeIcon(r.type),
                            size: 20,
                            color: catInfo.color),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(r.title,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 2),
                              Text(r.description,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: catInfo.color
                                      .withValues(alpha: 0.1),
                                  borderRadius:
                                      BorderRadius.circular(6),
                                ),
                                child: Text(r.source,
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: catInfo.color)),
                              ),
                            ],
                          ),
                        ),
                        if (isViewed)
                          const Icon(Icons.check_circle,
                              size: 16,
                              color: AppTheme.statusGreen),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
