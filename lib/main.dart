import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'repositories/denuncia_repository.dart';
import 'services/auth_service.dart';
import 'services/denuncia_service.dart';
import 'services/font_scale_service.dart';
import 'services/localizacao_service.dart';
import 'views/router_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const VozAnimalApp());
}

class VozAnimalApp extends StatelessWidget {
  const VozAnimalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        Provider(create: (_) => DenunciaRepository()),
        ChangeNotifierProxyProvider<DenunciaRepository, DenunciaService>(
          create: (ctx) =>
              DenunciaService(repo: ctx.read<DenunciaRepository>()),
          update: (_, repo, prev) => prev ?? DenunciaService(repo: repo),
        ),
        Provider(create: (_) => LocalizacaoService()),
        ChangeNotifierProvider(create: (_) => FontScaleService()),
      ],
      child: MaterialApp(
        title: 'Voz Animal',
        debugShowCheckedModeBanner: false,
        builder: (context, child) {
          final fontScale = context.watch<FontScaleService>();
          final mediaQuery = MediaQuery.of(context);

          // Respeita a configuração de acessibilidade do sistema (já
          // limitada a 1.0–1.4x) e aplica o ajuste manual do usuário
          // por cima, com uma margem de segurança para o layout.
          final escalaDoSistema = mediaQuery.textScaler
              .clamp(minScaleFactor: 1.0, maxScaleFactor: 1.4)
              .scale(1.0);
          final escalaCombinada =
              (escalaDoSistema * fontScale.scale).clamp(0.85, 1.8);

          return MediaQuery(
            data: mediaQuery.copyWith(
              textScaler: TextScaler.linear(escalaCombinada),
            ),
            child: child!,
          );
        },
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.green,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          iconButtonTheme: IconButtonThemeData(
            style: ButtonStyle(
              minimumSize: WidgetStateProperty.all(const Size(48, 48)),
            ),
          ),
        ),
        home: const RouterScreen(),
      ),
    );
  }
}
