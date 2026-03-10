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
import '../../models/journal_entry.dart';
import '../../providers/journal_service_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/app_styles.dart';

class ImageUploadScreen extends StatefulWidget {
  const ImageUploadScreen({super.key});

  @override
  State<ImageUploadScreen> createState() => _ImageUploadScreenState();
}

class _ImageUploadScreenState extends State<ImageUploadScreen> {
  late AppLocalizations _l10n;
  late ThemeData _theme;

  XFile? _pickedFile;
  bool _isUploading = false;
  String? _uploadError;
  String? _imageTitle;
  final TextEditingController _titleController = TextEditingController();

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

  Future<void> _pickImage(ImageSource source) async {
    setState(() {
      _pickedFile = null;
      _uploadError = null;
      _imageTitle = null;
    });

    final ImagePicker picker = ImagePicker();
    try {
      final XFile? file = await picker.pickImage(source: source);
      if (file != null) {
        setState(() {
          _pickedFile = file;
          _imageTitle = file.name;
          _titleController.text = file.name;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _uploadError = _l10n.imageUploadErrorPicking(e.toString());
        });
      }
      debugPrint('Error picking image: $e');
    }
  }

  Future<void> _uploadImage() async {
    if (_pickedFile == null) {
      if (mounted) {
        setState(() {
          _uploadError = _l10n.imageUploadErrorNoFileSelected;
        });
      }
      return;
    }

    final activeElderProvider =
        Provider.of<ActiveElderProvider>(context, listen: false);
    final currentElder = activeElderProvider.activeElder;
    final currentUser = AuthService.currentUser;

    if (currentElder == null) {
      if (mounted) {
        setState(() {
          _uploadError = _l10n.imageUploadErrorNoElderSelected;
        });
      }
      return;
    }
    if (currentUser == null) {
      if (mounted) {
        setState(() {
          _uploadError = _l10n.imageUploadErrorNotLoggedIn;
        });
      }
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadError = null;
    });

    try {
      final String elderId = currentElder.id;
      final String userId = currentUser.uid;
      final String fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${_pickedFile!.name}';
      final Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('elder_images/$elderId/$fileName');

      await storageRef.putFile(File(_pickedFile!.path));
      final String downloadUrl = await storageRef.getDownloadURL();

      final journalServiceProvider =
          Provider.of<JournalServiceProvider>(context, listen: false);
      final now = DateTime.now();
      final dateString = DateFormat('yyyy-MM-dd').format(now);

      String loggedByDisplayName = currentUser.displayName ?? '';
      if (loggedByDisplayName.isEmpty) {
        loggedByDisplayName = currentUser.email ?? _l10n.formUnknownUser;
      }

      final Map<String, dynamic> imageData = {
        'url': downloadUrl,
        'storagePath': 'elder_images/$elderId/$fileName',
        'title': _imageTitle ?? _l10n.imageUploadDefaultTitle,
        'mimeType': _pickedFile!.mimeType,
        'size': await _pickedFile!.length(),
        'timestamp': FieldValue.serverTimestamp(),
      };

      final Map<String, dynamic> journalEntryPayload = {
        'elderId': elderId,
        'loggedByUserId': userId,
        'loggedByDisplayName': loggedByDisplayName,
        'loggedByUserAvatarUrl': currentUser.photoURL,
        'entryTimestamp': Timestamp.fromDate(now),
        'dateString': dateString,
        'text': _imageTitle ?? _l10n.imageUploadDefaultTitle,
        'data': imageData,
        'isPublic': true,
        'visibleToUserIds': currentElder.caregiverUserIds.toList(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'type': 'image',
      };

      await journalServiceProvider.addJournalEntry(
        'image',
        journalEntryPayload,
        userId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_l10n.imageUploadSuccess)),
        );
        _pickedFile = null;
        _titleController.clear();
        _imageTitle = null;
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _uploadError = _l10n.imageUploadErrorFailed(e.toString());
        });
      }
      debugPrint('Error uploading or saving image metadata: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  void _showImageFullScreen(String imageUrl, String imageTitle) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(imageTitle),
          ),
          body: Center(
            child: InteractiveViewer(
              child: Image.network(imageUrl, fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeElder = Provider.of<ActiveElderProvider>(context).activeElder;

    if (activeElder == null) {
      return Scaffold(
        appBar: AppBar(title: Text(_l10n.imageUploadScreenTitle)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              _l10n.imageUploadErrorNoElderSelected,
              style: AppStyles.emptyStateText,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_l10n.imageUploadScreenTitle),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _l10n.imageUploadForElder(activeElder.profileName),
              style:
                  AppStyles.sectionTitle.copyWith(color: AppTheme.primaryColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _pickImage(ImageSource.gallery),
              icon: const Icon(Icons.photo_library),
              label: Text(_l10n.imageUploadButtonGallery),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _pickImage(ImageSource.camera),
              icon: const Icon(Icons.camera_alt),
              label: Text(_l10n.imageUploadButtonCamera),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 24),
            if (_pickedFile != null) ...[
              Text(
                _l10n.imageUploadPreviewTitle,
                style: _theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Container(
                height: 200,
                color: AppTheme.backgroundGray,
                alignment: Alignment.center,
                child: Image.file(
                  File(_pickedFile!.path),
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                      Text(_l10n.imageUploadErrorLoadingPreview),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: _l10n.imageUploadLabelTitle,
                  hintText: _l10n.imageUploadHintTitle,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    _imageTitle = value;
                  });
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _isUploading ? null : _uploadImage,
                icon: _isUploading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: AppTheme.textOnPrimary,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.cloud_upload),
                label: Text(_isUploading
                    ? _l10n.imageUploadStatusUploading
                    : _l10n.imageUploadButtonUpload),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: AppTheme.accentColor,
                ),
              ),
            ],
            if (_uploadError != null)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Text(
                  _uploadError!,
                  style: const TextStyle(color: AppTheme.dangerColor),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 32),
            Text(
              _l10n.uploadedImagesSectionTitle,
              style:
                  AppStyles.sectionTitle.copyWith(color: AppTheme.primaryColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            StreamBuilder<List<JournalEntry>>(
              stream: Provider.of<JournalServiceProvider>(context,
                      listen: false)
                  .getJournalEntriesStream(
                    elderId: activeElder.id,
                    currentUserId: AuthService.currentUserId ?? '',
                  )
                  .map((entries) =>
                      entries.where((entry) => entry.type == 'image').toList()),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      // --- I18N UPDATE ---
                      // Replaced string concatenation with a parameterized
                      // localization key for better translation support.
                      _l10n.genericError(snapshot.error.toString()),
                      style: const TextStyle(color: AppTheme.dangerColor),
                    ),
                  );
                }
                final List<JournalEntry> imageEntries = snapshot.data ?? [];

                if (imageEntries.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      _l10n.noImagesUploadedYet,
                      style: AppStyles.emptyStateText.copyWith(fontSize: 16),
                      textAlign: TextAlign.center,
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
                    childAspectRatio: 0.8,
                  ),
                  itemCount: imageEntries.length,
                  itemBuilder: (context, index) {
                    final entry = imageEntries[index];
                    final String imageUrl = entry.data?['url'] as String? ?? '';
                    final String imageTitle = entry.data?['title']
                            as String? ??
                        _l10n.imageUploadDefaultTitle;
                    final DateTime uploadDate = entry.entryTimestamp.toDate();

                    if (imageUrl.isEmpty) {
                      return Card(
                        color: AppTheme.backgroundGray,
                        child: Center(
                          child: Text(_l10n.imageUnavailable,
                              textAlign: TextAlign.center),
                        ),
                      );
                    }

                    return GestureDetector(
                      onTap: () => _showImageFullScreen(imageUrl, imageTitle),
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Center(
                                      child: CircularProgressIndicator(
                                          value: loadingProgress
                                                      .expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                              : null));
                                },
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                        color: AppTheme.backgroundGray,
                                        child: const Center(
                                            child: Icon(Icons.broken_image,
                                                color: AppTheme.textLight,
                                                size: 40))),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(imageTitle,
                                        style: _theme.textTheme.bodyMedium
                                            ?.copyWith(
                                                fontWeight: FontWeight.bold),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 4),
                                    // --- I18N UPDATE ---
                                    // Using locale-aware date formatting.
                                    Text(
                                        DateFormat.yMMMd(_l10n.localeName)
                                            .format(uploadDate),
                                        style: _theme.textTheme.bodySmall)
                                  ]),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}