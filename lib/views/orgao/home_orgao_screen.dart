import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/classificacao_urgencia.dart';
import '../../models/status_denuncia.dart';
import '../../models/tipo_ocorrencia.dart';
import '../../services/auth_service.dart';
import '../../services/denuncia_service.dart';
import '../foto_denuncia.dart';
import '../usuario/perfil_screen.dart';
import 'detalhe_denuncia_orgao_screen.dart';
import 'relatorios_screen.dart';

class HomeOrgaoScreen extends StatelessWidget {
  const HomeOrgaoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final svc = context.watch<DenunciaService>();
    final denuncias = [...svc.todas]
      ..sort((a, b) =>
          b.urgencia.prioridade.compareTo(a.urgencia.prioridade));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Painel do Órgão'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Relatórios',
            icon: const Icon(Icons.assessment),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RelatoriosScreen()),
            ),
          ),
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
              context.read<AuthService>().logout();
            },
          ),
        ],
      ),
      body: denuncias.isEmpty
          ? const Center(child: Text('Nenhuma denúncia recebida.'))
          : ListView.separated(
              padding: const EdgeInsets.all(8),
              itemCount: denuncias.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final d = denuncias[i];
                return Card(
                  child: ListTile(
                    leading:
                        FotoDenuncia(path: d.fotoPath, width: 56, height: 56),
                    title: Text('${d.tipo.label} — ${d.urgencia.label}',
                        style:
                            const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      '${d.status.label}\n${d.descricao}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    isThreeLine: true,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            DetalheDenunciaOrgaoScreen(denuncia: d),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
