import 'package:app_pigeon/app_pigeon.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/api_handler/failure.dart';
import '../../model/legal_page_model.dart';
import '../../services/profile_interface.dart';
import '../../services/profile_interface_impl.dart';
import '../widgets/profile_screen_chrome.dart';

/// A legal page from `GET /legal/:slug`, in the profile screens' chrome.
///
/// Until the page is published the API answers 404, which shows as a calm
/// "not published yet" note rather than an error.
class LegalPageScreen extends StatefulWidget {
  const LegalPageScreen({super.key, required this.slug, required this.title});

  final String slug;

  /// Shown in the header; the page's own title replaces it once loaded.
  final String title;

  @override
  State<LegalPageScreen> createState() => _LegalPageScreenState();
}

class _LegalPageScreenState extends State<LegalPageScreen> {
  LegalPage? _page;
  String _message = '';
  bool _loading = true;

  ProfileInterface _interface() {
    if (!Get.isRegistered<ProfileInterface>()) {
      Get.put<ProfileInterface>(
        ProfileInterfaceImpl(Get.find<AuthorizedPigeon>()),
      );
    }
    return Get.find<ProfileInterface>();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _message = '';
    });
    final result = await _interface().legalPage(widget.slug);
    if (!mounted) return;
    setState(() {
      result.fold((failure) {
        _message = failure.failure == Failure.notFound
            ? 'This page has not been published yet.'
            : failure.uiMessage;
      }, (ok) => _page = ok.data);
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final page = _page;
    return Scaffold(
      backgroundColor: const Color(0xFF050608),
      body: Stack(
        children: [
          const ProfileBackgroundGlow(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ProfileScreenHeader(
                    title: page == null || page.title.isEmpty
                        ? widget.title
                        : page.title,
                  ),
                  const SizedBox(height: 30),
                  Expanded(child: _content(page)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _content(LegalPage? page) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF3BDDEB)),
      );
    }
    if (page == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.description_outlined,
              color: Colors.white38,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              _message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white60, fontSize: 14),
            ),
            TextButton(
              onPressed: _load,
              child: const Text(
                'Try again',
                style: TextStyle(color: Color(0xFF3BDDEB)),
              ),
            ),
          ],
        ),
      );
    }
    final updated = page.updatedAt?.toLocal();
    return RefreshIndicator(
      color: const Color(0xFF3BDDEB),
      onRefresh: _load,
      child: ListView(
        children: [
          if (updated != null) ...[
            Text(
              'Last updated ${updated.day}/${updated.month}/${updated.year}',
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
            const SizedBox(height: 16),
          ],
          SelectableText(
            page.plainText,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 15,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }
}
