import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cecelia_care_flutter/services/auth_service.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';
import 'package:cecelia_care_flutter/utils/app_styles.dart';

// Import your AppLocalizations
import 'package:cecelia_care_flutter/l10n/app_localizations.dart';

/// A warm, supportive login screen. On successful login, AuthGate (in
/// main.dart) detects the user and replaces this with the home screen.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? _errorText;
  bool _isLoading = false;
  bool _isCreateMode = false;

  // Entrance animation
  late final AnimationController _entranceCtrl;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeIn = CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOut));
    _entranceCtrl.forward();
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final l10n = AppLocalizations.of(context)!;
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() => _errorText = null);

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorText = l10n.errorEnterEmailPassword);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await AuthService.signIn(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorText = e.message ?? l10n.errorLoginFailedDefault;
      });
    } catch (e) {
      setState(() {
        _errorText = '${l10n.errorPrefix}${e.toString()}';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleCreateAccount() async {
    final l10n = AppLocalizations.of(context)!;
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() => _errorText = null);

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorText = l10n.errorEnterEmailPassword);
      return;
    }
    if (password.length < 6) {
      setState(() =>
          _errorText = 'Password must be at least 6 characters.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = AuthService();
      await authService.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorText =
            e.message ?? 'Account creation failed. Please try again.';
      });
    } catch (e) {
      setState(() {
        _errorText = '${l10n.errorPrefix}${e.toString()}';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryColor.withValues(alpha: 0.06),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: FadeTransition(
                opacity: _fadeIn,
                child: SlideTransition(
                  position: _slideUp,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ─── Logo ───
                      Image.asset(
                        'assets/images/logo.png',
                        width: 110,
                        height: 110,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 16),

                      // ─── App Name ───
                      Text(
                        _isCreateMode
                            ? 'Create Account'
                            : l10n.loginScreenTitle,
                        style: AppStyles.authTitle,
                      ),
                      const SizedBox(height: 6),

                      // ─── Tagline ───
                      Text(
                        'Supporting those who support others',
                        style: TextStyle(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 36),

                      // ─── Email TextField ───
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: l10n.emailLabel,
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusM),
                          ),
                          hintText: l10n.emailHint,
                          prefixIcon: const Icon(Icons.email_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ─── Password TextField ───
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _isCreateMode
                            ? _handleCreateAccount()
                            : _handleLogin(),
                        decoration: InputDecoration(
                          labelText: l10n.passwordLabel,
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusM),
                          ),
                          prefixIcon: const Icon(Icons.lock_outline),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ─── Error message if any ───
                      if (_errorText != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            _errorText!,
                            style: const TextStyle(
                                color: AppTheme.dangerColor, fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                        ),

                      // ─── Login / Create Button ───
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading
                              ? null
                              : (_isCreateMode
                                  ? _handleCreateAccount
                                  : _handleLogin),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentColor,
                            elevation: _isLoading ? 0 : 2,
                            padding:
                                const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusM),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  _isCreateMode
                                      ? 'Create Account'
                                      : l10n.loginButton,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ─── Toggle between login and create account ───
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isCreateMode = !_isCreateMode;
                            _errorText = null;
                          });
                        },
                        child: Text(
                          _isCreateMode
                              ? 'Already have an account? Log in'
                              : l10n.dontHaveAccountSignUp,
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppTheme.primaryColor,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
