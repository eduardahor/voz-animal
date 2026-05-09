import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'services/denuncia_service.dart';
import 'services/localizacao_service.dart';
import 'views/router_screen.dart';

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
        Provider(create: (_) => LocalizacaoService()),
      ],
      child: MaterialApp(
        title: 'Voz Animal',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          // O seu ColorScheme verde que configuramos antes!
          colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.green,
              brightness: Brightness.light),
          useMaterial3: true,
        ),
        home: const RouterScreen(),
      ),
    );
  }
}