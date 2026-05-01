import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'services/denuncia_service.dart';
import 'views/splash_screen.dart';
import 'views/login_screen.dart';
import 'views/cadastro_screen.dart';
import 'views/home_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => DenunciaService()),
      ],
      child: const VozAnimalApp(),
    ),
  );
}

class VozAnimalApp extends StatelessWidget {
  const VozAnimalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Voz Animal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF2E7D32),
        useMaterial3: true,
        brightness: Brightness.light,
        cardTheme: const CardThemeData(
          elevation: 2,
          margin: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        ),
        appBarTheme: const AppBarTheme(centerTitle: true),
      ),
      home: const SplashScreen(),

      routes: {
        '/login': (context) => const LoginScreen(),
        '/registro': (context) => const CadastroScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}