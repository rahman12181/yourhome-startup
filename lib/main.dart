import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:yourhome/providers/chat_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/property_provider.dart';
import 'providers/profile_provider.dart';
import 'providers/admin_provider.dart';  
import 'screens/splash_screen.dart';
import 'services/api_service.dart';
import 'utils/theme.dart';
import 'providers/owner_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _updateSystemUIOverlay(Brightness.light);

  await ApiService().init();

  runApp(const MyApp());
}
void _updateSystemUIOverlay(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
  );

  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      // Status Bar
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: isDark 
          ? const Color(0xFF141A2C)
          : Colors.white,            
      systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => ThemeProvider(),
        ),
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(),
        ),
        ChangeNotifierProvider<PropertyProvider>(
          create: (_) => PropertyProvider(),
        ),
        ChangeNotifierProvider<ProfileProvider>(
          create: (_) => ProfileProvider(),
        ),
        ChangeNotifierProvider<AdminProvider>(
          create: (_) => AdminProvider(),
        ),
        ChangeNotifierProvider(create: (_) => OwnerProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final brightness = themeProvider.themeMode == ThemeMode.dark
                ? Brightness.dark
                : themeProvider.themeMode == ThemeMode.light
                    ? Brightness.light
                    : WidgetsBinding.instance.window.platformBrightness;
            _updateSystemUIOverlay(brightness);
          });

          return MaterialApp(
            title: 'YourHome',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const SplashScreen(),
            onGenerateRoute: (settings) {
              return null;
            },
          );
        },
      ),
    );
  }
}