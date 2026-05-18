import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/classificacao_urgencia.dart';
import '../../models/status_denuncia.dart';
import '../../models/tipo_ocorrencia.dart';
import '../../models/denuncia.dart'; // <-- Adicionado para reconhecer a lista
import '../../services/denuncia_service.dart';
import '../../services/relatorio_service.dart';

class RelatoriosScreen extends StatelessWidget {
  const RelatoriosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Escuta a nova função que busca TODAS as denúncias do Firebase
    final streamTodas = context.read<DenunciaService>().todasAsDenuncias;

    // Colocamos o StreamBuilder por fora do Scaffold para que os botões 
    // de exportar CSV também tenham acesso aos dados atualizados!
    return StreamBuilder<List<Denuncia>>(
      stream: streamTodas,
      builder: (context, snapshot) {
        // Mostra a bolinha girando enquanto baixa os dados da nuvem
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final listaDenuncias = snapshot.data ?? [];
        
        // Agora sim, passamos a lista real baixada do Firebase para o seu gerador!
        final rel = RelatorioService(listaDenuncias);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Relatórios'),
            backgroundColor: Colors.green.shade700,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                tooltip: 'Copiar CSV',
                icon: const Icon(Icons.download),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: rel.gerarCsv()));
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('CSV copiado para a área de transferência.')),
                  );
                },
              ),
              IconButton(
                tooltip: 'Copiar resumo',
                icon: const Icon(Icons.copy),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: rel.gerarTexto()));
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Resumo copiado.')),
                  );
                },
              ),
            ],
          ),
          body: rel.total == 0
              ? const Center(child: Text('Sem dados para gerar relatório.'))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _CardsResumo(rel: rel),
                    const SizedBox(height: 16),
                    _SecaoDistribuicao(
                      titulo: 'Por status',
                      dados: rel.porStatus().map((k, v) => MapEntry(k.label, v)),
                      total: rel.total,
                    ),
                    const SizedBox(height: 16),
                    _SecaoDistribuicao(
                      titulo: 'Por tipo de ocorrência',
                      dados: rel.porTipo().map((k, v) => MapEntry(k.label, v)),
                      total: rel.total,
                    ),
                    const SizedBox(height: 16),
                    _SecaoDistribuicao(
                      titulo: 'Por urgência',
                      dados: rel.porUrgencia().map((k, v) => MapEntry(k.label, v)),
                      total: rel.total,
                    ),
                    const SizedBox(height: 24),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Pré-visualização do texto',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 8),
                            SelectableText(
                              rel.gerarTexto(),
                              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _CardsResumo extends StatelessWidget {
  final RelatorioService rel;
  const _CardsResumo({required this.rel});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _CardKpi(label: 'Total', valor: '${rel.total}', cor: Colors.blue.shade700),
        _CardKpi(label: 'Pendentes', valor: '${rel.pendentes()}', cor: Colors.orange.shade700),
        _CardKpi(label: 'Resolvidas', valor: '${rel.porStatus()[StatusDenuncia.resolvida] ?? 0}', cor: Colors.green.shade700),
        _CardKpi(label: 'Taxa resolução', valor: '${rel.taxaResolucao().toStringAsFixed(1)}%', cor: Colors.purple.shade700),
      ],
    );
  }
}

class _CardKpi extends StatelessWidget {
  final String label;
  final String valor;
  final Color cor;
  const _CardKpi({required this.label, required this.valor, required this.cor});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: cor.withOpacity(0.1), // Alterado withValues para withOpacity (mais seguro em Flutter)
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: TextStyle(color: cor, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(valor, style: TextStyle(color: cor, fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _SecaoDistribuicao extends StatelessWidget {
  final String titulo;
  final Map<String, int> dados;
  final int total;
  const _SecaoDistribuicao({required this.titulo, required this.dados, required this.total});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            ...dados.entries.map((e) {
              final pct = total == 0 ? 0.0 : e.value / total;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(e.key)),
                        Text('${e.value}  (${(pct * 100).toStringAsFixed(1)}%)'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: pct,
                      backgroundColor: Colors.grey.shade200,
                      minHeight: 6,
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}