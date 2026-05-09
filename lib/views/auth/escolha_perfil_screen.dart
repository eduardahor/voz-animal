import 'package:flutter/material.dart';
import '../../models/tipo_usuario.dart';
import 'login_screen.dart';

class EscolhaPerfilScreen extends StatelessWidget {
  const EscolhaPerfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.pets, size: 80, color: Colors.green),
              const SizedBox(height: 16),
              const Text('Voz Animal',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Como você quer entrar?',
                  style: TextStyle(fontSize: 16, color: Colors.black54)),
              const SizedBox(height: 40),
              _PerfilCard(
                icon: Icons.person,
                titulo: 'Sou Cidadão',
                subtitulo: 'Quero registrar denúncias e acompanhar.',
                cor: Colors.blue.shade700,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          const LoginScreen(tipo: TipoUsuario.cidadao)),
                ),
              ),
              const SizedBox(height: 16),
              _PerfilCard(
                icon: Icons.verified_user,
                titulo: 'Sou Órgão Responsável',
                subtitulo: 'Quero receber e gerenciar denúncias.',
                cor: Colors.green.shade700,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          const LoginScreen(tipo: TipoUsuario.orgao)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PerfilCard extends StatelessWidget {
  final IconData icon;
  final String titulo;
  final String subtitulo;
  final Color cor;
  final VoidCallback onTap;
  const _PerfilCard({
    required this.icon,
    required this.titulo,
    required this.subtitulo,
    required this.cor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: cor, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titulo,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(subtitulo,
                        style: const TextStyle(color: Colors.black54)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
