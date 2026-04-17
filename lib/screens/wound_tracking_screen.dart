// lib/screens/wound_tracking_screen.dart
//
// Clinical photo documentation for wounds, skin conditions, and injuries.
// Capture photos with metadata (body region, type, severity) and compare
// before/after over time.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:cecelia_care_flutter/models/wound_entry.dart';
import 'package:cecelia_care_flutter/providers/active_elder_provider.dart';
import 'package:cecelia_care_flutter/services/firestore_service.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';
import 'package:cecelia_care_flutter/widgets/skeleton_loaders.dart';
import 'package:cecelia_care_flutter/utils/haptic_utils.dart';
import 'package:cecelia_care_flutter/widgets/cached_avatar.dart';
import 'package:cecelia_care_flutter/widgets/empty_state_widget.dart';

class WoundTrackingScreen extends StatefulWidget {
  const WoundTrackingScreen({super.key});

  @override
  State<WoundTrackingScreen> createState() => _WoundTrackingScreenState();
}

class _WoundTrackingScreenState extends State<WoundTrackingScreen> {
  final FirestoreService _firestore = FirestoreService();
  String _regionFilter = 'all';

  // ── Photo capture + metadata ────────────────────────────────────

  Future<void> _captureAndUpload() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;

    final picker = ImagePicker();
    final image = await picker.pickImage(
        source: source, imageQuality: 85, maxWidth: 1200);
    if (image == null || !mounted) return;

    _showMetadataForm(File(image.path), image.name);
  }

  void _showMetadataForm(File imageFile, String fileName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.92,
        ),
        decoration: BoxDecoration(
          color: Theme.of(ctx).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: _WoundMetadataForm(
          imageFile: imageFile,
          fileName: fileName,
          firestore: _firestore,
        ),
      ),
    );
  }

  // ── Build ───────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final elderId =
        context.watch<ActiveElderProvider>().activeElder?.id ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Wound Tracker')),
      floatingActionButton: FloatingActionButton(
        onPressed: _captureAndUpload,
        backgroundColor: AppTheme.statusRed,
        child: const Icon(Icons.add_a_photo, color: Colors.white),
      ),
      body: elderId.isEmpty
          ? const Center(child: Text('No care recipient selected.'))
          : Column(
              children: [
                // ── Region filter ────────────────────────────────
                _buildRegionFilter(elderId),
                // ── Entries timeline ─────────────────────────────
                Expanded(child: _buildTimeline(elderId)),
              ],
            ),
    );
  }

  Widget _buildRegionFilter(String elderId) {
    return SizedBox(
      height: 44,
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _firestore.getWoundEntriesStream(elderId),
        builder: (context, snapshot) {
          final entries = snapshot.data ?? [];
          final regionCounts = <String, int>{};
          for (final e in entries) {
            final region = e['bodyRegion'] as String? ?? 'other';
            regionCounts[region] = (regionCounts[region] ?? 0) + 1;
          }

          return ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            children: [
              _filterChip('all', 'All (${entries.length})'),
              ...regionCounts.entries.map((e) {
                final region = BodyRegion.fromId(e.key);
                return _filterChip(
                    e.key, '${region.icon} ${region.label} (${e.value})');
              }),
            ],
          );
        },
      ),
    );
  }

  Widget _filterChip(String key, String label) {
    final isSelected = _regionFilter == key;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        selected: isSelected,
        label: Text(label, style: const TextStyle(fontSize: 12)),
        selectedColor: AppTheme.statusRed.withValues(alpha: 0.15),
        backgroundColor: Colors.grey.shade100,
        onSelected: (_) => setState(() => _regionFilter = key),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusXL)),
      ),
    );
  }

  Widget _buildTimeline(String elderId) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _firestore.getWoundEntriesStream(elderId),
      builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Something went wrong.',
                      style: TextStyle(color: Colors.red)));
                }
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: List.generate(3, (_) => const SkeletonListTile()),
            ),
          );
        }

        final allEntries = (snapshot.data ?? [])
            .map((raw) => WoundEntry.fromFirestore(
                raw['id'] as String? ?? '', raw))
            .toList();

        final entries = _regionFilter == 'all'
            ? allEntries
            : allEntries
                .where((e) => e.bodyRegion == _regionFilter)
                .toList();

        if (entries.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.healing_outlined,
            title: 'No wound photos yet',
            subtitle: 'Document conditions for your care team.',
          );
        }

        // Show healing timeline when a specific region is filtered.
        final showTimeline =
            _regionFilter != 'all' && entries.length >= 2;

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: entries.length + (showTimeline ? 1 : 0),
          itemBuilder: (_, i) {
            if (showTimeline && i == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _WoundHealingTimeline(entries: entries),
              );
            }
            final idx = showTimeline ? i - 1 : i;
            return _buildWoundCard(entries[idx], allEntries);
          },
        );
      },
    );
  }

  Widget _buildWoundCard(
      WoundEntry entry, List<WoundEntry> allEntries) {
    final region = entry.region;
    final dateStr = entry.createdAt != null
        ? DateFormat('MMM d, yyyy').format(entry.createdAt!.toDate())
        : '';

    // Check if comparison is possible
    final hasLinked = entry.linkedEntryId != null &&
        entry.linkedEntryId!.isNotEmpty;
    final sameRegionEntries =
        allEntries.where((e) => e.bodyRegion == entry.bodyRegion).toList();
    final canCompare = hasLinked || sameRegionEntries.length > 1;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusM)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusS),
              child: entry.photoUrl.isNotEmpty
                  ? CachedImage(imageUrl: entry.photoUrl,
                      width: 80, height: 80, fit: BoxFit.cover)
                  : Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.image, color: Colors.grey)),
            ),
            const SizedBox(width: 12),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.title,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      // Body region chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.tileBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('${region.icon} ${region.label}',
                            style: const TextStyle(fontSize: 10)),
                      ),
                      const SizedBox(width: 6),
                      // Severity badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: entry.severityColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(entry.severityLabel,
                            style: TextStyle(
                                fontSize: 10,
                                color: entry.severityColor,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(entry.woundType,
                      style: TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary)),
                  if (entry.notes != null && entry.notes!.isNotEmpty)
                    Text(entry.notes!,
                        style: TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text('$dateStr \u00B7 by ${entry.uploadedByName}',
                          style: TextStyle(
                              fontSize: 11, color: AppTheme.textLight)),
                      const Spacer(),
                      if (canCompare)
                        GestureDetector(
                          onTap: () =>
                              _showComparison(entry, sameRegionEntries),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.compare_arrows,
                                  size: 14,
                                  color: AppTheme.primaryColor),
                              const SizedBox(width: 2),
                              Text('Compare',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.primaryColor,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Before/After comparison ─────────────────────────────────────

  void _showComparison(
      WoundEntry current, List<WoundEntry> sameRegion) {
    // Find the linked entry, or the most recent different entry.
    WoundEntry? before;
    if (current.linkedEntryId != null) {
      before = sameRegion
          .where((e) => e.id == current.linkedEntryId)
          .firstOrNull;
    }
    before ??= sameRegion
        .where((e) =>
            e.id != current.id &&
            (e.createdAt?.toDate().isBefore(
                        current.createdAt?.toDate() ?? DateTime.now()) ??
                false))
        .firstOrNull;

    if (before == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No earlier photo to compare with.')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ComparisonSheet(before: before!, after: current),
    );
  }
}

// ── Comparison Sheet ──────────────────────────────────────────────

class _ComparisonSheet extends StatelessWidget {
  const _ComparisonSheet({required this.before, required this.after});
  final WoundEntry before;
  final WoundEntry after;

  String get _delta {
    const levels = ['mild', 'moderate', 'severe'];
    final beforeIdx = levels.indexOf(before.severity);
    final afterIdx = levels.indexOf(after.severity);
    if (afterIdx < beforeIdx) return 'Improving';
    if (afterIdx > beforeIdx) return 'Worsening';
    return 'Stable';
  }

  Color get _deltaColor {
    final d = _delta;
    if (d == 'Improving') return AppTheme.statusGreen;
    if (d == 'Worsening') return AppTheme.statusRed;
    return Colors.grey;
  }

  String get _deltaIcon {
    final d = _delta;
    if (d == 'Improving') return '\u2713';
    if (d == 'Worsening') return '\u26A0';
    return '\u2192';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('$_deltaIcon $_delta',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _deltaColor,
                    )),
              ],
            ),
            const SizedBox(height: 16),
            // Side by side photos
            Row(
              children: [
                Expanded(child: _photoColumn('Before', before)),
                const SizedBox(width: 12),
                Expanded(child: _photoColumn('After', after)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _photoColumn(String label, WoundEntry entry) {
    final dateStr = entry.createdAt != null
        ? DateFormat('MMM d').format(entry.createdAt!.toDate())
        : '';
    return Column(
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          child: AspectRatio(
            aspectRatio: 1,
            child: entry.photoUrl.isNotEmpty
                ? CachedImage(imageUrl: entry.photoUrl, fit: BoxFit.cover)
                : Container(color: Colors.grey.shade200),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: entry.severityColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(entry.severityLabel,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: entry.severityColor)),
        ),
        Text(dateStr,
            style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}

// ── Metadata Form ─────────────────────────────────────────────────

class _WoundMetadataForm extends StatefulWidget {
  const _WoundMetadataForm({
    required this.imageFile,
    required this.fileName,
    required this.firestore,
  });
  final File imageFile;
  final String fileName;
  final FirestoreService firestore;

  @override
  State<_WoundMetadataForm> createState() => _WoundMetadataFormState();
}

class _WoundMetadataFormState extends State<_WoundMetadataForm> {
  final _titleCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String? _selectedRegion;
  String? _selectedWoundType;
  String? _selectedSeverity;
  bool _isSaving = false;

  bool get _canSave =>
      _titleCtrl.text.trim().isNotEmpty &&
      _selectedRegion != null &&
      _selectedWoundType != null &&
      _selectedSeverity != null;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_canSave) return;
    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final elderId =
          context.read<ActiveElderProvider>().activeElder?.id ?? '';
      if (elderId.isEmpty) return;

      // Upload photo
      final ts = DateTime.now().millisecondsSinceEpoch;
      final storagePath =
          'wound_photos/$elderId/$_selectedRegion/${ts}_${widget.fileName}';
      final ref = FirebaseStorage.instance.ref().child(storagePath);
      await ref.putFile(widget.imageFile);
      final downloadUrl = await ref.getDownloadURL();

      // Create Firestore entry
      final data = WoundEntry(
        photoUrl: downloadUrl,
        storagePath: storagePath,
        title: _titleCtrl.text.trim(),
        bodyRegion: _selectedRegion!,
        woundType: _selectedWoundType!,
        severity: _selectedSeverity!,
        notes: _notesCtrl.text.trim().isEmpty
            ? null
            : _notesCtrl.text.trim(),
        elderId: elderId,
        uploadedBy: user.uid,
        uploadedByName: user.displayName ?? user.email ?? 'Unknown',
      ).toFirestore();

      await widget.firestore.addWoundEntry(elderId, data);
      HapticUtils.success();

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Wound photo saved.'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      debugPrint('Wound upload error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to save. Please try again.'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 12),
          const Text('Document Wound / Condition',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          // Photo preview
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
            child: Image.file(widget.imageFile,
                height: 180, width: double.infinity, fit: BoxFit.cover),
          ),
          const SizedBox(height: 16),

          // Title
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(
              labelText: 'Title *',
              border: OutlineInputBorder(),
              hintText: 'e.g., Left heel pressure sore',
            ),
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),

          // Body region
          const Text('Body Region *',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: WoundEntry.kBodyRegions.map((r) {
              final isSelected = _selectedRegion == r.id;
              return GestureDetector(
                onTap: () => setState(() => _selectedRegion = r.id),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.statusRed.withValues(alpha: 0.1)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(AppTheme.radiusS),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.statusRed
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Text('${r.icon} ${r.label}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected
                            ? AppTheme.statusRed
                            : null,
                      )),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Wound type
          DropdownButtonFormField<String>(
            value: _selectedWoundType,
            decoration: const InputDecoration(
              labelText: 'Wound Type *',
              border: OutlineInputBorder(),
            ),
            items: WoundEntry.kWoundTypes
                .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                .toList(),
            onChanged: (v) => setState(() => _selectedWoundType = v),
          ),
          const SizedBox(height: 16),

          // Severity
          const Text('Severity *',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: [
              _severityChip('mild', 'Mild', AppTheme.statusGreen),
              const SizedBox(width: 8),
              _severityChip('moderate', 'Moderate', AppTheme.tileOrange),
              const SizedBox(width: 8),
              _severityChip('severe', 'Severe', AppTheme.statusRed),
            ],
          ),
          const SizedBox(height: 16),

          // Notes
          TextField(
            controller: _notesCtrl,
            decoration: const InputDecoration(
              labelText: 'Clinical notes (optional)',
              border: OutlineInputBorder(),
              hintText: 'Size, color, drainage, edges...',
            ),
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 20),

          // Save button
          ElevatedButton(
            onPressed: _canSave && !_isSaving ? _handleSave : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.statusRed,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusM)),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('Save',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _severityChip(String value, String label, Color color) {
    final isSelected = _selectedSeverity == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedSeverity = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.15)
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(AppTheme.radiusS),
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade300,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          alignment: Alignment.center,
          child: Text(label,
              style: TextStyle(
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? color : Colors.grey.shade600,
              )),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Wound healing timeline — horizontal dot + arrow visualization showing
// severity progression for a specific body region.
// ---------------------------------------------------------------------------

class _WoundHealingTimeline extends StatelessWidget {
  const _WoundHealingTimeline({required this.entries});
  final List<WoundEntry> entries;

  static int _severityRank(String severity) {
    switch (severity) {
      case 'mild':
        return 1;
      case 'moderate':
        return 2;
      case 'severe':
        return 3;
      default:
        return 0;
    }
  }

  static Color _dotColor(String severity) {
    switch (severity) {
      case 'mild':
        return AppTheme.statusGreen;
      case 'moderate':
        return AppTheme.statusAmber;
      case 'severe':
        return AppTheme.statusRed;
      default:
        return AppTheme.textLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Sort oldest → newest.
    final sorted = entries.toList()
      ..sort((a, b) {
        final aMs = a.createdAt?.millisecondsSinceEpoch ?? 0;
        final bMs = b.createdAt?.millisecondsSinceEpoch ?? 0;
        return aMs.compareTo(bMs);
      });

    if (sorted.length < 2) return const SizedBox.shrink();

    final region = sorted.first.region;
    final dateFmt = DateFormat('MMM d');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.backgroundGray,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(color: AppTheme.textLight.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('${region.icon} ',
                  style: const TextStyle(fontSize: 14)),
              Text(
                '${region.label} Healing Timeline',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '${sorted.length} entries',
                style: TextStyle(
                    fontSize: 11, color: AppTheme.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Scrollable timeline row.
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (int i = 0; i < sorted.length; i++) ...[
                  _TimelineDot(
                    entry: sorted[i],
                    dateFmt: dateFmt,
                  ),
                  if (i < sorted.length - 1)
                    _TimelineArrow(
                      fromSeverity: sorted[i].severity,
                      toSeverity: sorted[i + 1].severity,
                    ),
                ],
              ],
            ),
          ),
          // Legend
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendDot(AppTheme.statusGreen, 'Improving'),
              const SizedBox(width: 12),
              _legendDot(AppTheme.statusAmber, 'Stable'),
              const SizedBox(width: 12),
              _legendDot(AppTheme.statusRed, 'Worsening'),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
      ],
    );
  }
}

class _TimelineDot extends StatelessWidget {
  const _TimelineDot({required this.entry, required this.dateFmt});
  final WoundEntry entry;
  final DateFormat dateFmt;

  @override
  Widget build(BuildContext context) {
    final color = _WoundHealingTimeline._dotColor(entry.severity);
    final dateStr = entry.createdAt != null
        ? dateFmt.format(entry.createdAt!.toDate())
        : '?';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 4,
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          entry.severityLabel,
          style: TextStyle(
              fontSize: 9, fontWeight: FontWeight.w600, color: color),
        ),
        Text(
          dateStr,
          style: TextStyle(fontSize: 9, color: AppTheme.textSecondary),
        ),
      ],
    );
  }
}

class _TimelineArrow extends StatelessWidget {
  const _TimelineArrow({
    required this.fromSeverity,
    required this.toSeverity,
  });
  final String fromSeverity;
  final String toSeverity;

  @override
  Widget build(BuildContext context) {
    final fromRank = _WoundHealingTimeline._severityRank(fromSeverity);
    final toRank = _WoundHealingTimeline._severityRank(toSeverity);

    Color color;
    String arrow;
    if (toRank < fromRank) {
      color = AppTheme.statusGreen;
      arrow = '\u2191'; // ↑ improving
    } else if (toRank > fromRank) {
      color = AppTheme.statusRed;
      arrow = '\u2193'; // ↓ worsening
    } else {
      color = AppTheme.statusAmber;
      arrow = '\u2192'; // → stable
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 20), // align with dot center
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 24,
            height: 2,
            color: color.withValues(alpha: 0.4),
          ),
          Text(
            arrow,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Container(
            width: 24,
            height: 2,
            color: color.withValues(alpha: 0.4),
          ),
        ],
      ),
    );
  }
}
