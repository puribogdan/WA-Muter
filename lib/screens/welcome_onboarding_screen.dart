import 'package:flutter/material.dart';

class WelcomeOnboardingScreen extends StatelessWidget {
  final VoidCallback onContinue;

  const WelcomeOnboardingScreen({
    super.key,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const Icon(Icons.notifications_off_outlined, size: 88),
              const SizedBox(height: 24),
              const Text(
                'Mute WhatsApp Groups on a Schedule',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Silences selected WhatsApp group notifications during your quiet hours. Works locally on your device.',
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              FilledButton(
                onPressed: onContinue,
                child: const Text('Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
