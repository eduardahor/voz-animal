import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'services/denuncia_service.dart';
import 'views/splash_screen.dart';
import 'views/login_screen.dart';
import 'views/home_screen.dart';
import 'views/cadastro_screen.dart';
import 'views/nova_denuncia_screen.dart';
import 'views/detalhe_denuncia_screen.dart';
import 'views/perfil_screen.dart';

void main() {
  runApp(const VozAnimalApp());
}

class VozAnimalApp extends StatelessWidget {
  const VozAnimalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => DenunciaService()),
      ],
      child: MaterialApp(
        title: 'Voz Animal',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2E7D32),
            primary: const Color(0xFF2E7D32),
            secondary: const Color(0xFFFF8F00),
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF2E7D32),
            foregroundColor: Colors.white,
            elevation: 2,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          cardTheme: CardThemeData(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/login': (context) => const LoginScreen(),
          '/cadastro': (context) => const CadastroScreen(),
          '/home': (context) => const HomeScreen(),
          '/nova-denuncia': (context) => const NovaDenunciaScreen(),
          '/perfil': (context) => const PerfilScreen(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == '/detalhe-denuncia') {
            final denunciaId = settings.arguments as String;
            return MaterialPageRoute(
              builder: (context) => DetalheDenunciaScreen(denunciaId: denunciaId),
            );
          }
          return null;
        },
      ),
    );
  }
}
