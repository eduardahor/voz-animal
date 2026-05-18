import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'auth/escolha_perfil_screen.dart';
import 'orgao/home_orgao_screen.dart';
import 'usuario/home_usuario_screen.dart';

class RouterScreen extends StatelessWidget {
  const RouterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    // Proteção contra o loop de carregamento infinito no logout
    if (auth.usuarioAtual == null) {
      return const EscolhaPerfilScreen();
    }

    if (auth.isOrgao) {
      return const HomeOrgaoScreen();
    } else {
      return const HomeUsuarioScreen();
    }
  }
}