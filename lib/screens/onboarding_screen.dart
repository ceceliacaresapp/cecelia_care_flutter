// lib/screens/onboarding_screen.dart
//
// Interactive "learning by doing" first-launch flow. Each page performs a
// REAL action so the dashboard isn't empty on first visit.
//
// 5 pages:
//   1. Welcome — warm greeting + "Let's get started"
//   2. Your Name — user enters their display name (saved to Firestore)
//   3. Care Recipient — user enters their care recipient's name (creates elder profile)
//   4. First Log — quick-log grid: Mood, Medication, Meal, or Vital (creates real entry)
//   5. You're Ready — celebration + "Explore your dashboard"
//
// On completion, writes `onboardingCompleted: true` to Firestore.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:cecelia_care_flutter/models/elder_profile.dart';
import 'package:cecelia_care_flutter/providers/active_elder_provider.dart';
import 'package:cecelia_care_flutter/providers/journal_service_provider.dart';
import 'package:cecelia_care_flutter/providers/medication_definitions_provider.dart';
import 'package:cecelia_care_flutter/screens/forms/meal_form.dart';
import 'package:cecelia_care_flutter/screens/forms/med_form.dart';
import 'package:cecelia_care_flutter/screens/forms/mood_form.dart';
import 'package:cecelia_care_flutter/screens/forms/vital_form.dart';
import 'package:cecelia_care_flutter/services/firestore_service.dart';
import 'package:cecelia_care_flutter/services/notification_service.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';
import 'package:cecelia_care_flutter/utils/haptic_utils.dart';
import 'package:cecelia_care_flutter/widgets/confetti_overlay.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pc = PageController();
  int _page = 0;
  static const int _pageCount = 5;

  // Page 2 state
  final _nameCtrl = TextEditingController();
  bool _nameSaving = false;

  // Page 3 state
  final _elderNameCtrl = TextEditingController();
  bool _elderSaving = false;
  ElderProfile? _createdElder;

  // Page 4 state
  bool _firstLogDone = false;

  @override
  void dispose() {
    _pc.dispose();
    _nameCtrl.dispose();
    _elderNameCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < _pageCount - 1) {
      _pc.nextPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  Future<void> _complete() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'onboardingCompleted': true,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        debugPrint('OnboardingScreen: error saving flag: $e');
      }
    }
    // Request notification permission at onboarding completion — the user
    // has just experienced value and is emotionally receptive. This fires
    // at most once (gated by SharedPreferences internally).
    try {
      await NotificationService.instance.requestPermissionIfNeeded();
    } catch (_) {}
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryColor.withValues(alpha: 0.04),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Skip (hidden on last page)
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8, right: 16),
                  child: _page < _pageCount - 1
                      ? TextButton(
                          onPressed: _complete,
                          child: Text('Skip',
                              style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 14)),
                        )
                      : const SizedBox(height: 48),
                ),
              ),

              // Pages
              Expanded(
                child: PageView(
                  controller: _pc,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (i) => setState(() => _page = i),
                  children: [
                    _buildWelcome(),
                    _buildNamePage(),
                    _buildElderPage(),
                    _buildFirstLogPage(),
                    _buildReadyPage(),
                  ],
                ),
              ),

              // Progress dots
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_pageCount, (i) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == _page ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _page
                            ? AppTheme.primaryColor
                            : AppTheme.primaryColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Page 1: Welcome ─────────────────────────────────────────

  Widget _buildWelcome() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/images/logo.png', width: 100, height: 100),
          const SizedBox(height: 24),
          const Text(
            'Welcome to\nCecelia Care',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppTheme.primaryColor,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Supporting those who support others',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontStyle: FontStyle.italic,
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _next,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusM)),
              ),
              child: const Text("Let's get started",
                  style:
                      TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Page 2: Your Name ───────────────────────────────────────

  Widget _buildNamePage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.tileBlue.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_outline,
                size: 48, color: AppTheme.tileBlue),
          ),
          const SizedBox(height: 24),
          const Text(
            "What's your name?",
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryColor),
          ),
          const SizedBox(height: 8),
          Text(
            'Your care team will see this name.',
            style: TextStyle(
                fontSize: 14, color: AppTheme.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _nameCtrl,
            textCapitalization: TextCapitalization.words,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Your name',
              hintText: 'e.g. Maria',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusM)),
              prefixIcon: const Icon(Icons.badge_outlined),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _nameCtrl.text.trim().isEmpty || _nameSaving
                  ? null
                  : _saveName,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.tileBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusM)),
              ),
              child: _nameSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Next',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveName() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _nameSaving = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.updateDisplayName(name);
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'displayName': name,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      HapticUtils.success();
      _next();
    } catch (e) {
      debugPrint('Onboarding: save name error: $e');
    } finally {
      if (mounted) setState(() => _nameSaving = false);
    }
  }

  // ── Page 3: Care Recipient ──────────────────────────────────

  Widget _buildElderPage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.tilePinkBright.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.favorite_outline,
                size: 48, color: AppTheme.tilePinkBright),
          ),
          const SizedBox(height: 24),
          const Text(
            'Who are you caring for?',
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryColor),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter their name to create their care profile.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 14, color: AppTheme.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _elderNameCtrl,
            textCapitalization: TextCapitalization.words,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Care recipient name',
              hintText: 'e.g. Mom, Dad, Grandma Rose',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusM)),
              prefixIcon: const Icon(Icons.person_add_outlined),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed:
                  _elderNameCtrl.text.trim().isEmpty || _elderSaving
                      ? null
                      : _saveElder,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.tilePinkBright,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusM)),
              ),
              child: _elderSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Create & Continue',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveElder() async {
    final name = _elderNameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _elderSaving = true);
    try {
      final fs = context.read<FirestoreService>();
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      await fs.createElderProfile({
        'profileName': name,
        'primaryAdminUserId': uid,
        'caregiverUserIds': [uid],
      });
      // Give the Firestore stream a moment to deliver the new elder
      // to ActiveElderProvider (it subscribes to realtime snapshots).
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        final elder = context.read<ActiveElderProvider>().activeElder;
        if (elder != null) _createdElder = elder;
      }
      HapticUtils.success();
      _next();
    } catch (e) {
      debugPrint('Onboarding: create elder error: $e');
    } finally {
      if (mounted) setState(() => _elderSaving = false);
    }
  }

  // ── Page 4: First Log ───────────────────────────────────────

  Widget _buildFirstLogPage() {
    final elder = _createdElder ??
        context.watch<ActiveElderProvider>().activeElder;
    final dateStr =
        '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}';

    if (_firstLogDone) {
      return _buildFirstLogSuccess();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.statusGreen.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.edit_note_outlined,
                size: 48, color: AppTheme.statusGreen),
          ),
          const SizedBox(height: 24),
          const Text(
            'Log your first entry',
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryColor),
          ),
          const SizedBox(height: 8),
          Text(
            elder != null
                ? 'Tap any tile to log something for ${elder.profileName}.'
                : 'Tap any tile to log your first care entry.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 14, color: AppTheme.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 28),
          if (elder != null)
            _buildQuickLogGrid(context, elder, dateStr)
          else
            Text(
              'No care recipient found — tap "Skip" to continue and add one later.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13, color: AppTheme.textSecondary),
            ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _next,
            child: const Text('Skip this step',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickLogGrid(
      BuildContext context, ElderProfile elder, String dateStr) {
    final journalService = context.read<JournalServiceProvider>();

    final tiles = [
      _QuickLogTile(
        icon: Icons.sentiment_satisfied_outlined,
        label: 'Mood',
        color: AppTheme.tilePinkBright,
        form: ChangeNotifierProvider.value(
          value: journalService,
          child: MoodForm(
              onClose: () => _onFirstLogDone(),
              currentDate: dateStr,
              activeElder: elder),
        ),
      ),
      _QuickLogTile(
        icon: Icons.medication_outlined,
        label: 'Medication',
        color: AppTheme.tileBlue,
        form: MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: journalService),
            ChangeNotifierProvider(
              create: (_) =>
                  MedicationDefinitionsProvider()..updateForElder(elder),
            ),
          ],
          child: MedForm(
              onClose: () => _onFirstLogDone(),
              currentDate: dateStr,
              activeElder: elder),
        ),
      ),
      _QuickLogTile(
        icon: Icons.restaurant_outlined,
        label: 'Meal',
        color: AppTheme.statusGreen,
        form: ChangeNotifierProvider.value(
          value: journalService,
          child: MealForm(
              onClose: () => _onFirstLogDone(),
              currentDate: dateStr,
              activeElder: elder),
        ),
      ),
      _QuickLogTile(
        icon: Icons.monitor_heart_outlined,
        label: 'Vital',
        color: AppTheme.tileOrange,
        form: ChangeNotifierProvider.value(
          value: journalService,
          child: VitalForm(
              onClose: () => _onFirstLogDone(),
              currentDate: dateStr,
              activeElder: elder),
        ),
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: tiles.map((t) {
        return GestureDetector(
          onTap: () => _openForm(t.form),
          child: Container(
            decoration: BoxDecoration(
              color: t.color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
              border: Border.all(color: t.color.withValues(alpha: 0.25)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(t.icon, color: t.color, size: 28),
                const SizedBox(height: 6),
                Text(t.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: t.color,
                    )),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  void _openForm(Widget form) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheetCtx).viewInsets.bottom),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(sheetCtx).scaffoldBackgroundColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(sheetCtx).size.height * 0.92,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.textLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Flexible(child: form),
              ],
            ),
          ),
        );
      },
    );
  }

  void _onFirstLogDone() {
    if (!mounted) return;
    HapticUtils.celebration();
    ConfettiOverlay.trigger(context);
    setState(() => _firstLogDone = true);
  }

  Widget _buildFirstLogSuccess() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.statusGreen.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.celebration,
                size: 56, color: AppTheme.statusGreen),
          ),
          const SizedBox(height: 24),
          const Text(
            'Great job!',
            style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppTheme.statusGreen),
          ),
          const SizedBox(height: 8),
          Text(
            'You just logged your first care entry.\nYour dashboard is already filling in.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 15, color: AppTheme.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _next,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.statusGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusM)),
              ),
              child: const Text('Continue',
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Page 5: You're Ready ────────────────────────────────────

  Widget _buildReadyPage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.dashboard_outlined,
                size: 56, color: AppTheme.primaryColor),
          ),
          const SizedBox(height: 28),
          const Text(
            "You're ready!",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppTheme.primaryColor,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Your dashboard is set up with real data. '
            'Explore your care tools, invite your team, and '
            'remember — every log matters.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 15, color: AppTheme.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _complete,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusM)),
                elevation: 2,
              ),
              child: const Text(
                'Explore your dashboard',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickLogTile {
  final IconData icon;
  final String label;
  final Color color;
  final Widget form;

  const _QuickLogTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.form,
  });
}
