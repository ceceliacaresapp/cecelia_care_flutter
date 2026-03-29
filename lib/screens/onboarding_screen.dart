// lib/screens/onboarding_screen.dart
//
// First-launch walkthrough — shown ONCE after a new account is created.
//
// Triggered by `onboardingCompleted == false` on the user's Firestore profile.
// Existing users who don't have the field are treated as completed.
//
// 5 pages:
//   1. Welcome to Cecelia Care
//   2. Set Up Your Profile
//   3. Add Your Care Recipient
//   4. Your Toolkit (6-tab overview)
//   5. You're All Set
//
// On completion, writes `onboardingCompleted: true` to Firestore.

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:cecelia_care_flutter/utils/app_theme.dart';
import 'package:cecelia_care_flutter/screens/settings/my_account_screen.dart';
import 'package:cecelia_care_flutter/screens/manage_care_recipient_profiles_screen.dart';

const _kPrimary = Color(0xFF3F51B5);
const _kAccent = Color(0xFFFF5722);

class OnboardingScreen extends StatefulWidget {
  /// Called when onboarding is complete — HomeScreen uses this to dismiss.
  final VoidCallback onComplete;

  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageCtrl = PageController();
  int _currentPage = 0;
  static const int _pageCount = 5;

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentPage < _pageCount - 1) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _skip() => _complete();

  Future<void> _complete() async {
    // Write the flag to Firestore
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
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button (top right) — hidden on last page
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 8, right: 16),
                child: _currentPage < _pageCount - 1
                    ? TextButton(
                        onPressed: _skip,
                        child: const Text(
                          'Skip',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      )
                    : const SizedBox(height: 48),
              ),
            ),

            // Pages
            Expanded(
              child: PageView(
                controller: _pageCtrl,
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  _WelcomePage(),
                  _SetUpProfilePage(
                    onGoToProfile: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const MyAccountScreen(),
                      ));
                    },
                  ),
                  _AddCareRecipientPage(
                    onGoToProfiles: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) =>
                            const ManageCareRecipientProfilesScreen(),
                      ));
                    },
                  ),
                  _ToolkitPage(),
                  _AllSetPage(onComplete: _complete),
                ],
              ),
            ),

            // Page dots + Next button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Row(
                children: [
                  // Dots
                  Row(
                    children: List.generate(_pageCount, (i) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: i == _currentPage ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: i == _currentPage
                              ? _kPrimary
                              : _kPrimary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const Spacer(),
                  // Next / Get Started button
                  if (_currentPage < _pageCount - 1)
                    ElevatedButton(
                      onPressed: _next,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kPrimary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Next',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward, size: 18),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Page 1 — Welcome
// ---------------------------------------------------------------------------
class _WelcomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _kPrimary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.favorite, size: 64, color: _kPrimary),
          ),
          const SizedBox(height: 32),
          const Text(
            'Welcome to\nCecelia Care',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: _kPrimary,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'The caregiving companion that helps you coordinate care, '
            'track health, and take care of yourself too.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _kAccent.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              "Let's get you set up in under 2 minutes",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _kAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Page 2 — Set Up Your Profile
// ---------------------------------------------------------------------------
class _SetUpProfilePage extends StatelessWidget {
  const _SetUpProfilePage({required this.onGoToProfile});
  final VoidCallback onGoToProfile;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E88E5).withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_outline,
                size: 56, color: Color(0xFF1E88E5)),
          ),
          const SizedBox(height: 28),
          const Text(
            'Set up your profile',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: _kPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Add your name, photo, and caregiving goals so your care '
            'team knows who you are.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: onGoToProfile,
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Go to My Account'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _kPrimary,
              side: const BorderSide(color: _kPrimary, width: 1.5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 12),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You can always do this later in Settings',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textLight,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Page 3 — Add Your Care Recipient
// ---------------------------------------------------------------------------
class _AddCareRecipientPage extends StatelessWidget {
  const _AddCareRecipientPage({required this.onGoToProfiles});
  final VoidCallback onGoToProfiles;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFE91E63).withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.group_add_outlined,
                size: 56, color: Color(0xFFE91E63)),
          ),
          const SizedBox(height: 28),
          const Text(
            'Add your care recipient',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: _kPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'This is the person you\'re caring for. Add their name, '
            'allergies, medications, and emergency contact info.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You can manage multiple care recipients and invite '
            'other caregivers to collaborate.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: onGoToProfiles,
            icon: const Icon(Icons.add_circle_outline, size: 18),
            label: const Text('Create Care Recipient'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFE91E63),
              side: const BorderSide(
                  color: Color(0xFFE91E63), width: 1.5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 12),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You can always do this later in Settings',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textLight,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Page 4 — Your Toolkit (6 tabs overview)
// ---------------------------------------------------------------------------
class _ToolkitPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Your toolkit',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: _kPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Everything you need, organized in 6 tabs:',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          _ToolkitItem(
            icon: Icons.home_outlined,
            color: const Color(0xFF1E88E5),
            title: 'Home',
            desc: 'Dashboard with today\'s summary, quick log, and wellness check-in.',
          ),
          _ToolkitItem(
            icon: Icons.timeline_outlined,
            color: const Color(0xFF5C6BC0),
            title: 'Timeline',
            desc: 'Shared care log visible to your entire care team in real time.',
          ),
          _ToolkitItem(
            icon: Icons.favorite_border,
            color: const Color(0xFFE91E63),
            title: 'Care',
            desc: 'Medications, document scanner, resources, and budget tracker.',
          ),
          _ToolkitItem(
            icon: Icons.calendar_today_outlined,
            color: const Color(0xFF00897B),
            title: 'Calendar',
            desc: 'Appointments, health screenings, and shared events.',
          ),
          _ToolkitItem(
            icon: Icons.receipt_long_outlined,
            color: const Color(0xFFF57C00),
            title: 'Expenses',
            desc: 'Track caregiving costs by category with weekly summaries.',
          ),
          _ToolkitItem(
            icon: Icons.self_improvement_outlined,
            color: const Color(0xFF8E24AA),
            title: 'Self Care',
            desc: 'Wellness check-ins, burnout detection, breathing exercises, and journaling.',
          ),
        ],
      ),
    );
  }
}

class _ToolkitItem extends StatelessWidget {
  const _ToolkitItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.desc,
  });
  final IconData icon;
  final Color color;
  final String title;
  final String desc;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Page 5 — You're All Set
// ---------------------------------------------------------------------------
class _AllSetPage extends StatelessWidget {
  const _AllSetPage({required this.onComplete});
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF43A047).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle,
                size: 64, color: Color(0xFF43A047)),
          ),
          const SizedBox(height: 32),
          const Text(
            "You're all set!",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Color(0xFF43A047),
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Start caring with confidence. Cecelia is here to help you '
            'every step of the way.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onComplete,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 2,
              ),
              child: const Text(
                "Let's get started",
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
