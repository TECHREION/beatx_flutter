import 'package:flutter/material.dart';

import 'legal_page_screen.dart';

/// Privacy Policy, from `GET /legal/privacy`.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const LegalPageScreen(slug: 'privacy', title: 'Privacy Policy');
}
