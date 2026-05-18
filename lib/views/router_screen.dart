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
    // Escuta as mudanças de login/logout do aplicativo
    final auth = context.watch<AuthService>();

    // SE NÃO HOUVER USUÁRIO LOGADO: Manda para a tela de escolha de perfil/login
    if (auth.usuarioAtual == null) {
      return const EscolhaPerfilScreen();
    }

    // SE HOUVER USUÁRIO LOGADO: Faz a triagem do tipo de conta
    if (auth.isOrgao) {
      return const HomeOrgaoScreen();
    } else {
      return const HomeUsuarioScreen();
    }
  }
}