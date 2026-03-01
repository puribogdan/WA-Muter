import 'package:flutter/material.dart';

class WelcomeOnboardingScreen extends StatefulWidget {
  final VoidCallback onContinue;

  const WelcomeOnboardingScreen({
    super.key,
    required this.onContinue,
  });

  @override
  State<WelcomeOnboardingScreen> createState() => _WelcomeOnboardingScreenState();
}

class _WelcomeOnboardingScreenState extends State<WelcomeOnboardingScreen> {
  int _step = 0;

  static const Color bgColor = Color(0xFF0B0F0A);
  static const Color accentColor = Color(0xFFA3B836);
  static const Color primaryText = Color(0xFFF3F4F5);
  static const Color secondaryText = Color(0xFFA7B0A9);

  void _onNextPressed() {
    if (_step < 2) {
      setState(() => _step += 1);
    } else {
      widget.onContinue();
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (_step) {
      case 0:
        return _OnboardingScreenOne(onNext: _onNextPressed);
      case 1:
        return _OnboardingScreenTwo(onNext: _onNextPressed);
      default:
        return _OnboardingScreenThree(onNext: _onNextPressed);
    }
  }
}

class _OnboardingShell extends StatelessWidget {
  final Widget graphic;
  final String title;
  final String description;
  final String buttonLabel;
  final VoidCallback onPressed;

  const _OnboardingShell({
    required this.graphic,
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _WelcomeOnboardingScreenState.bgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Column(
                children: [
                  graphic,
                  const SizedBox(height: 56),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: _WelcomeOnboardingScreenState.primaryText,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    description,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      color: _WelcomeOnboardingScreenState.secondaryText,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: onPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _WelcomeOnboardingScreenState.accentColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    buttonLabel,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _WelcomeOnboardingScreenState.bgColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingScreenOne extends StatelessWidget {
  final VoidCallback onNext;

  const _OnboardingScreenOne({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return _OnboardingShell(
      graphic: _OnboardingGraphics.buildIconGraphic(Icons.notifications_off_outlined),
      title: 'WhatsApp never sleeps.\nBut you should.',
      description:
          'Group chats, client messages, and random pings don\'t care what time it is. Stop letting your phone dictate your downtime.',
      buttonLabel: 'Next',
      onPressed: onNext,
    );
  }
}

class _OnboardingScreenTwo extends StatelessWidget {
  final VoidCallback onNext;

  const _OnboardingScreenTwo({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return _OnboardingShell(
      graphic: _OnboardingGraphics.buildChatGraphic(),
      title: 'Mute the noise. Keep\nthe important stuff.',
      description:
          'Don\'t mute your whole phone. Build custom schedules to automatically silence specific groups and contacts, while letting personal messages through.',
      buttonLabel: 'Next',
      onPressed: onNext,
    );
  }
}

class _OnboardingScreenThree extends StatelessWidget {
  final VoidCallback onNext;

  const _OnboardingScreenThree({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return _OnboardingShell(
      graphic: _OnboardingGraphics.buildPrivacyGraphic(),
      title: 'Your chats stay on\nyour device.',
      description:
          'To silence specific chats, ChatMuter needs Notification Access to read incoming sender names. We do not read your messages, and your data never leaves your phone.',
      buttonLabel: 'Grant Access & Start',
      onPressed: onNext,
    );
  }
}

class _OnboardingGraphics {
  static const Color _bgColor = _WelcomeOnboardingScreenState.bgColor;
  static const Color _accentColor = _WelcomeOnboardingScreenState.accentColor;

  static Widget buildIconGraphic(IconData icon) {
    return _buildGlowingContainer(
      child: Icon(icon, size: 80, color: _accentColor),
    );
  }

  static Widget buildChatGraphic() {
    return _buildGlowingContainer(
      width: 180,
      height: 140,
      child: Stack(
        children: [
          Positioned(
            top: 10,
            left: 0,
            child: _buildBubble(
              text: 'Boss',
              icon: Icons.do_not_disturb_alt,
              isLeftTail: true,
            ),
          ),
          Positioned(
            bottom: 10,
            right: 0,
            child: _buildBubble(
              text: 'Mom',
              icon: Icons.check,
              isLeftTail: false,
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildPrivacyGraphic() {
    return _buildGlowingContainer(
      width: 140,
      height: 140,
      child: Stack(
        alignment: Alignment.center,
        children: const [
          Icon(Icons.shield_outlined, size: 130, color: _accentColor),
          Icon(Icons.phonelink_lock, size: 50, color: _accentColor),
        ],
      ),
    );
  }

  static Widget _buildBubble({
    required String text,
    required IconData icon,
    required bool isLeftTail,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _bgColor,
        border: Border.all(color: _accentColor, width: 2),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(isLeftTail ? 4 : 16),
          bottomRight: Radius.circular(isLeftTail ? 16 : 4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: const TextStyle(
              color: _accentColor,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(width: 8),
          Icon(icon, color: _accentColor, size: 20),
        ],
      ),
    );
  }

  static Widget _buildGlowingContainer({
    required Widget child,
    double width = 120,
    double height = 120,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: _accentColor.withOpacity(0.15),
            blurRadius: 50,
            spreadRadius: 10,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: child,
    );
  }
}
