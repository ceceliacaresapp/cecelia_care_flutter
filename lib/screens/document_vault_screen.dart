// lib/screens/document_vault_screen.dart
//
// Legal & financial document vault. Upload POA, advance directives,
// insurance cards, medical records. Category tags, share, view.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

import 'package:cecelia_care_flutter/models/vault_document.dart';
import 'package:cecelia_care_flutter/providers/active_elder_provider.dart';
import 'package:cecelia_care_flutter/services/firestore_service.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';
import 'package:cecelia_care_flutter/utils/haptic_utils.dart';

class DocumentVaultScreen extends StatefulWidget {
  const DocumentVaultScreen({super.key});

  @override
  State<DocumentVaultScreen> createState() => _DocumentVaultScreenState();
}

class _DocumentVaultScreenState extends State<DocumentVaultScreen> {
  String? _filterCategory; // null = show all

  @override
  Widget build(BuildContext context) {
    final elder =
        context.watch<ActiveElderProvider>().activeElder;
    if (elder == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Document Vault')),
        body: const Center(
            child: Text('No care recipient selected.')),
      );
    }

    final fs = context.read<FirestoreService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Document Vault'),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryColor,
                AppTheme.primaryColor.withValues(alpha: 0.82),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showPickerSheet(context, elder.id),
        backgroundColor: AppTheme.tileIndigo,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: fs.getVaultDocumentsStream(elder.id),
        builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Something went wrong.',
                      style: TextStyle(color: Colors.red)));
                }
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final rawDocs = snapshot.data ?? [];
          final allDocs = rawDocs
              .map((m) =>
                  VaultDocument.fromFirestore(m['id'] as String, m))
              .toList();

          if (allDocs.isEmpty) {
            return _EmptyState();
          }

          // Build category counts for filter chips
          final catCounts = <String, int>{};
          for (final doc in allDocs) {
            catCounts[doc.category] =
                (catCounts[doc.category] ?? 0) + 1;
          }

          final filtered = _filterCategory == null
              ? allDocs
              : allDocs
                  .where((d) => d.category == _filterCategory)
                  .toList();

          return Column(
            children: [
              // Category filter chips
              _CategoryFilterBar(
                counts: catCounts,
                selected: _filterCategory,
                totalCount: allDocs.length,
                onSelect: (cat) =>
                    setState(() => _filterCategory = cat),
              ),
              const Divider(height: 1),

              // Document list
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text(
                          'No documents in this category.',
                          style: TextStyle(
                              color: AppTheme.textSecondary),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                            16, 12, 16, 80),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, i) => _DocCard(
                          doc: filtered[i],
                          onTap: () =>
                              _viewDocument(context, filtered[i]),
                          onLongPress: () => _showDocActions(
                              context, elder.id, filtered[i]),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Source picker ───────────────────────────────────────────────
  void _showPickerSheet(BuildContext context, String elderId) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined,
                  color: AppTheme.tileIndigo),
              title: const Text('Take photo'),
              subtitle: const Text(
                  'Photograph a document with your camera'),
              onTap: () {
                Navigator.of(ctx).pop();
                _pickAndUpload(context, elderId, _PickSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: AppTheme.tileIndigo),
              title: const Text('Choose from gallery'),
              subtitle: const Text('Select an image from your photos'),
              onTap: () {
                Navigator.of(ctx).pop();
                _pickAndUpload(
                    context, elderId, _PickSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.upload_file_outlined,
                  color: AppTheme.tileIndigo),
              title: const Text('Upload file'),
              subtitle:
                  const Text('Select a PDF or image from files'),
              onTap: () {
                Navigator.of(ctx).pop();
                _pickAndUpload(context, elderId, _PickSource.file);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── Pick file + show upload form ────────────────────────────────
  Future<void> _pickAndUpload(
    BuildContext context,
    String elderId,
    _PickSource source,
  ) async {
    String? filePath;
    String? fileName;
    String? mimeType;

    try {
      if (source == _PickSource.camera ||
          source == _PickSource.gallery) {
        final picker = ImagePicker();
        final image = await picker.pickImage(
          source: source == _PickSource.camera
              ? ImageSource.camera
              : ImageSource.gallery,
          imageQuality: 85,
        );
        if (image == null) return;
        filePath = image.path;
        fileName = image.name;
        mimeType = image.mimeType ?? 'image/jpeg';
      } else {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        );
        if (result == null || result.files.isEmpty) return;
        final pf = result.files.first;
        if (pf.path == null) return;
        filePath = pf.path!;
        fileName = pf.name;
        final ext = pf.extension?.toLowerCase() ?? '';
        if (ext == 'pdf') {
          mimeType = 'application/pdf';
        } else {
          mimeType = 'image/$ext';
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not pick file: $e')),
        );
      }
      return;
    }

    if (filePath == null || fileName == null) return;
    if (!mounted) return;

    // Show upload form
    _showUploadForm(
      context,
      elderId: elderId,
      filePath: filePath,
      fileName: fileName,
      mimeType: mimeType ?? 'application/octet-stream',
    );
  }

  // ── Upload form dialog ──────────────────────────────────────────
  void _showUploadForm(
    BuildContext context, {
    required String elderId,
    required String filePath,
    required String fileName,
    required String mimeType,
  }) {
    final nameCtrl = TextEditingController(
      text: fileName.replaceAll(RegExp(r'\.[^.]+$'), ''),
    );
    String selectedCategory = 'Other';
    final notesCtrl = TextEditingController();
    bool isUploading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(builder: (ctx, setSheetState) {
          final cat = VaultCategory.fromName(selectedCategory);

          return Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            decoration: BoxDecoration(
              color: Theme.of(ctx).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    Icon(
                      mimeType.startsWith('image/')
                          ? Icons.image_outlined
                          : Icons.picture_as_pdf_outlined,
                      color: cat.color,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Upload Document',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: cat.color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // File preview row
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundGray,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      if (mimeType.startsWith('image/'))
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.file(
                            File(filePath),
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                          ),
                        )
                      else
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppTheme.statusRed
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                              Icons.picture_as_pdf,
                              color: AppTheme.statusRed,
                              size: 24),
                        ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          fileName,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Name
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Document name',
                    hintText: "e.g., Mom's POA - 2024",
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),

                // Category picker
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    prefixIcon:
                        Icon(cat.icon, color: cat.color, size: 20),
                  ),
                  items: VaultCategory.all.map((vc) {
                    return DropdownMenuItem(
                      value: vc.name,
                      child: Text(vc.name, style: const TextStyle(fontSize: 14)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setSheetState(() => selectedCategory = val);
                    }
                  },
                ),
                const SizedBox(height: 12),

                // Notes
                TextField(
                  controller: notesCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Notes (optional)',
                    hintText:
                        'e.g., Signed by attorney, expires 2027',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 16),

                // Upload button
                SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: isUploading
                        ? null
                        : () async {
                            final name = nameCtrl.text.trim();
                            if (name.isEmpty) return;
                            setSheetState(
                                () => isUploading = true);

                            try {
                              await _performUpload(
                                elderId: elderId,
                                filePath: filePath,
                                fileName: fileName,
                                mimeType: mimeType,
                                docName: name,
                                category: selectedCategory,
                                notes: notesCtrl.text.trim(),
                              );
                              if (ctx.mounted) {
                                Navigator.of(ctx).pop();
                              }
                              if (mounted) {
                                HapticUtils.success();
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        '"$name" uploaded'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (ctx.mounted) {
                                setSheetState(
                                    () => isUploading = false);
                                ScaffoldMessenger.of(ctx)
                                    .showSnackBar(
                                  SnackBar(
                                    content:
                                        Text('Upload failed: $e'),
                                    backgroundColor:
                                        AppTheme.dangerColor,
                                  ),
                                );
                              }
                            }
                          },
                    icon: isUploading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white))
                        : const Icon(Icons.cloud_upload_outlined,
                            size: 18),
                    label: Text(
                      isUploading ? 'Uploading…' : 'Upload',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cat.color,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  // ── Perform the actual upload ───────────────────────────────────
  Future<void> _performUpload({
    required String elderId,
    required String filePath,
    required String fileName,
    required String mimeType,
    required String docName,
    required String category,
    required String notes,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Not logged in');

    final slug = VaultCategory.fromName(category).slug;
    final ts = DateTime.now().millisecondsSinceEpoch;
    final storagePath = 'elder_documents/$elderId/$slug/${ts}_$fileName';

    // Upload to Firebase Storage
    final storageRef = FirebaseStorage.instance.ref().child(storagePath);
    await storageRef.putFile(File(filePath));
    final downloadUrl = await storageRef.getDownloadURL();

    // Get file size
    final file = File(filePath);
    final fileSize = await file.length();

    // Resolve display name
    String displayName = user.displayName ?? '';
    if (displayName.isEmpty) {
      displayName = user.email?.split('@').first ?? 'Unknown';
    }

    // Create Firestore doc
    final fs = context.read<FirestoreService>();
    await fs.addVaultDocument(elderId, {
      'name': docName,
      'category': category,
      'notes': notes.isNotEmpty ? notes : null,
      'fileUrl': downloadUrl,
      'storagePath': storagePath,
      'mimeType': mimeType,
      'fileSize': fileSize,
      'uploadedBy': user.uid,
      'uploadedByName': displayName,
      'elderId': elderId,
    });
  }

  // ── View document ───────────────────────────────────────────────
  void _viewDocument(BuildContext context, VaultDocument doc) {
    if (doc.isImage) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text(doc.name)),
          body: Center(
            child: InteractiveViewer(
              child: Image.network(
                doc.fileUrl,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.broken_image_outlined,
                  size: 48,
                  color: AppTheme.textLight,
                ),
              ),
            ),
          ),
        ),
      ));
    } else {
      // Open PDF or other files in external viewer
      launchUrl(
        Uri.parse(doc.fileUrl),
        mode: LaunchMode.externalApplication,
      );
    }
  }

  // ── Long-press actions ──────────────────────────────────────────
  void _showDocActions(
    BuildContext context,
    String elderId,
    VaultDocument doc,
  ) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final elderProv = context.read<ActiveElderProvider>();
    final isAdmin =
        elderProv.activeElder?.primaryAdminUserId == currentUid;
    final isOwner = doc.uploadedBy == currentUid;
    final canDelete = isAdmin || isOwner;

    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.share_outlined,
                  color: doc.categoryInfo.color),
              title: const Text('Share'),
              onTap: () {
                Navigator.of(ctx).pop();
                _shareDocument(context, doc);
              },
            ),
            ListTile(
              leading: Icon(Icons.edit_outlined,
                  color: doc.categoryInfo.color),
              title: const Text('Edit details'),
              onTap: () {
                Navigator.of(ctx).pop();
                _showEditForm(context, elderId, doc);
              },
            ),
            if (canDelete)
              ListTile(
                leading: const Icon(Icons.delete_outline,
                    color: AppTheme.dangerColor),
                title: const Text('Delete',
                    style: TextStyle(color: AppTheme.dangerColor)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _confirmDelete(context, elderId, doc);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── Share ───────────────────────────────────────────────────────
  Future<void> _shareDocument(
    BuildContext context,
    VaultDocument doc,
  ) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preparing to share…')),
      );

      // Download to temp dir
      final tempDir = await getTemporaryDirectory();
      final ext = doc.isPdf
          ? '.pdf'
          : doc.mimeType?.contains('png') == true
              ? '.png'
              : '.jpg';
      final tempFile =
          File('${tempDir.path}/${doc.name.replaceAll(RegExp(r'[^\w\-.]'), '_')}$ext');

      final response = await http.get(Uri.parse(doc.fileUrl));
      await tempFile.writeAsBytes(response.bodyBytes);

      await Share.shareXFiles(
        [XFile(tempFile.path)],
        subject: doc.name,
        text: doc.notes,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not share: $e')),
        );
      }
    }
  }

  // ── Edit form ───────────────────────────────────────────────────
  void _showEditForm(
    BuildContext context,
    String elderId,
    VaultDocument doc,
  ) {
    final nameCtrl = TextEditingController(text: doc.name);
    String selectedCategory = doc.category;
    final notesCtrl = TextEditingController(text: doc.notes ?? '');
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(builder: (ctx, setSheetState) {
          final cat = VaultCategory.fromName(selectedCategory);
          return Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            decoration: BoxDecoration(
              color: Theme.of(ctx).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Edit Document',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: cat.color,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Document name',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    prefixIcon:
                        Icon(cat.icon, color: cat.color, size: 20),
                  ),
                  items: VaultCategory.all.map((vc) {
                    return DropdownMenuItem(
                      value: vc.name,
                      child: Text(vc.name,
                          style: const TextStyle(fontSize: 14)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setSheetState(() => selectedCategory = val);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Notes (optional)',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: isSaving
                        ? null
                        : () async {
                            final name = nameCtrl.text.trim();
                            if (name.isEmpty || doc.id == null) return;
                            setSheetState(() => isSaving = true);
                            try {
                              await context
                                  .read<FirestoreService>()
                                  .updateVaultDocument(
                                      elderId, doc.id!, {
                                'name': name,
                                'category': selectedCategory,
                                'notes': notesCtrl.text.trim().isNotEmpty
                                    ? notesCtrl.text.trim()
                                    : null,
                              });
                              if (ctx.mounted) Navigator.of(ctx).pop();
                            } catch (e) {
                              if (ctx.mounted) {
                                setSheetState(() => isSaving = false);
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(
                                      content: Text('Error: $e')),
                                );
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cat.color,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Save Changes',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  // ── Delete ──────────────────────────────────────────────────────
  Future<void> _confirmDelete(
    BuildContext context,
    String elderId,
    VaultDocument doc,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete "${doc.name}"?'),
        content: const Text(
            'This permanently removes the document and its file.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
                foregroundColor: AppTheme.dangerColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || doc.id == null) return;

    try {
      // Delete Storage file
      if (doc.storagePath.isNotEmpty) {
        try {
          await FirebaseStorage.instance
              .ref()
              .child(doc.storagePath)
              .delete();
        } catch (e) {
          debugPrint('Could not delete storage file: $e');
          // Continue — Firestore doc should still be deleted
        }
      }

      // Delete Firestore doc
      await context
          .read<FirestoreService>()
          .deleteVaultDocument(elderId, doc.id!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Document deleted'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not delete: $e')),
        );
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Pick source enum
// ---------------------------------------------------------------------------
enum _PickSource { camera, gallery, file }

// ---------------------------------------------------------------------------
// Category filter bar
// ---------------------------------------------------------------------------
class _CategoryFilterBar extends StatelessWidget {
  const _CategoryFilterBar({
    required this.counts,
    required this.selected,
    required this.totalCount,
    required this.onSelect,
  });

  final Map<String, int> counts;
  final String? selected;
  final int totalCount;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: [
          // "All" chip
          _FilterChip(
            label: 'All',
            count: totalCount,
            color: AppTheme.tileIndigo,
            isSelected: selected == null,
            onTap: () => onSelect(null),
          ),
          const SizedBox(width: 6),
          // Category chips (only for categories that have docs)
          ...counts.entries.map((entry) {
            final cat = VaultCategory.fromName(entry.key);
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: _FilterChip(
                label: entry.key,
                count: entry.value,
                color: cat.color,
                icon: cat.icon,
                isSelected: selected == entry.key,
                onTap: () => onSelect(entry.key),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.count,
    required this.color,
    this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final int count;
  final Color color;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : AppTheme.textLight.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 13, color: isSelected ? color : AppTheme.textLight),
              const SizedBox(width: 4),
            ],
            Text(
              label.length > 14 ? '${label.substring(0, 12)}…' : label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? color : AppTheme.textSecondary,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: isSelected ? color : AppTheme.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Document card
// ---------------------------------------------------------------------------
class _DocCard extends StatelessWidget {
  const _DocCard({
    required this.doc,
    required this.onTap,
    required this.onLongPress,
  });

  final VaultDocument doc;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final cat = doc.categoryInfo;
    final dateStr = doc.createdAt != null
        ? DateFormat('MMM d, y').format(doc.createdAt!.toDate())
        : '';

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cat.color.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cat.color.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            // Thumbnail / icon
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: doc.isImage
                    ? Colors.transparent
                    : cat.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              clipBehavior: Clip.antiAlias,
              child: doc.isImage
                  ? Image.network(
                      doc.fileUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Icon(cat.icon, color: cat.color, size: 24),
                    )
                  : doc.isPdf
                      ? const Icon(Icons.picture_as_pdf,
                          color: AppTheme.statusRed, size: 26)
                      : Icon(cat.icon, color: cat.color, size: 24),
            ),
            const SizedBox(width: 12),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doc.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      // Category badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: cat.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          doc.category,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: cat.color,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (doc.fileSizeLabel.isNotEmpty)
                        Text(
                          doc.fileSizeLabel,
                          style: TextStyle(
                            fontSize: 10,
                            color: AppTheme.textLight,
                          ),
                        ),
                    ],
                  ),
                  if (dateStr.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Uploaded $dateStr by ${doc.uploadedByName}',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppTheme.textLight,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            // Chevron
            Icon(Icons.chevron_right,
                size: 18, color: cat.color.withValues(alpha: 0.4)),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_special_outlined,
                size: 56, color: AppTheme.textLight),
            const SizedBox(height: 16),
            Text(
              'No documents yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Store power of attorney, insurance cards, advance '
              'directives, and other important documents here.\n\n'
              'Tap + to upload your first document.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textLight,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
