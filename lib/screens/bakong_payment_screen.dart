import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../services/foodie_api.dart';
import '../services/api_client.dart';

const _brandColor = Color(0xFFF5233B);
const _mutedColor = Color(0xFF747782);

/// Displays the KHQR returned by the Foodie Spring Boot backend.
/// Transaction lookup is diagnostic until the backend links a verified
/// transaction to the persisted order and updates its payment status.
class BakongPaymentScreen extends StatefulWidget {
  final String orderId;
  final double amount;
  final String currency;
  final String qrPayload;
  final String md5;

  const BakongPaymentScreen({
    super.key,
    required this.orderId,
    required this.amount,
    required this.currency,
    required this.qrPayload,
    required this.md5,
  });

  @override
  State<BakongPaymentScreen> createState() => _BakongPaymentScreenState();
}

class _BakongPaymentScreenState extends State<BakongPaymentScreen> {
  bool _checking = false;
  bool _transactionFound = false;
  String? _statusMessage;
  String? _errorMessage;

  Future<void> _checkPayment() async {
    if (_checking) return;
    setState(() {
      _checking = true;
      _errorMessage = null;
      _statusMessage = null;
    });

    try {
      final response = await FoodieApi.instance.checkBakongTransaction(
        widget.md5,
      );
      final code = response['responseCode'];
      final isFound = code is num && code.toInt() == 0;

      if (!mounted) return;
      setState(() {
        _transactionFound = isFound;
        _statusMessage = isFound
            ? 'Bakong returned a matching transaction. The order still needs final payment confirmation from the server.'
            : (response['responseMessage']?.toString() ??
                  'No completed transaction was found yet. If you just paid, wait a moment and check again.');
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage =
            error is ApiException && !error.message.startsWith('/api/')
            ? error.message
            : 'Unable to check payment status. Please try again.';
      });
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F9),
      appBar: AppBar(
        title: const Text('Bakong KHQR Payment'),
        backgroundColor: _brandColor,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 4),
            const Icon(Icons.qr_code_2_rounded, size: 36, color: _brandColor),
            const SizedBox(height: 10),
            const Text(
              'Scan to pay',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            const Text(
              'Open a supported banking app and scan this KHQR code.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _mutedColor, fontSize: 13),
            ),
            const SizedBox(height: 22),
            Center(
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: QrImageView(
                  data: widget.qrPayload,
                  version: QrVersions.auto,
                  size: 250,
                  backgroundColor: Colors.white,
                  errorCorrectionLevel: QrErrorCorrectLevel.M,
                ),
              ),
            ),
            const SizedBox(height: 22),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE8E8EC)),
              ),
              child: Column(
                children: [
                  const Text(
                    'Amount to pay',
                    style: TextStyle(color: _mutedColor, fontSize: 13),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${widget.currency} ${widget.amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: _brandColor,
                    ),
                  ),
                  const Divider(height: 26),
                  _detailRow('Order number', '#${widget.orderId}'),
                  const SizedBox(height: 10),
                  _detailRow('Payment method', 'Bakong KHQR'),
                  const SizedBox(height: 10),
                  _detailRow('Expires in', '15 minutes'),
                ],
              ),
            ),
            const SizedBox(height: 18),
            if (_statusMessage != null || _errorMessage != null)
              Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: _errorMessage != null
                      ? const Color(0xFFFFF0F0)
                      : (_transactionFound
                            ? const Color(0xFFEAF7EF)
                            : const Color(0xFFFFF7E6)),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      _errorMessage != null
                          ? Icons.error_outline
                          : (_transactionFound
                                ? Icons.check_circle_outline
                                : Icons.info_outline),
                      color: _errorMessage != null
                          ? Colors.red
                          : (_transactionFound
                                ? Colors.green
                                : Colors.orange.shade800),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _errorMessage ?? _statusMessage!,
                        style: const TextStyle(fontSize: 12, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _checking ? null : _checkPayment,
                icon: _checking
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Icon(Icons.refresh_rounded),
                label: Text(
                  _checking
                      ? 'Checking payment...'
                      : 'I have paid — check status',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _brandColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Do not close this screen until you have saved your order number. Payment confirmation must be completed by the server before this order can be treated as paid.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _mutedColor, fontSize: 11, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Text(
          label,
          style: const TextStyle(color: _mutedColor, fontSize: 12),
        ),
      ),
      const SizedBox(width: 12),
      Flexible(
        child: Text(
          value,
          textAlign: TextAlign.right,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
    ],
  );
}
