import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/active_elder_provider.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/journal_entry.dart';
import '../../models/entry_types.dart';
import '../../providers/journal_service_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/app_styles.dart';

const _kImageColor = Color(0xFF5C6BC0); // indigo — matches Care screen tile

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class ImageUploadScreen extends StatefulWidget {
  const ImageUploadScreen({super.key});

  @override
  State<ImageUploadScreen> createState() => _ImageUploadScreenState();
}

class _ImageUploadScreenState extends State<ImageUploadScreen> {
  late AppLocalizations _l10n;
  late ThemeData _theme;

  // ── Upload state ────────────────────────────────────────────────────────
  XFile? _pickedFile;
  bool _isUploading = false;
  String? _uploadError;
  String? _imageTitle;
  final TextEditingController _titleController = TextEditingController();

  // ── Folder state ────────────────────────────────────────────────────────
  // Selected folder for UPLOAD (null = no folder / Uncategorized)
  String? _selectedUploadFolderId;
  String? _selectedUploadFolderName;

  // Selected folder for GRID FILTER (null = show all)
  String? _filterFolderId;
  String? _filterFolderName;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _l10n = AppLocalizations.of(context)!;
    _theme = Theme.of(context);
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Image picking
  // ---------------------------------------------------------------------------

  Future<void> _pickImage(ImageSource source) async {
    setState(() {
      _pickedFile = null;
      _uploadError = null;
      _imageTitle = null;
    });
    final picker = ImagePicker();
    try {
      final file = await picker.pickImage(source: source);
      if (file != null) {
        setState(() {
          _pickedFile = file;
          _imageTitle = file.name;
          _titleController.text = file.name;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _uploadError = _l10n.imageUploadErrorPicking(e.toString()));
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Upload
  // ---------------------------------------------------------------------------

  Future<void> _uploadImage() async {
    if (_pickedFile == null) {
      if (mounted) setState(() => _uploadError = _l10n.imageUploadErrorNoFileSelected);
      return;
    }

    final elder = Provider.of<ActiveElderProvider>(context, listen: false).activeElder;
    final user = AuthService.currentUser;

    if (elder == null) {
      setState(() => _uploadError = _l10n.imageUploadErrorNoElderSelected);
      return;
    }
    if (user == null) {
      setState(() => _uploadError = _l10n.imageUploadErrorNotLoggedIn);
      return;
    }

    setState(() { _isUploading = true; _uploadError = null; });

    try {
      final elderId = elder.id;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${_pickedFile!.name}';
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('elder_images/$elderId/${_selectedUploadFolderId ?? 'uncategorized'}/$fileName');

      await storageRef.putFile(File(_pickedFile!.path));
      final downloadUrl = await storageRef.getDownloadURL();

      final journalServiceProvider =
          Provider.of<JournalServiceProvider>(context, listen: false);
      final now = DateTime.now();
      final dateString = DateFormat('yyyy-MM-dd').format(now);

      String loggedByDisplayName = user.displayName ?? '';
      if (loggedByDisplayName.isEmpty) {
        loggedByDisplayName = user.email ?? _l10n.formUnknownUser;
      }
      final String? loggedByAvatarUrl =
          await context.read<FirestoreService>().getAvatarUrl(user.uid);

      final imageData = <String, dynamic>{
        'url': downloadUrl,
        'storagePath':
            'elder_images/$elderId/${_selectedUploadFolderId ?? 'uncategorized'}/$fileName',
        'title': _imageTitle ?? _l10n.imageUploadDefaultTitle,
        'mimeType': _pickedFile!.mimeType,
        'size': await _pickedFile!.length(),
        'timestamp': FieldValue.serverTimestamp(),
        // Folder metadata embedded in the image data
        if (_selectedUploadFolderId != null) 'folderId': _selectedUploadFolderId,
        if (_selectedUploadFolderName != null) 'folderName': _selectedUploadFolderName,
      };

      final journalEntryPayload = <String, dynamic>{
        'elderId': elderId,
        'loggedByUserId': user.uid,
        'loggedByDisplayName': loggedByDisplayName,
        'loggedByUserAvatarUrl': loggedByAvatarUrl,
        'entryTimestamp': Timestamp.fromDate(now),
        'dateString': dateString,
        'text': _imageTitle ?? _l10n.imageUploadDefaultTitle,
        'data': imageData,
        'isPublic': true,
        'visibleToUserIds': elder.caregiverUserIds.toList(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'type': 'image',
      };

      await journalServiceProvider.addJournalEntry('image', journalEntryPayload, user.uid);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_l10n.imageUploadSuccess)));
        setState(() {
          _pickedFile = null;
          _imageTitle = null;
          _selectedUploadFolderId = null;
          _selectedUploadFolderName = null;
        });
        _titleController.clear();
      }
    } catch (e) {
      if (mounted) setState(() => _uploadError = _l10n.imageUploadErrorFailed(e.toString()));
      debugPrint('ImageUploadScreen: upload error: $e');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  // ---------------------------------------------------------------------------
  // Folder helpers
  // ---------------------------------------------------------------------------

  Future<void> _showCreateFolderDialog(String elderId) async {
    final ctrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New folder'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'e.g. Medications, Insurance, Lab Results',
            labelText: 'Folder name',
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: _kImageColor),
            child: const Text('Create', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (confirmed != true || ctrl.text.trim().isEmpty) return;
    try {
      final firestoreService = context.read<FirestoreService>();
      final newId = await firestoreService.createImageFolder(elderId, ctrl.text.trim());
      if (mounted) {
        setState(() {
          _selectedUploadFolderId = newId;
          _selectedUploadFolderName = ctrl.text.trim();
        });
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Folder "${ctrl.text.trim()}" created')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not create folder: $e'),
                backgroundColor: AppTheme.dangerColor));
      }
    }
  }

  Future<void> _confirmDeleteFolder(String elderId, String folderId, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete folder'),
        content: Text(
            'Delete "$name"?\n\nImages in this folder will not be deleted — they\'ll just become uncategorized.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.dangerColor),
            child: const Text('Delete folder'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await context.read<FirestoreService>().deleteImageFolder(elderId, folderId);
      if (mounted && _filterFolderId == folderId) {
        setState(() { _filterFolderId = null; _filterFolderName = null; });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not delete folder: $e')));
    }
  }

  void _showImageFullScreen(String imageUrl, String imageTitle) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: Text(imageTitle)),
        body: Center(
          child: InteractiveViewer(
            child: Image.network(imageUrl, fit: BoxFit.contain),
          ),
        ),
      ),
    ));
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final activeElder = Provider.of<ActiveElderProvider>(context).activeElder;

    if (activeElder == null) {
      return Scaffold(
        appBar: AppBar(title: Text(_l10n.imageUploadScreenTitle)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(_l10n.imageUploadErrorNoElderSelected,
                style: AppStyles.emptyStateText, textAlign: TextAlign.center),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(_l10n.imageUploadScreenTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Elder label ───────────────────────────────────────────────
            Text(
              _l10n.imageUploadForElder(activeElder.profileName),
              style: AppStyles.sectionTitle.copyWith(color: AppTheme.primaryColor),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 20),

            // ── Pick source buttons ───────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _PickerButton(
                    icon: Icons.photo_library_outlined,
                    label: _l10n.imageUploadButtonGallery,
                    onTap: () => _pickImage(ImageSource.gallery),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PickerButton(
                    icon: Icons.camera_alt_outlined,
                    label: _l10n.imageUploadButtonCamera,
                    onTap: () => _pickImage(ImageSource.camera),
                  ),
                ),
              ],
            ),

            // ── Preview + form ────────────────────────────────────────────
            if (_pickedFile != null) ...[
              const SizedBox(height: 20),
              Text(_l10n.imageUploadPreviewTitle,
                  style: _theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Container(
                height: 200,
                color: AppTheme.backgroundGray,
                alignment: Alignment.center,
                child: Image.file(File(_pickedFile!.path),
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) =>
                        Text(_l10n.imageUploadErrorLoadingPreview)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: _l10n.imageUploadLabelTitle,
                  hintText: _l10n.imageUploadHintTitle,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (v) => setState(() => _imageTitle = v),
              ),
              const SizedBox(height: 16),

              // ── Folder picker for upload ──────────────────────────────
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: context
                    .read<FirestoreService>()
                    .getImageFoldersStream(activeElder.id),
                builder: (context, snap) {
                  final folders = snap.data ?? [];
                  return _FolderPickerRow(
                    label: 'Save to folder',
                    folders: folders,
                    selectedFolderId: _selectedUploadFolderId,
                    selectedFolderName: _selectedUploadFolderName,
                    onSelect: (id, name) => setState(() {
                      _selectedUploadFolderId = id;
                      _selectedUploadFolderName = name;
                    }),
                    onCreateFolder: () => _showCreateFolderDialog(activeElder.id),
                  );
                },
              ),
              const SizedBox(height: 16),

              ElevatedButton.icon(
                onPressed: _isUploading ? null : _uploadImage,
                icon: _isUploading
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.cloud_upload_outlined),
                label: Text(_isUploading
                    ? _l10n.imageUploadStatusUploading
                    : _l10n.imageUploadButtonUpload),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kImageColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],

            if (_uploadError != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(_uploadError!,
                    style: const TextStyle(color: AppTheme.dangerColor),
                    textAlign: TextAlign.center),
              ),

            const SizedBox(height: 8),
            const Divider(height: 32),

            // ── Uploaded images section ───────────────────────────────────
            // Folder management + filter bar
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: context
                  .read<FirestoreService>()
                  .getImageFoldersStream(activeElder.id),
              builder: (context, folderSnap) {
                final folders = folderSnap.data ?? [];
                return _FolderFilterBar(
                  folders: folders,
                  selectedFolderId: _filterFolderId,
                  selectedFolderName: _filterFolderName,
                  elderId: activeElder.id,
                  onSelect: (id, name) =>
                      setState(() { _filterFolderId = id; _filterFolderName = name; }),
                  onCreateFolder: () => _showCreateFolderDialog(activeElder.id),
                  onDeleteFolder: (id, name) =>
                      _confirmDeleteFolder(activeElder.id, id, name),
                );
              },
            ),

            const SizedBox(height: 12),

            // ── Image grid ───────────────────────────────────────────────
            StreamBuilder<List<JournalEntry>>(
              stream: Provider.of<JournalServiceProvider>(context, listen: false)
                  .getJournalEntriesStream(
                    elderId: activeElder.id,
                    currentUserId: AuthService.currentUserId ?? '',
                    entryTypeFilter: 'image',
                  ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(_l10n.genericError(snapshot.error.toString()),
                        style: const TextStyle(color: AppTheme.dangerColor)));
                }

                var imageEntries = snapshot.data
                        ?.where((e) => e.type == EntryType.image)
                        .toList() ??
                    [];

                // Apply folder filter
                if (_filterFolderId != null) {
                  imageEntries = imageEntries
                      .where((e) => e.data?['folderId'] == _filterFolderId)
                      .toList();
                }

                if (imageEntries.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.photo_library_outlined,
                              size: 48, color: _kImageColor.withOpacity(0.4)),
                          const SizedBox(height: 12),
                          Text(
                            _filterFolderId != null
                                ? 'No images in "${_filterFolderName ?? 'this folder'}" yet.'
                                : _l10n.noImagesUploadedYet,
                            style: AppStyles.emptyStateText.copyWith(fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.78,
                  ),
                  itemCount: imageEntries.length,
                  itemBuilder: (context, index) {
                    final entry = imageEntries[index];
                    final imageUrl = entry.data?['url'] as String? ?? '';
                    final imageTitle =
                        entry.data?['title'] as String? ?? _l10n.imageUploadDefaultTitle;
                    final folderName = entry.data?['folderName'] as String?;
                    final uploadDate = entry.entryTimestamp.toDate();

                    if (imageUrl.isEmpty) {
                      return Container(
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundGray,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                            child: Text(_l10n.imageUnavailable,
                                textAlign: TextAlign.center)),
                      );
                    }

                    return GestureDetector(
                      onTap: () => _showImageFullScreen(imageUrl, imageTitle),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _kImageColor.withOpacity(0.2)),
                          boxShadow: [
                            BoxShadow(
                              color: _kImageColor.withOpacity(0.08),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                loadingBuilder: (_, child, progress) {
                                  if (progress == null) return child;
                                  return Center(
                                    child: CircularProgressIndicator(
                                      value: progress.expectedTotalBytes != null
                                          ? progress.cumulativeBytesLoaded /
                                              progress.expectedTotalBytes!
                                          : null,
                                    ),
                                  );
                                },
                                errorBuilder: (_, __, ___) => Container(
                                  color: AppTheme.backgroundGray,
                                  child: const Center(
                                    child: Icon(Icons.broken_image,
                                        color: AppTheme.textLight, size: 40),
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(imageTitle,
                                      style: _theme.textTheme.bodyMedium
                                          ?.copyWith(fontWeight: FontWeight.bold),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          DateFormat.yMMMd(_l10n.localeName)
                                              .format(uploadDate),
                                          style: _theme.textTheme.bodySmall,
                                        ),
                                      ),
                                      if (folderName != null)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 5, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: _kImageColor.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            folderName,
                                            style: TextStyle(
                                              fontSize: 9,
                                              color: _kImageColor,
                                              fontWeight: FontWeight.w600,
                                            ),
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
                  },
                );
              },
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _FolderPickerRow — inline folder selector for the upload form
// ---------------------------------------------------------------------------

class _FolderPickerRow extends StatelessWidget {
  const _FolderPickerRow({
    required this.label,
    required this.folders,
    required this.selectedFolderId,
    required this.selectedFolderName,
    required this.onSelect,
    required this.onCreateFolder,
  });

  final String label;
  final List<Map<String, dynamic>> folders;
  final String? selectedFolderId;
  final String? selectedFolderName;
  final void Function(String? id, String? name) onSelect;
  final VoidCallback onCreateFolder;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.folder_outlined, size: 14, color: _kImageColor),
            const SizedBox(width: 5),
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
                color: _kImageColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // "No folder" chip
            _FolderChip(
              label: 'None',
              isSelected: selectedFolderId == null,
              onTap: () => onSelect(null, null),
            ),
            // Existing folder chips
            for (final f in folders)
              _FolderChip(
                label: f['name'] as String? ?? '',
                isSelected: selectedFolderId == f['id'],
                onTap: () => onSelect(f['id'] as String, f['name'] as String?),
              ),
            // Create new folder
            GestureDetector(
              onTap: onCreateFolder,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: _kImageColor.withOpacity(0.4),
                      style: BorderStyle.solid),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, size: 14, color: _kImageColor.withOpacity(0.8)),
                    const SizedBox(width: 4),
                    Text('New folder',
                        style: TextStyle(
                            fontSize: 12,
                            color: _kImageColor.withOpacity(0.8),
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// _FolderFilterBar — folder filter strip above the image grid
// ---------------------------------------------------------------------------

class _FolderFilterBar extends StatelessWidget {
  const _FolderFilterBar({
    required this.folders,
    required this.selectedFolderId,
    required this.selectedFolderName,
    required this.elderId,
    required this.onSelect,
    required this.onCreateFolder,
    required this.onDeleteFolder,
  });

  final List<Map<String, dynamic>> folders;
  final String? selectedFolderId;
  final String? selectedFolderName;
  final String elderId;
  final void Function(String? id, String? name) onSelect;
  final VoidCallback onCreateFolder;
  final void Function(String id, String name) onDeleteFolder;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.collections_outlined, color: _kImageColor, size: 16),
            const SizedBox(width: 6),
            const Text(
              'UPLOADED IMAGES',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
                color: _kImageColor,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: onCreateFolder,
              icon: const Icon(Icons.create_new_folder_outlined, size: 14),
              label: const Text('New folder', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(
                foregroundColor: _kImageColor,
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
        if (folders.isNotEmpty) ...[
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // "All" chip
                _FolderChip(
                  label: 'All',
                  isSelected: selectedFolderId == null,
                  onTap: () => onSelect(null, null),
                ),
                const SizedBox(width: 8),
                for (final f in folders) ...[
                  GestureDetector(
                    onLongPress: () => onDeleteFolder(
                        f['id'] as String, f['name'] as String? ?? ''),
                    child: _FolderChip(
                      label: f['name'] as String? ?? '',
                      isSelected: selectedFolderId == f['id'],
                      onTap: () =>
                          onSelect(f['id'] as String, f['name'] as String?),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Long-press a folder chip to delete it',
            style: TextStyle(
                fontSize: 10, color: AppTheme.textLight, fontStyle: FontStyle.italic),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// _FolderChip
// ---------------------------------------------------------------------------

class _FolderChip extends StatelessWidget {
  const _FolderChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 130),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? _kImageColor : _kImageColor.withOpacity(0.07),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? _kImageColor : _kImageColor.withOpacity(0.25),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? Icons.folder : Icons.folder_outlined,
              size: 12,
              color: isSelected ? Colors.white : _kImageColor,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : _kImageColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _PickerButton — styled source picker for gallery / camera
// ---------------------------------------------------------------------------

class _PickerButton extends StatelessWidget {
  const _PickerButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: _kImageColor.withOpacity(0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kImageColor.withOpacity(0.25)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: _kImageColor, size: 28),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _kImageColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
