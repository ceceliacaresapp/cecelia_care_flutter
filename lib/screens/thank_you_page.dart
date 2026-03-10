import 'package:flutter/material.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';
import 'package:cecelia_care_flutter/utils/app_styles.dart';

class ThankYouPage extends StatefulWidget {
  const ThankYouPage({super.key});

  @override
  State<ThankYouPage> createState() => _ThankYouPageState();
}

class _ThankYouPageState extends State<ThankYouPage> {
  final TextEditingController _surveyController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thank You!'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.green, size: 100),
              const SizedBox(height: 24),
              const Text(
                "You're on the waitlist!",
                style: AppStyles.screenTitle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'You are currently number #1234 on the waitlist.', // You can randomize this or use a real number from your database.
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // Viral Referral
              const Text(
                'Invite 3 friends to move to the front of the line!',
                style: AppStyles.sectionTitle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.facebook),
                    onPressed: () {
                      // Implement sharing logic
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.email),
                    onPressed: () {
                      // Implement sharing logic
                    },
                  ),
                ],
              ),
              const SizedBox(height: 48),

              // Survey
              const Text(
                'What is your single biggest challenge in caregiving today?',
                style: AppStyles.sectionTitle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _surveyController,
                decoration: const InputDecoration(
                  hintText: 'Your challenge...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // Save survey response to Firestore
                },
                child: const Text('Submit Feedback'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}