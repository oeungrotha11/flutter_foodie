import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../services/foodie_api.dart';
import 'login_screen.dart';

class VerifyEmailScreen extends StatefulWidget {
  final String email;
  const VerifyEmailScreen({super.key, required this.email});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _code = TextEditingController();
  bool _loading = false;
  bool _resending = false;

  Future<void> _verify() async {
    if (_loading || !_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await FoodieApi.instance.verifyEmail(email: widget.email, code: _code.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Email verified. You can now log in.'),
        backgroundColor: Colors.green,
      ));
      Navigator.pushAndRemoveUntil(context,
        MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e is ApiException ? e.message : 'Could not verify email. Try again.'),
        backgroundColor: Colors.red,
      ));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    if (_resending || _loading) return;
    setState(() => _resending = true);
    try {
      await FoodieApi.instance.resendVerificationCode(widget.email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('A new code has been sent to your email.'),
        backgroundColor: Colors.green,
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e is ApiException ? e.message : 'Could not resend code. Try again.'),
        backgroundColor: Colors.red,
      ));
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(child: Center(child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Form(key: _formKey, child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.mark_email_read_outlined, size: 76, color: Color(0xFFF5233B)),
            const SizedBox(height: 24),
            const Text('Verify your email', textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text('Enter the 6-digit code we sent to:', textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(widget.email, textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 28),
            TextFormField(
              controller: _code,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, letterSpacing: 8),
              decoration: InputDecoration(
                labelText: '6-digit code',
                counterText: '',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              validator: (value) => value != null && RegExp(r'^[0-9]{6}$').hasMatch(value.trim())
                ? null : 'Enter the 6-digit code from your email',
            ),
            const SizedBox(height: 18),
            SizedBox(height: 46, child: ElevatedButton(
              onPressed: _loading ? null : _verify,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF5233B),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: _loading ? const SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Verify email'),
            )),
            TextButton(
              onPressed: (_resending || _loading) ? null : _resend,
              child: _resending ? const CircularProgressIndicator()
                : const Text('Resend verification code', style: TextStyle(color: Color(0xFFF5233B))),
            ),
            TextButton(
              onPressed: () => Navigator.pushAndRemoveUntil(context,
                MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false),
              child: const Text('Back to login', style: TextStyle(color: Colors.black54)),
            ),
          ],
        )),
      ))),
    );
  }
}
