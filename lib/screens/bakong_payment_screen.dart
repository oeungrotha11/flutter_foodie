import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../services/foodie_api.dart';
import '../services/api_client.dart';
import 'home_screen.dart';
import 'order_success_screen.dart';

const _brandColor = Color(0xFFF5233B);
const _mutedColor = Color(0xFF747782);

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
  Timer? _pollTimer;
  bool _checking = false;
  bool _completed = false;
  bool _expired = false;
  String? _statusMessage;
  String? _errorMessage;
  late final DateTime _expiresAt;

  bool get _isTestMode => widget.qrPayload.startsWith('FOODIE-TEST-NOT-PAYABLE|');

  @override
  void initState() {
    super.initState();
    _expiresAt = DateTime.now().add(const Duration(minutes: 15));
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkPayment());
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || _completed || _expired || _checking) return;
      if (DateTime.now().isAfter(_expiresAt)) {
        setState(() {
          _expired = true;
          _statusMessage = 'This QR request expired. Please create a new payment request.';
        });
        _pollTimer?.cancel();
      } else {
        _checkPayment();
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _confirmLeavePayment() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Leave payment screen?'),
        content: Text('Order #${widget.orderId} has already been created. Leaving this screen will not cancel the order or payment request.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Stay here')),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(backgroundColor: _brandColor, foregroundColor: Colors.white),
            child: const Text('Leave payment'),
          ),
        ],
      ),
    );
    if (leave == true && mounted) {
      _pollTimer?.cancel();
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomeScreen()), (route) => false);
    }
  }

  Future<void> _checkPayment() async {
    if (_checking || _completed || _expired) return;
    setState(() {
      _checking = true;
      _errorMessage = null;
    });
    try {
      final response = await FoodieApi.instance.checkBakongTransaction(widget.md5);
      final code = response['responseCode'];
      final isFound = code is num && code.toInt() == 0;
      if (!mounted) return;

      // Never treat the backend's simulated test-mode response as a real payment.
      if (isFound && !_isTestMode) {
        _completed = true;
        _pollTimer?.cancel();
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => OrderSuccessScreen(total: widget.amount, orderId: widget.orderId)),
          (route) => false,
        );
        return;
      }

      setState(() {
        _statusMessage = isFound
            ? 'TEST MODE only: this is simulated. No money was transferred.'
            : (response['responseMessage']?.toString() ?? 'Waiting for Bakong payment confirmation. Checking automatically every 5 seconds.');
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error is ApiException && !error.message.startsWith('/api/')
            ? error.message
            : 'Unable to check payment status. Will retry automatically.';
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
        leading: IconButton(tooltip: 'Back to shopping', icon: const Icon(Icons.arrow_back_rounded), onPressed: _confirmLeavePayment),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 4),
            const Icon(Icons.qr_code_2_rounded, size: 36, color: _brandColor),
            const SizedBox(height: 10),
            const Text('Scan to pay', textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            const Text('Open a supported banking app and scan this KHQR code.', textAlign: TextAlign.center, style: TextStyle(color: _mutedColor, fontSize: 13)),
            const SizedBox(height: 22),
            if (_isTestMode) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFFFFF0D9), borderRadius: BorderRadius.circular(12)),
                child: const Text('DEVELOPMENT TEST MODE: this QR is fake and cannot be paid. No money will be transferred.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF8A4B00), fontSize: 12, height: 1.4, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 14),
            ],
            Center(
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 8))]),
                child: QrImageView(data: widget.qrPayload, version: QrVersions.auto, size: 250, backgroundColor: Colors.white, errorCorrectionLevel: QrErrorCorrectLevel.M),
              ),
            ),
            const SizedBox(height: 22),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE8E8EC))),
              child: Column(
                children: [
                  const Text('Amount to pay', style: TextStyle(color: _mutedColor, fontSize: 13)),
                  const SizedBox(height: 5),
                  Text('${widget.currency} ${widget.amount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: _brandColor)),
                  const Divider(height: 26),
                  _detailRow('Order number', '#${widget.orderId}'),
                  const SizedBox(height: 10),
                  _detailRow('Payment method', 'Bakong KHQR'),
                  const SizedBox(height: 10),
                  _detailRow('Expires in', _expired ? 'Expired' : '15 minutes'),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: _errorMessage != null ? const Color(0xFFFFF0F0) : const Color(0xFFEFF4FF), borderRadius: BorderRadius.circular(14)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_checking) const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) else Icon(_errorMessage != null ? Icons.error_outline : Icons.info_outline, color: _errorMessage != null ? Colors.red : Colors.blue),
                  const SizedBox(width: 10),
                  Expanded(child: Text(_errorMessage ?? _statusMessage ?? (_expired ? 'Payment request expired.' : 'Waiting for confirmation. This screen checks automatically every 5 seconds.'), style: const TextStyle(fontSize: 12, height: 1.4))),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text('This screen completes checkout only when Bakong reports a live transaction. Do not pay the same QR more than once.', textAlign: TextAlign.center, style: TextStyle(color: _mutedColor, fontSize: 11, height: 1.4)),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(child: Text(label, style: const TextStyle(color: _mutedColor, fontSize: 12))),
      const SizedBox(width: 12),
      Flexible(child: Text(value, textAlign: TextAlign.right, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
    ],
  );
}
