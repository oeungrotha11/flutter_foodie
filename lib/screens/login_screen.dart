import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';
import 'package:pos_product/screens/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  bool _obscurePassword = true;

  final TextEditingController emailController = TextEditingController();

  final TextEditingController passwordController = TextEditingController();

  // Login
  Future<void> signIn() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();

    // Get registered account
    final savedEmail = prefs.getString('sv11-12.pos_mobile.email');

    final savedPassword = prefs.getString('sv11-12.pos_mobile.password');

    // No account
    if (savedEmail == null || savedPassword == null) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No account found. Please register first.'),
          backgroundColor: Colors.red,
        ),
      );

      return;
    }

    // Check credentials
    if (emailController.text.trim() == savedEmail &&
        passwordController.text == savedPassword) {
      // Save login token
      await prefs.setString(
        'sv11-12.pos_mobile.token',
        'local_logged_in_token',
      );

      if (!mounted) return;

      // Show success dialog
      await showDialog(
        context: context,
        barrierDismissible: false,

        builder: (dialogContext) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),

            child: Padding(
              padding: const EdgeInsets.all(24),

              child: Column(
                mainAxisSize: MainAxisSize.min,

                children: [
                  // Success Animation
                  SizedBox(
                    height: 150,
                    width: 150,

                    child: Lottie.asset(
                      'assets/lotties/success.json',
                      repeat: false,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Title
                  const Text(
                    'Login Successful!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Description
                  const Text(
                    'Welcome! You have successfully logged in.',
                    textAlign: TextAlign.center,

                    style: TextStyle(fontSize: 15, color: Colors.grey),
                  ),

                  const SizedBox(height: 25),

                  // Continue button
                  SizedBox(
                    width: double.infinity,
                    height: 50,

                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,

                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),

                      onPressed: () {
                        // Close dialog
                        Navigator.pop(dialogContext);

                        // Go Home
                        Navigator.pushAndRemoveUntil(
                          context,

                          MaterialPageRoute(
                            builder: (context) => const HomeScreen(),
                          ),

                          (route) => false,
                        );
                      },

                      child: const Text(
                        'Continue',

                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } else {
      // Wrong email/password
      if (!mounted) return;

      await showDialog(
        context: context,
        barrierDismissible: true,

        builder: (dialogContext) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),

            child: Padding(
              padding: const EdgeInsets.all(24),

              child: Column(
                mainAxisSize: MainAxisSize.min,

                children: [
                  // Error Animation
                  SizedBox(
                    height: 120,
                    width: 120,

                    child: Lottie.asset(
                      'assets/lotties/error_sign.json',
                      repeat: false,
                    ),
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    'Login Failed',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    'The email or password you entered is incorrect. Please try again.',
                    textAlign: TextAlign.center,

                    style: TextStyle(fontSize: 15, color: Colors.grey),
                  ),

                  const SizedBox(height: 25),

                  SizedBox(
                    width: double.infinity,
                    height: 50,

                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,

                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),

                      onPressed: () {
                        Navigator.pop(dialogContext);
                      },

                      child: const Text(
                        'Try Again',

                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),

            child: Form(
              key: _formKey,

              child: Column(
                children: [
                  const SizedBox(height: 70),

                  const Text(
                    "Login",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),

                  const SizedBox(height: 55),

                  // Email
                  _buildTextFormField(
                    labelText: "Email",
                    controller: emailController,
                    hintText: "Enter email",
                    icon: Icons.email,
                    keyboardType: TextInputType.emailAddress,

                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your email';
                      }

                      final emailRegex = RegExp(
                        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                      );

                      if (!emailRegex.hasMatch(value.trim())) {
                        return 'Please enter a valid email';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 14),

                  // Password
                  _buildTextFormField(
                    labelText: "Password",
                    controller: passwordController,
                    hintText: "Enter password",
                    icon: Icons.lock,
                    obscureText: _obscurePassword,

                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }

                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }

                      return null;
                    },

                    suffixIcon: IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 35,
                        minHeight: 35,
                      ),
                      splashRadius: 18,
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },

                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        size: 17,
                        color: Colors.black87,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Login
                  SizedBox(
                    width: double.infinity,
                    height: 40,

                    child: ElevatedButton(
                      onPressed: signIn,

                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF5233B),
                        foregroundColor: Colors.white,
                        elevation: 0,

                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),

                      child: const Text(
                        "LOGIN",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 26),

                  Row(
                    children: [
                      const Expanded(
                        child: Divider(thickness: 1, color: Colors.grey),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'or continue with',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                      const Expanded(
                        child: Divider(thickness: 1, color: Colors.grey),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  _buildSocialLoginButton(
                    label: 'Continue with Facebook',
                    leading: SvgPicture.asset(
                      'assets/svg/fb.svg',
                      // colorFilter: const ColorFilter.mode(
                      //   Color.fromARGB(255, 5, 0, 156),
                      //   BlendMode.srcIn,
                      // ),
                      width: 24.0,
                      height: 24.0,
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Facebook login is coming soon.'),
                          backgroundColor: Color(0xFF1877F2),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 12),

                  _buildSocialLoginButton(
                    label: 'Continue with Google',
                    leading: SvgPicture.asset(
                      'assets/svg/google.svg',
                      // colorFilter: const ColorFilter.mode(
                      //   Color.fromARGB(255, 5, 0, 156),
                      //   BlendMode.srcIn,
                      // ),
                      width: 24.0,
                      height: 24.0,
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Google login is coming soon.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 26),

                  // Register
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Don't have an account? ",
                        style: TextStyle(fontSize: 10, color: Colors.grey),
                      ),

                      Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const RegisterScreen(),
                              ),
                            );
                          },

                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            child: Text(
                              "Register now",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFF5233B),
                                // decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialLoginButton({
    required String label,
    required Widget leading,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 42,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.grey, width: 0.8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          foregroundColor: Colors.black87,
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: Row(
          children: [
            // 1. Keeps the icon size unified on the left
            SizedBox(width: 24, height: 24, child: leading),

            // 2. Center the text in the remaining available row width
            Expanded(
              child: Text(
                label,
                textAlign:
                    TextAlign.center, // Forces text grids to perfectly align
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            // 3. Invisible spacer matching the icon width to keep text perfectly centered
          const SizedBox(width: 24), 
          ],
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String hintText,
    required String labelText,
    required IconData icon,
    required String? Function(String?) validator,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
       autovalidateMode: AutovalidateMode.onUserInteractionIfError,

      style: const TextStyle(fontSize: 12),

      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: Icon(icon, size: 16, color: const Color(0xFFF5233B)),

        labelStyle: TextStyle(fontSize:11,  color: Colors.grey),
        hintStyle: const TextStyle(fontSize: 11, color: Colors.grey),

        prefixIconConstraints: const BoxConstraints(
          minWidth: 35,
          minHeight: 35,
        ),

        suffixIcon: suffixIcon,

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: const BorderSide(color: Colors.grey, width: 0.8),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: const BorderSide(color: Colors.grey, width: 0.8),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: const BorderSide(color: Color(0xFFF5233B), width: 1),
        ),

        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: const BorderSide(color: Colors.red, width: 0.8),
        ),

        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),

        errorStyle: const TextStyle(fontSize: 10),
      ),
    );
  }
}
