import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/status_denuncia.dart';
import '../../services/auth_service.dart';
import '../../services/denuncia_service.dart';
import '../auth/escolha_perfil_screen.dart';
import 'minhas_denuncias_screen.dart';
import 'nova_denuncia_screen.dart';
import 'perfil_screen.dart';

class HomeUsuarioScreen extends StatelessWidget {
  const HomeUsuarioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final svc = context.watch<DenunciaService>();
    final usuario = auth.usuarioAtual!;
    final minhas = svc.doUsuario(usuario.id);

    final emAnalise =
        minhas.where((d) => d.status == StatusDenuncia.emAnalise).length;
    final resolvidas =
        minhas.where((d) => d.status == StatusDenuncia.resolvida).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Voz Animal'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            tooltip: 'Meu Perfil',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PerfilScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: () {
              auth.logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                    builder: (_) => const EscolhaPerfilScreen()),
                (_) => false,
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Olá, ${usuario.nome}',
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('Sua voz protege quem não pode falar.',
                style: TextStyle(color: Colors.black54)),
            const SizedBox(height: 24),

            // Estatísticas resumidas
            Row(
              children: [
                _Stat(label: 'Total', valor: '${minhas.length}'),
                const SizedBox(width: 8),
                _Stat(
                    label: 'Em análise',
                    valor: '$emAnalise',
                    cor: Colors.orange),
                const SizedBox(width: 8),
                _Stat(
                    label: 'Resolvidas',
                    valor: '$resolvidas',
                    cor: Colors.green),
              ],
            ),
            const SizedBox(height: 32),

            // Botão circular DENUNCIE AQUI
            Center(
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const NovaDenunciaScreen()),
                ),
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Colors.red.shade400, Colors.red.shade800],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withValues(alpha: 0.4),
                        blurRadius: 20,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.campaign,
                          color: Colors.white, size: 56),
                      SizedBox(height: 8),
                      Text('DENUNCIE\nAQUI',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          )),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Card minhas denúncias
            Card(
              child: ListTile(
                leading: Icon(Icons.list_alt,
                    color: Colors.blue.shade700, size: 32),
                title: const Text('Minhas Denúncias',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle:
                    Text('Acompanhe o status das suas ${minhas.length} denúncias'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const MinhasDenunciasScreen()),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String valor;
  final Color? cor;
  const _Stat({required this.label, required this.valor, this.cor});

  @override
  Widget build(BuildContext context) {
    final c = cor ?? Colors.blue.shade700;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(valor,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: c)),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
