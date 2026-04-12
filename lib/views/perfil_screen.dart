import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/denuncia_service.dart';

class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final denunciaService = context.watch<DenunciaService>();
    final usuario = auth.usuarioLogado;

    if (usuario == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Perfil')),
        body: const Center(child: Text('Usuário não encontrado')),
      );
    }

    final minhasDenuncias = denunciaService.denunciasPorUsuario(usuario.id);
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Perfil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              auth.logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Avatar
            CircleAvatar(
              radius: 50,
              backgroundColor:
                  Theme.of(context).colorScheme.primary.withOpacity(0.2),
              child: Text(
                usuario.nome.isNotEmpty ? usuario.nome[0].toUpperCase() : '?',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              usuario.nome,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              usuario.email,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            // Info cards
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _ProfileInfoTile(
                      icon: Icons.email,
                      label: 'Email',
                      value: usuario.email,
                    ),
                    const Divider(),
                    _ProfileInfoTile(
                      icon: Icons.phone,
                      label: 'Telefone',
                      value: usuario.telefone.isNotEmpty
                          ? usuario.telefone
                          : 'Não informado',
                    ),
                    const Divider(),
                    _ProfileInfoTile(
                      icon: Icons.calendar_today,
                      label: 'Membro desde',
                      value: dateFormat.format(usuario.dataCadastro),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Estatísticas
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Minhas Estatísticas',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatColumn(
                          label: 'Denúncias',
                          value: minhasDenuncias.length.toString(),
                          icon: Icons.report,
                          color: Colors.orange,
                        ),
                        _StatColumn(
                          label: 'Resolvidas',
                          value: minhasDenuncias
                              .where((d) =>
                                  d.status.descricao == 'Resolvida')
                              .length
                              .toString(),
                          icon: Icons.check_circle,
                          color: Colors.green,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileInfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileInfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey, size: 20),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Text(value, style: const TextStyle(fontSize: 15)),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatColumn({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}
