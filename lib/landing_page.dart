// lib/landing_page.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cecelia_care_flutter/utils/app_styles.dart';
import 'package:cecelia_care_flutter/l10n/app_localizations.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Your Logo
              Image.asset(
                'assets/images/logo.png', // Make sure you have a logo here
                width: 150,
                height: 150,
              ),
              const SizedBox(height: 24),
              // Value Proposition
              Text(
                'The simplest way to coordinate care, so you can focus on what matters.',
                textAlign: TextAlign.center,
                style: AppStyles.authTitle.copyWith(fontSize: 28),
              ),
              const SizedBox(height: 16),
              Text(
                'Our app is coming soon! Join the waitlist to be the first to know when we launch and get priority access.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 18),
              ),
              const SizedBox(height: 48),
              
              // --- Waitlist Sign-up Form ---
              const WaitlistSignupForm(),

            ],
          ),
        ),
      ),
    );
  }
}

// A new widget specifically for the waitlist form
class WaitlistSignupForm extends StatefulWidget {
  const WaitlistSignupForm({super.key});

  @override
  State<WaitlistSignupForm> createState() => _WaitlistSignupFormState();
}

class _WaitlistSignupFormState extends State<WaitlistSignupForm> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _message;
  bool _isError = false;

  Future<void> _joinWaitlist() async {
    if (_emailController.text.trim().isEmpty || !_emailController.text.contains('@')) {
       setState(() {
         _message = 'Please enter a valid email.';
         _isError = true;
       });
       return;
    }

    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      // Add email to Firestore 'waitlist' collection
      await FirebaseFirestore.instance.collection('waitlist').add({
        'email': _emailController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
      });
      setState(() {
        _message = "Thank you for joining! We'll be in touch.";
        _isError = false;
        _emailController.clear();
      });
    } catch (e) {
      setState(() {
        _message = 'An error occurred. Please try again.';
        _isError = true;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400), // Keeps form from getting too wide
          child: TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Enter your email',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.email_outlined),
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (_message != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Text(
              _message!,
              style: TextStyle(color: _isError ? Colors.red : Colors.green.shade700, fontSize: 16),
            ),
          ),
        SizedBox(
          width: 200,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _joinWaitlist,
            style: Theme.of(context).elevatedButtonTheme.style,
            child: _isLoading 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2,))
              : const Text('Join Waitlist'),
          ),
        ),
      ],
    );
  }
}