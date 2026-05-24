import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'repositories/denuncia_repository.dart';
import 'services/auth_service.dart';
import 'services/denuncia_service.dart';
import 'services/localizacao_service.dart';
import 'views/router_screen.dart';
 import 'firebase_options.dart'; // gerado por: flutterfire configure

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
      ],
      child: MaterialApp(
        title: 'Voz Animal',
        debugShowCheckedModeBanner: false,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: MediaQuery.of(context).textScaler.clamp(
                  minScaleFactor: 1.0,
                  maxScaleFactor: 1.4,
                ),
          ),
          child: child!,
        ),
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
