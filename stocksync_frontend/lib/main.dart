import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'auth/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'screens/client_home_screen.dart';
import 'screens/home_shell.dart';
import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';

void main() {
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.dumpErrorToConsole(details);
  };

  runZonedGuarded(() {
    runApp(const VVPApp());
  }, (error, stack) {
    print('Uncaught zone error: $error');
    print(stack);
  });
}

class VVPApp extends StatefulWidget {
  const VVPApp({super.key});

  @override
  State<VVPApp> createState() => _VVPAppState();
}

class _VVPAppState extends State<VVPApp> {
  bool _hasShownSplash = false;

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          const primaryColor = Color(0xFF4361EE);
          const primaryDark = Color(0xFF3A0CA3);
          const bgColor = Color(0xFFF0F4FF);

          final colorScheme = ColorScheme.fromSeed(
            seedColor: primaryColor,
            brightness: Brightness.light,
            background: bgColor,
            surface: Colors.white,
            primary: primaryColor,
            secondary: const Color(0xFF4CC9F0),
          );

          return MaterialApp(
            title: 'VVP',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              colorScheme: colorScheme,
              useMaterial3: true,
              scaffoldBackgroundColor: bgColor,
              fontFamily: 'Roboto',
              appBarTheme: const AppBarTheme(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                centerTitle: false,
                systemOverlayStyle: SystemUiOverlayStyle.light,
              ),
              cardTheme: CardThemeData(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                shadowColor: const Color(0x1A4361EE),
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: const Color(0xFFEEF2FF),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: primaryColor, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                labelStyle: const TextStyle(color: Color(0xFF6B7A9D)),
                hintStyle: const TextStyle(color: Color(0xFF6B7A9D)),
              ),
              bottomNavigationBarTheme: BottomNavigationBarThemeData(
                backgroundColor: Colors.white,
                selectedItemColor: primaryColor,
                unselectedItemColor: const Color(0xFF6B7A9D),
                showUnselectedLabels: true,
                type: BottomNavigationBarType.fixed,
                elevation: 12,
                selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              ),
              floatingActionButtonTheme: const FloatingActionButtonThemeData(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                elevation: 4,
              ),
              snackBarTheme: SnackBarThemeData(
                behavior: SnackBarBehavior.floating,
                backgroundColor: primaryDark,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            home: !_hasShownSplash
                ? AnimatedSplashScreen(
                    onFinished: () {
                      if (mounted) {
                        setState(() => _hasShownSplash = true);
                      }
                    },
                  )
                : (auth.isAuthenticated
                    ? (auth.currentUser?.role == 'client'
                        ? const ClientHomeScreen()
                        : const HomeShell())
                    : const LoginScreen()),
          );
        },
      ),
    );
  }
}
