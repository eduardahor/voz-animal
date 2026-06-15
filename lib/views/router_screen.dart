import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'auth/escolha_perfil_screen.dart';
import 'usuario/home_usuario_screen.dart';
import 'orgao/home_orgao_screen.dart';

class RouterScreen extends StatelessWidget {
  const RouterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (_, auth, __) {
        if (auth.carregandoSessao) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.pets, size: 72, color: Colors.green),
                  SizedBox(height: 24),
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Carregando...', style: TextStyle(color: Colors.black54)),
                ],
              ),
            ),
          );
        }

        if (!auth.logado)   return const EscolhaPerfilScreen();
        if (auth.isOrgao)   return const HomeOrgaoScreen();
        return const HomeUsuarioScreen();
      },
    );
  }
}
