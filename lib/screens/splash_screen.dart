import 'package:flutter/material.dart';
import 'package:pos_product/screens/home_screen.dart';
import 'package:pos_product/screens/login_screen.dart';
import 'package:provider/provider.dart';
import '../providers/favorite_provider.dart';
import '../services/api_client.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _textPosition;

  @override
  void initState() {
    super.initState();

    // Animation controller
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // Foodie text position
    _textPosition = Tween<double>(
      begin: 750,
      end: 380,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );

    // Start animation
    _controller.forward();

    // After animation finishes
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _checkLogin();
      }
    });
  }

  // Check whether user is already logged in
  Future<void> _checkLogin() async {
    // Wait a little after animation
    await Future.delayed(
      const Duration(milliseconds: 500),
    );

    if (!mounted) return;

    final token = await ApiClient.instance.accessToken;

    if (!mounted) return;

    // Check token
    if (token == null || token.isEmpty) {
      // No token → Login
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        ),
        (route) => false,
      );
    } else {
      await context.read<FavoriteProvider>().load();
      if (!mounted) return;
      // Token exists → Home
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const HomeScreen(),
        ),
        (route) => false,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,

        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFFF8A95),
              Color(0xFFFF3D57),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),

        child: Stack(
          children: [
            // Animated Foodie text
            AnimatedBuilder(
              animation: _textPosition,

              builder: (context, child) {
                return Positioned(
                  top: _textPosition.value,
                  left: 0,
                  right: 0,

                  child: const Center(
                    child: Text(
                      "Foodie",

                      style: TextStyle(
                        fontSize: 50,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                );
              },
            ),

            // Burger
            Positioned(
              bottom: 30,
              left: 20,
              right: 20,

              child: Image.asset(
                "assets/images/burger.png",
                height: 250,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
