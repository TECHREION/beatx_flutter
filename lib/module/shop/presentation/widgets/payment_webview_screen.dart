import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../services/payment_flow.dart';

/// The gateway's payment page, in-app.
///
/// It closes itself when the gateway reaches BeatX's callback. The buyer can
/// also close it at any point; either way the caller reads the real result
/// from the server afterwards, so nothing here decides whether a payment
/// worked.
class PaymentWebViewScreen extends StatefulWidget {
  const PaymentWebViewScreen({super.key, required this.url});

  final String url;

  /// Opens the page; completes when it has closed.
  static Future<void> open(String url) async {
    await Get.to<void>(() => PaymentWebViewScreen(url: url));
  }

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  /// How long to wait for a callback that started loading but never finishes
  /// or redirects. The request has been sent by then.
  static const _callbackGrace = Duration(seconds: 3);

  late final WebViewController _web;
  Timer? _callbackTimer;
  bool _loading = true;
  bool _failed = false;
  bool _closed = false;

  @override
  void initState() {
    super.initState();
    _web = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0B0B0C))
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            final step = gatewayStepOf(request.url);
            if (step == GatewayStep.finished) {
              _close();
              return NavigationDecision.prevent;
            }
            // The callback has to load: it is how the server learns the result.
            if (step == GatewayStep.callback) _closeSoon();
            return NavigationDecision.navigate;
          },
          onPageStarted: (url) {
            final step = gatewayStepOf(url);
            if (step == GatewayStep.finished) _close();
            if (step == GatewayStep.callback) _closeSoon();
            if (mounted) setState(() => _loading = true);
          },
          onPageFinished: (url) {
            if (gatewayStepOf(url) != GatewayStep.paying) _close();
            if (mounted) setState(() => _loading = false);
          },
          onWebResourceError: (error) {
            if (error.isForMainFrame != true || !mounted) return;
            setState(() {
              _loading = false;
              _failed = true;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  void _closeSoon() {
    _callbackTimer ??= Timer(_callbackGrace, _close);
  }

  void _close() {
    if (_closed || !mounted) return;
    _closed = true;
    _callbackTimer?.cancel();
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _callbackTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0B0C),
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Secure Payment',
          style: TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: _close,
            tooltip: 'Close',
            icon: const Icon(Icons.close_rounded, color: Colors.white),
          ),
        ],
        bottom: _loading
            ? const PreferredSize(
                preferredSize: Size.fromHeight(2),
                child: LinearProgressIndicator(
                  minHeight: 2,
                  color: Color(0xFF3BDDEB),
                  backgroundColor: Colors.transparent,
                ),
              )
            : null,
      ),
      body: _failed
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'The payment page could not be loaded. Close this page and '
                  'we will check your payment.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFFA7A3AA), height: 1.4),
                ),
              ),
            )
          : WebViewWidget(controller: _web),
    );
  }
}
