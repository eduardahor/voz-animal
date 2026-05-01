import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/denuncia_service.dart';
import '../models/status_denuncia.dart';
import 'nova_denuncia_screen.dart';
import 'detalhe_denuncia_screen.dart';
import 'perfil_screen.dart';
import 'login_screen.dart';
import '../widgets/denuncia_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  StatusDenuncia? _filtroStatus;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final service = context.watch<DenunciaService>();

    // Garantindo que o usuário existe para evitar erros de null
    final usuario = auth.usuarioAtual;
    if (usuario == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    // Lógica de filtragem original mantida
    var denuncias = service.denunciasPorUsuario(usuario.id);
    if (_filtroStatus != null) {
      denuncias = denuncias.where((d) => d.statusDenuncia == _filtroStatus).toList();
    }

    // Contadores para os novos chips de estatísticas
    final total = service.denunciasPorUsuario(usuario.id).length;
    final pendentes = service.denunciasPorUsuario(usuario.id)
        .where((d) => d.statusDenuncia == StatusDenuncia.pendente).length;
    final resolvidas = service.denunciasPorUsuario(usuario.id)
        .where((d) => d.statusDenuncia == StatusDenuncia.resolvida).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Voz Animal'),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PerfilScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              auth.logout();
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // HEADER COLORIDO COM ESTATÍSTICAS (Adaptado do código 1)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
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
                  'Olá, ${usuario.nome}!',
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _StatChip(label: 'Total', count: total, color: Colors.white),
                      const SizedBox(width: 10),
                      _StatChip(label: 'Pendentes', count: pendentes, color: Colors.orangeAccent),
                      const SizedBox(width: 10),
                      _StatChip(label: 'Resolvidas', count: resolvidas, color: Colors.lightGreenAccent),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // FILTROS POR STATUS (Original mantido)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('Todas'),
                    selected: _filtroStatus == null,
                    onSelected: (_) => setState(() => _filtroStatus = null),
                  ),
                  const SizedBox(width: 8),
                  ...StatusDenuncia.values.map((s) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(s.label),
                      selected: _filtroStatus == s,
                      onSelected: (_) => setState(() => _filtroStatus = _filtroStatus == s ? null : s),
                    ),
                  )),
                ],
              ),
            ),
          ),

          // LISTA DE DENÚNCIAS
          Expanded(
            child: denuncias.isEmpty
                ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Nenhuma denúncia encontrada.', style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: denuncias.length,
              itemBuilder: (_, i) => DenunciaCard(
                denuncia: denuncias[i],
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => DetalheDenunciaScreen(denuncia: denuncias[i]))
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NovaDenunciaScreen())),
        icon: const Icon(Icons.add, color: Colors.white),
        backgroundColor: Theme.of(context).colorScheme.secondary,
        label: const Text('Nova Denúncia', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}

// Widget auxiliar para as estatísticas do Header
class _StatChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatChip({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        '$label: $count',
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }
}