import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/denuncia_service.dart';
import '../../models/denuncia.dart';
import '../../models/classificacao_urgencia.dart';
import '../../models/tipo_ocorrencia.dart';
import '../../models/status_denuncia.dart';
import '../auth/escolha_perfil_screen.dart';
import '../usuario/perfil_screen.dart';
import 'detalhes_denuncia_orgao_screen.dart';
import 'relatorios_screen.dart';

class HomeOrgaoScreen extends StatelessWidget {
  const HomeOrgaoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Painel de Triagem'),
          backgroundColor: Colors.green.shade700,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.bar_chart),
              tooltip: 'Relatórios e Estatísticas',
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const RelatoriosScreen()));
              },
            ),
            IconButton(
              icon: const Icon(Icons.person),
              tooltip: 'Meu Perfil',
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const PerfilScreen()));
              },
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Sair da Conta',
              onPressed: () async {
                await auth.logout();
                if (!context.mounted) return;
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const EscolhaPerfilScreen()),
                  (_) => false,
                );
              },
            ),
          ],
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            indicatorColor: Colors.white,
            tabs: [
              Tab(icon: Icon(Icons.fiber_new), text: 'Novos Casos'),
              Tab(icon: Icon(Icons.engineering), text: 'Meus Casos'),
              Tab(icon: Icon(Icons.archive_outlined), text: 'Finalizados'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _ListaDenuncias(tipoAba: 'novos'),
            _ListaDenuncias(tipoAba: 'meus'),
            _ListaDenuncias(tipoAba: 'finalizados'),
          ],
        ),
      ),
    );
  }
}

class _ListaDenuncias extends StatelessWidget {
  final String tipoAba;
  const _ListaDenuncias({required this.tipoAba});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    
    if (authService.usuarioAtual == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final orgaoId = authService.usuarioAtual!.id;
    final service = Provider.of<DenunciaService>(context);

    Stream<List<Denuncia>> stream;
    if (tipoAba == 'novos') {
      stream = service.casosAbertos;
    } else if (tipoAba == 'meus') {
      stream = service.meusCasosOrgao(orgaoId);
    } else {
      stream = service.casosFinalizadosOrgao(orgaoId);
    }

    return StreamBuilder<List<Denuncia>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text('Sessão encerrada.'));
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

        final denuncias = snapshot.data ?? [];
        if (denuncias.isEmpty) {
          String mensagemVazia = 'Nenhum caso por aqui! 🎉';
          if (tipoAba == 'novos') mensagemVazia = 'Nenhum caso novo no momento! 🎉';
          if (tipoAba == 'meus') mensagemVazia = 'Você não tem casos em andamento.';
          if (tipoAba == 'finalizados') mensagemVazia = 'Nenhum caso finalizado ainda.';
          return Center(child: Text(mensagemVazia, style: const TextStyle(fontSize: 16, color: Colors.grey)));
        }

        denuncias.sort((a, b) => b.urgencia.prioridade.compareTo(a.urgencia.prioridade));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: denuncias.length,
          itemBuilder: (context, index) {
            final d = denuncias[index];
            Color corUrgencia = d.urgencia == ClassificacaoUrgencia.critica ? Colors.red.shade700 : d.urgencia == ClassificacaoUrgencia.alta ? Colors.orange.shade700 : d.urgencia == ClassificacaoUrgencia.media ? Colors.amber.shade700 : Colors.blue.shade700;

            return Card(
              elevation: 4,
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Chip(label: Text(d.tipo.label, style: const TextStyle(fontWeight: FontWeight.bold)), backgroundColor: Colors.grey.shade200),
                        Chip(label: Text(d.urgencia.label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), backgroundColor: corUrgencia),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(d.descricao, style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.grey, size: 18),
                        const SizedBox(width: 6),
                        Expanded(child: Text(d.localizacao?.resumo() ?? 'Local não informado', style: const TextStyle(color: Colors.grey, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                    const Divider(height: 24),
                    if (tipoAba == 'novos') ...[
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.pan_tool_outlined),
                          label: const Text('PEGAR DENÚNCIA (ASSUMIR)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                          onPressed: () async {
                            await service.alterarStatus(denunciaId: d.id, novoStatus: StatusDenuncia.emAndamento, orgaoId: orgaoId);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Caso movido para "Meus Casos"!'), backgroundColor: Colors.green));
                          },
                        ),
                      )
                    ] else ...[
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: OutlinedButton.icon(
                          icon: Icon(tipoAba == 'meus' ? Icons.edit_note : Icons.visibility),
                          label: Text(tipoAba == 'meus' ? 'ALTERAR STATUS / FINALIZAR' : 'VER DETALHES DO HISTÓRICO', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          style: OutlinedButton.styleFrom(foregroundColor: tipoAba == 'meus' ? Colors.green.shade700 : Colors.grey.shade700, side: BorderSide(color: tipoAba == 'meus' ? Colors.green.shade700 : Colors.grey.shade400), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => DetalhesDenunciaOrgaoScreen(denuncia: d)));
                          },
                        ),
                      )
                    ]
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}