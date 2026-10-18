import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:pos_product/providers/cart_provider.dart';
import 'package:pos_product/providers/favorite_provider.dart';
import 'package:pos_product/providers/navigation_provider.dart';
import 'package:pos_product/providers/catalog_provider.dart';
import 'package:pos_product/screens/splash_screen.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    DevicePreview(
      builder: (context) {
        return MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => CartProvider()),
            ChangeNotifierProvider(create: (_) => NavigationProvider()),
            ChangeNotifierProvider(create: (_) => CatalogProvider()..load()),
            ChangeNotifierProvider(create: (_) => FavoriteProvider()),
          ],
          child: const MyApp(),
        );
      },
    ),

    // MultiProvider(
    //   providers: [
    //     ChangeNotifierProvider(create: (_) => CartProvider()),
    //     ChangeNotifierProvider(
    //       create: (_) => FavoriteProvider()..load(),
    //     ),
    //     ChangeNotifierProvider(create: (_) => NavigationProvider()),
    //   ],
    //   child: const MyApp(),
    // ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'POS System',
      home: SplashScreen(),
      theme: ThemeData(
        useMaterial3: false,
        primaryColor: Colors.blue,
        fontFamily: 'Poppins',
        scaffoldBackgroundColor: Color.fromARGB(255, 255, 255, 255),
      ),
    );
  }
}
