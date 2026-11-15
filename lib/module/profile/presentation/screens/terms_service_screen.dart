import 'package:flutter/material.dart';

import 'legal_page_screen.dart';

/// Terms & Services, from `GET /legal/terms`.
class TermsServiceScreen extends StatelessWidget {
  const TermsServiceScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const LegalPageScreen(slug: 'terms', title: 'Terms & Services');
}
