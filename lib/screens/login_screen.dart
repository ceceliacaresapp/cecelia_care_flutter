import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cecelia_care_flutter/services/auth_service.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';
import 'package:cecelia_care_flutter/utils/app_styles.dart';

// Import your AppLocalizations
import 'package:cecelia_care_flutter/l10n/app_localizations.dart';
// Or if it's generated in dart_tool:
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// A simple login screen that calls FirebaseAuth.signInWithEmailAndPassword.
/// On successful login, AuthGate (in main.dart) will detect the user and replace
/// this screen with TimelineScreen automatically.
class LoginScreen extends StatefulWidget {
  final VoidCallback? onNavigateToSignUp; // <<< MODIFICATION: Added field

  const LoginScreen({
    super.key,
    this.onNavigateToSignUp, // <<< MODIFICATION: Added to constructor
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? _errorText;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    // Get AppLocalizations instance for use in async method if needed for error messages
    final l10n = AppLocalizations.of(context)!;
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() {
      _errorText = null;
    });

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        // Assuming 'errorEnterEmailPassword' is a key you've added to your .arb files
        _errorText = l10n.errorEnterEmailPassword;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Use the AuthService.instance singleton and call the signIn method
      await AuthService.signIn(email: email, password: password);
      // At this point, AuthGate’s stream will fire and navigate.
    } on FirebaseAuthException catch (e) {
      setState(() {
        // Firebase Auth exceptions often have localized messages.
        // We provide a fallback from our ARB files.
        // Assuming 'errorLoginFailedDefault' is a key you've added.
        _errorText = e.message ?? l10n.errorLoginFailedDefault;
      });
    } catch (e) {
      setState(() {
        // Assuming 'errorPrefix' is a key you've added.
        _errorText = '${l10n.errorPrefix}${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get AppLocalizations instance
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ─── Logo ───
                Image.asset(
                  'assets/images/logo.png',
                  width: 120,
                  height: 120,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 24),

                // ─── App Name ───
                Text(
                  // Assuming 'loginScreenTitle' is a key you've added
                  l10n.loginScreenTitle,
                  style: AppStyles.authTitle,
                ),
                const SizedBox(height: 48),

                // ─── Email TextField ───
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    // Assuming 'emailLabel' is a key you've added
                    labelText: l10n.emailLabel,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    // Assuming 'emailHint' is a key you've added
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
                  decoration: InputDecoration(
                    // Assuming 'passwordLabel' is a key you've added
                    labelText: l10n.passwordLabel,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
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
                      _errorText!, // This is already localized in _handleLogin
                      style: const TextStyle(color: Colors.red, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),

                // ─── Login Button ───
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentColor,
                      elevation: _isLoading ? 0 : 2,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
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
                            l10n.loginButton, // This is an existing key
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),

                // ─── (Optional) Link to create an account ───
                GestureDetector(
                  onTap: () {
                    // <<< MODIFICATION: Use the callback passed from LandingPage >>>
                    if (widget.onNavigateToSignUp != null) {
                      widget.onNavigateToSignUp!();
                    } else {
                      // Fallback or error if the callback is somehow not provided,
                      // though in the current setup from LandingPage, it should always be.
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n.signUpNotImplemented),
                        ), // Or a more specific error
                      );
                    }
                  },
                  child: Text(
                    // Assuming 'dontHaveAccountSignUp' is a key you've added
                    l10n.dontHaveAccountSignUp,
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
    );
  }
}
