import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/denuncia_service.dart';
import '../models/status_denuncia.dart';
import '../widgets/denuncia_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Carrega dados de exemplo na primeira vez
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthService>();
      final denunciaService = context.read<DenunciaService>();
      if (auth.usuarioLogado != null) {
        denunciaService.carregarDadosExemplo(
          auth.usuarioLogado!.id,
          auth.usuarioLogado!.nome,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final denunciaService = context.watch<DenunciaService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Voz Animal'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.pushNamed(context, '/perfil'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Header com estatísticas
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Olá, \${auth.usuarioLogado?.nome ?? "Usuário"}!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _StatChip(
                      label: 'Total',
                      count: denunciaService.denuncias.length,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 12),
                    _StatChip(
                      label: 'Pendentes',
                      count: denunciaService.denunciasPendentes.length,
                      color: const Color(0xFFFFA726),
                    ),
                    const SizedBox(width: 12),
                    _StatChip(
                      label: 'Resolvidas',
                      count: denunciaService.denunciasResolvidas.length,
                      color: const Color(0xFF66BB6A),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Lista de denúncias
          Expanded(
            child: denunciaService.denuncias.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Nenhuma denúncia registrada',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: denunciaService.denuncias.length,
                    itemBuilder: (context, index) {
                      final denuncia = denunciaService.denuncias[index];
                      return DenunciaCard(
                        denuncia: denuncia,
                        onTap: () => Navigator.pushNamed(
                          context,
                          '/detalhe-denuncia',
                          arguments: denuncia.id,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/nova-denuncia'),
        backgroundColor: Theme.of(context).colorScheme.secondary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nova Denúncia', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatChip({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '\$label: \$count',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }
}
