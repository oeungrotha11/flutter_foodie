import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../services/foodie_api.dart';

class AbaPayWayCheckoutScreen extends StatefulWidget {
  final int orderId;
  final String transactionId;
  final String checkoutHtml;
  final double total;

  const AbaPayWayCheckoutScreen({
    super.key,
    required this.orderId,
    required this.transactionId,
    required this.checkoutHtml,
    required this.total,
  });

  @override
  State<AbaPayWayCheckoutScreen> createState() => _AbaPayWayCheckoutScreenState();
}

class _AbaPayWayCheckoutScreenState extends State<AbaPayWayCheckoutScreen> {
  late final WebViewController _controller;
  bool _verifying = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onWebResourceError: (error) {
          // Third-party checkout resources can fail without blocking the whole page.
        },
      ))
      ..loadHtmlString(widget.checkoutHtml);
  }

  Future<void> _verifyPayment() async {
    if (_verifying) return;
    setState(() => _verifying = true);
    try {
      await FoodieApi.instance.verifyAbaPayWayPayment(
        orderId: widget.orderId,
        transactionId: widget.transactionId,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(error.toString()),
        backgroundColor: Colors.red,
      ));
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ABA PayWay'),
        backgroundColor: const Color(0xFFF5233B),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(child: WebViewWidget(controller: _controller)),
          SafeArea(
            top: false,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, -3))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Order total: \\$' + widget.total.toStringAsFixed(2),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _verifying ? null : _verifyPayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF5233B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _verifying
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('I have completed payment · Verify'),
                  ),
                  TextButton(
                    onPressed: _verifying ? null : () => Navigator.of(context).pop(false),
                    child: const Text('Cancel and return to checkout'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
