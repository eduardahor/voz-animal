import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/denuncia.dart';
import '../../models/status_denuncia.dart';
import '../../models/tipo_ocorrencia.dart';
import '../../services/auth_service.dart';
import '../../services/denuncia_service.dart';
import '../foto_denuncia.dart';
import '../shared/font_size_controls.dart';
import 'detalhe_denuncia_usuario_screen.dart';
import 'nova_denuncia_screen.dart';

class MinhasDenunciasScreen extends StatefulWidget {
  const MinhasDenunciasScreen({super.key});

  @override
  State<MinhasDenunciasScreen> createState() =>
      _MinhasDenunciasScreenState();
}

class _MinhasDenunciasScreenState extends State<MinhasDenunciasScreen> {
  StatusDenuncia? _filtro;

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<AuthService>().usuarioAtual!;
    final svc     = context.read<DenunciaService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Denúncias'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: const [FontSizeControls()],
      ),
      body: StreamBuilder<List<Denuncia>>(
        stream: svc.doCidadao(usuario.id),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final todas     = snap.data ?? [];
          final filtradas = _filtro == null
              ? todas
              : todas.where((d) => d.status == _filtro).toList();

          return Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    _chip('Todas', null),
                    ...StatusDenuncia.values
                        .map((s) => _chip(s.label, s)),
                  ],
                ),
              ),

              Expanded(
                child: filtradas.isEmpty
                    ? _vazio(context)
                    : ListView.separated(
                        padding: const EdgeInsets.all(8),
                        itemCount: filtradas.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          final d = filtradas[i];
                          return Card(
                            child: ListTile(
                              leading: FotoDenuncia(
                                path: d.fotoUrl,
                                width: 56,
                                height: 56,
                              ),
                              title: Text(d.tipo.label,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(d.descricao,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis),
                                  Text('Status: ${d.status.label}',
                                      style: const TextStyle(
                                          color: Colors.black54)),
                                ],
                              ),
                              isThreeLine: true,
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      DetalheDenunciaUsuarioScreen(
                                          denuncia: d),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _chip(String label, StatusDenuncia? status) {
    final sel = _filtro == status;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(label),
        selected: sel,
        onSelected: (_) => setState(() => _filtro = status),
      ),
    );
  }

  Widget _vazio(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          const Text('Nenhuma denúncia ainda',
              style: TextStyle(fontSize: 18)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const NovaDenunciaScreen()),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Fazer primeira denúncia'),
          ),
        ],
      ),
    ),
  );
}
