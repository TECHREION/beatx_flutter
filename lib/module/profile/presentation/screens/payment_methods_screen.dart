import 'package:beatx_flutter/core/common/widget/reactive_button/save_button.dart';
import 'package:beatx_flutter/core/notifiers/button_status_notifier.dart';
import 'package:beatx_flutter/module/profile/presentation/widgets/profile_screen_chrome.dart';
import 'package:flutter/material.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  final _saveButtonStatus = ProcessStatusNotifier(
    initialStatus: EnabledStatus(),
  );

  static const LinearGradient _paymentGradient = LinearGradient(
    colors: [Color(0xFFB2FF4E), Color(0xFF40DDEB)],
  );

  @override
  void dispose() {
    _saveButtonStatus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050608),
      body: Stack(
        children: [
          const ProfileBackgroundGlow(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const ProfileScreenHeader(title: 'Payment Methods'),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: _paymentGradient,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Stripe Connect',
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w600,
                                fontSize: 18,
                              ),
                            ),
                            Icon(Icons.credit_card, color: Colors.black),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          color: Colors.black,
                          padding: const EdgeInsets.all(10),
                          child: const Text(
                            '**** **** **** 4242',
                            style: TextStyle(
                              color: Colors.white,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Expires 12/2027',
                          style: TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  _label('Card number'),
                  const SizedBox(height: 8),
                  const _InputField(hint: '1234 1234 1234'),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('Security Code'),
                            const SizedBox(height: 8),
                            const _InputField(hint: 'CVC'),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('Expiry date'),
                            const SizedBox(height: 8),
                            const _InputField(hint: 'MM/YY'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _label('Zip Code'),
                  const SizedBox(height: 8),
                  const _InputField(hint: '12345'),
                  const SizedBox(height: 30),
                  RSaveButton(
                    key: const ValueKey('payment-method-save-button'),
                    height: 58,
                    borderRadius: BorderRadius.circular(30),
                    activeGradient: _paymentGradient,
                    buttonStatusNotifier: _saveButtonStatus,
                    saveText: 'Update Payment Method',
                    doneText: 'Updated',
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w700,
                    ),
                    onSaveTap: _savePaymentMethod,
                    onDone: _showSavedMessage,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _savePaymentMethod() {
    _saveButtonStatus.setSuccess();
  }

  void _showSavedMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Payment method updated')),
    );
    _saveButtonStatus.setEnabled();
  }

  Widget _label(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(color: Colors.white70, fontSize: 14),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  const _InputField({required this.hint});

  final String hint;

  @override
  Widget build(BuildContext context) {
    return TextField(
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        filled: true,
        fillColor: Colors.transparent,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: .3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF40DDEB)),
        ),
      ),
    );
  }
}
