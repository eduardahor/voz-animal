import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'services/auth_service.dart';
import 'services/denuncia_service.dart';
import 'services/localizacao_service.dart';
import 'views/router_screen.dart';

void main() async {
  // Escudo de proteção global para o Web
  try {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Tenta inicializar o Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Se der tudo certo, roda o app normal
    runApp(const VozAnimalApp());
    
  } catch (e) {
    // Se o Firebase capotar na inicialização, ele não quebra a tela vermelha!
    // Ele vai imprimir o erro real no console para nós vermos.
    print("ERRO FATAL NA INICIALIZAÇÃO DO FIREBASE: ${e.toString()}");
  }
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