import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../screens/home_screen.dart';
import '../providers/catalog_provider.dart';
import '../providers/favorite_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl_phone_field/phone_number.dart';
import '../services/foodie_api.dart';
import '../services/api_client.dart';
import 'login_screen.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String completePhoneNumber = '';

  final TextEditingController nameController = TextEditingController();

  final TextEditingController phoneController = TextEditingController();

  final TextEditingController emailController = TextEditingController();

  final TextEditingController passwordController = TextEditingController();

  final TextEditingController confirmPasswordController =
      TextEditingController();

  Future<void> register() async {
    if (_isLoading || !_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await FoodieApi.instance.register(
        username: nameController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text,
        confirm: confirmPasswordController.text,
      );
      if (completePhoneNumber.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('delivery.phone', completePhoneNumber);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration successful. Please login.'), backgroundColor: Colors.green),
      );
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(error is ApiException ? error.message : 'Unable to register. Check your connection and try again.'),
        backgroundColor: Colors.red,
      ));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> registerWithGoogle() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) return;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      final firebaseIdToken = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (firebaseIdToken == null || firebaseIdToken.isEmpty) {
        throw Exception('Could not verify your Google account. Please try again.');
      }

      // The backend verifies this Firebase token and creates/returns the Foodie account.
      await FoodieApi.instance.googleLogin(firebaseIdToken);
      if (!mounted) return;
      unawaited(context.read<CatalogProvider>().load());
      unawaited(context.read<FavoriteProvider>().load());
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (_) => false,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(error is ApiException
              ? error.message
              : 'Google registration failed. Please try again.'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();

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
                  const SizedBox(height: 50),

                  const Text(
                    "Register",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 45),

                  // Name
                  _buildTextFormField(
                    labelText: "Name",
                    controller: nameController,
                    hintText: "Your name",
                    prefixIcon: Icons.person,

                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your name';
                      }

                      if (value.trim().length < 2) {
                        return 'Name must be at least 2 characters';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 14),
                  
                  _buildPhoneFormField(
                    controller: phoneController,
                    onChanged: (phone) =>
                        completePhoneNumber = phone.completeNumber,
                    validator: (value) =>
                        (value == null || value.number.isEmpty)
                        ? 'Please enter your phone number'
                        : null,
                  ),

                  const SizedBox(height: 14),

                  // Email
                  _buildTextFormField(
                    labelText: "Email",
                    controller: emailController,
                    hintText: "Enter email",
                    prefixIcon: Icons.email,
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
                    prefixIcon: Icons.lock,
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

                  const SizedBox(height: 14),

                  // Confirm password
                  _buildTextFormField(
                    labelText: "Confirm password",
                    controller: confirmPasswordController,
                    hintText: "Enter confirm password",
                    prefixIcon: Icons.verified,
                    obscureText: _obscureConfirmPassword,

                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your password';
                      }

                      if (value != passwordController.text) {
                        return 'Passwords do not match';
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
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },

                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        size: 17,
                        color: Colors.black87,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Register button
                  SizedBox(
                    width: double.infinity,
                    height: 40,

                    child: ElevatedButton(
                      onPressed: _isLoading ? null : register,

                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF5233B),
                        foregroundColor: Colors.white,
                        elevation: 0,

                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),

                      child: _isLoading
                          ? const SizedBox(
                              width: 19,
                              height: 19,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              "CREATE ACCOUNT",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  Row(
                    children: [
                      const Expanded(child: Divider(color: Colors.grey)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'or sign up with',
                          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                        ),
                      ),
                      const Expanded(child: Divider(color: Colors.grey)),
                    ],
                  ),

                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : registerWithGoogle,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black87,
                        side: const BorderSide(color: Color(0xFFD6D6D6)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SvgPicture.asset(
                            'assets/svg/google.svg',
                            width: 22,
                            height: 22,
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Continue with Google',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  // Login
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Already have an account? ",
                        style: TextStyle(fontSize: 10, color: Colors.grey),
                      ),

                      Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LoginScreen(),
                              ),
                            );
                          },

                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            child: Text(
                              "Login now",
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

  InputDecoration _buildInputDecoration({
    String? labelText,
    required String hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,

      labelStyle: const TextStyle(fontSize: 11, color: Colors.grey),
      hintStyle: const TextStyle(fontSize: 11, color: Colors.grey),

      prefixIconConstraints: const BoxConstraints(minWidth: 35, minHeight: 35),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      errorStyle: const TextStyle(fontSize: 10),

      // Unified Borders
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
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    required IconData prefixIcon,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
    bool obscureText = false,
    void Function(String)? onChanged,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      onChanged: onChanged,
      keyboardType: keyboardType,
      obscureText: obscureText,
      autovalidateMode: AutovalidateMode.onUserInteractionIfError,
      style: const TextStyle(fontSize: 12),
      decoration: _buildInputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: Icon(prefixIcon, size: 16, color: const Color(0xFFF5233B)),
        suffixIcon: suffixIcon,
      ),
    );
  }

  Widget _buildPhoneFormField({
    required TextEditingController controller,
    required void Function(PhoneNumber) onChanged,
    required String? Function(PhoneNumber?) validator,
    String hintText = 'Phone number',
    String initialCountryCode = 'KH',
  }) {
    return IntlPhoneField(
      controller: controller,
      initialCountryCode: initialCountryCode,
      disableLengthCheck: true,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 12),
      dropdownIconPosition: IconPosition.trailing,
      flagsButtonPadding: const EdgeInsets.only(left: 5),
      dropdownIcon: const Icon(Icons.arrow_drop_down, size: 18),
      validator: validator,
      decoration: _buildInputDecoration(
        hintText: hintText,
        // Pass null to prefixIcon so IntlPhoneField can put the flag menu there naturally
      ),
    );
  }
}
