import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'auth/auth_provider.dart';
import 'screens/client_home_screen.dart';
import 'screens/home_shell.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const StockSyncApp());
}

class StockSyncApp extends StatelessWidget {
  const StockSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          // Monochrome black & white theme for a clean professional UI
          const primaryColor = Color(0xFF000000); // Black
          const backgroundColor = Color(0xFFFFFFFF); // White
          const surfaceColor = Color(0xFFF8F8F8); // subtle off-white for cards
          const onSurfaceText = Color(0xFF111111); // dark text

          final colorScheme = ColorScheme.light(
            primary: primaryColor,
            onPrimary: Colors.white,
            background: backgroundColor,
            surface: surfaceColor,
            onSurface: onSurfaceText,
            brightness: Brightness.light,
          );

          return MaterialApp(
            title: 'StockSync',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              colorScheme: colorScheme,
              useMaterial3: true,
              scaffoldBackgroundColor: backgroundColor,
              cardColor: surfaceColor,
              appBarTheme: const AppBarTheme(
                backgroundColor: backgroundColor,
                foregroundColor: onSurfaceText,
                elevation: 1,
                centerTitle: false,
              ),
              textTheme: ThemeData.light().textTheme.apply(
                    bodyColor: onSurfaceText,
                    displayColor: onSurfaceText,
                  ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              outlinedButtonTheme: OutlinedButtonThemeData(
                style: OutlinedButton.styleFrom(
                  foregroundColor: onSurfaceText,
                  side: const BorderSide(color: Colors.black12),
                ),
              ),
              cardTheme: const CardThemeData(
                elevation: 0,
                margin: EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
              ),
              bottomNavigationBarTheme: BottomNavigationBarThemeData(
                backgroundColor: backgroundColor,
                selectedItemColor: primaryColor,
                unselectedItemColor: onSurfaceText.withOpacity(0.6),
                showUnselectedLabels: true,
                elevation: 4,
              ),
            ),
            home: auth.isAuthenticated
                ? (auth.currentUser?.role == 'client'
                    ? const ClientHomeScreen()
                    : const HomeShell())
                : const LoginScreen(),
          );
        },
      ),
    );
  }
}
