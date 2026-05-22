import 'package:flutter/material.dart';
import 'auth/escolha_perfil_screen.dart';
import 'usuario/home_usuario_screen.dart';
import 'orgao/home_orgao_screen.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class RouterScreen extends StatelessWidget {
  const RouterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (_, auth, __) {
        if (!auth.logado) return const EscolhaPerfilScreen();
        if (auth.isOrgao) return const HomeOrgaoScreen();
        return const HomeUsuarioScreen();
      },
    );
  }
}
