import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/classificacao_urgencia.dart';
import '../../models/denuncia.dart';
import '../../models/status_denuncia.dart';
import '../../models/tipo_ocorrencia.dart';
import '../../services/auth_service.dart';
import '../../services/denuncia_service.dart';
import '../../services/relatorio_service.dart';
import '../shared/font_size_controls.dart';

class RelatoriosScreen extends StatelessWidget {
  const RelatoriosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final orgaoId = context.read<AuthService>().usuarioAtual!.id;
    final svc     = context.read<DenunciaService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatórios'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        actions: const [FontSizeControls()],
      ),
      body: StreamBuilder<List<Denuncia>>(
        stream: svc.doOrgao(orgaoId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final denuncias = snap.data ?? [];
          final rel       = RelatorioService(denuncias);

          if (rel.total == 0) {
            return const Center(
                child: Text('Sem dados para gerar relatório.'));
          }

          return Stack(
            children: [
              ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                children: [
                  _CardsResumo(rel: rel),
                  const SizedBox(height: 16),
                  _SecaoDistribuicao(
                    titulo: 'Por status',
                    dados: rel.porStatus().map((k, v) =>
                        MapEntry(k.label, v)),
                    total: rel.total,
                  ),
                  const SizedBox(height: 16),
                  _SecaoDistribuicao(
                    titulo: 'Por tipo de ocorrência',
                    dados: rel.porTipo().map((k, v) =>
                        MapEntry(k.label, v)),
                    total: rel.total,
                  ),
                  const SizedBox(height: 16),
                  _SecaoDistribuicao(
                    titulo: 'Por urgência',
                    dados: rel.porUrgencia().map((k, v) =>
                        MapEntry(k.label, v)),
                    total: rel.total,
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Resumo texto',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16)),
                          const SizedBox(height: 8),
                          SelectableText(rel.gerarTexto(),
                              style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Positioned(
                bottom: 16,
                right: 16,
                child: Row(
                  children: [
                    FloatingActionButton.small(
                      heroTag: 'csv',
                      tooltip: 'Copiar CSV',
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      onPressed: () async {
                        await Clipboard.setData(
                            ClipboardData(text: rel.gerarCsv()));
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('CSV copiado.')),
                        );
                      },
                      child: const Icon(Icons.download),
                    ),
                    const SizedBox(width: 8),
                    FloatingActionButton.small(
                      heroTag: 'txt',
                      tooltip: 'Copiar resumo',
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      onPressed: () async {
                        await Clipboard.setData(
                            ClipboardData(text: rel.gerarTexto()));
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Resumo copiado.')),
                        );
                      },
                      child: const Icon(Icons.copy),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}


class _CardsResumo extends StatelessWidget {
  final RelatorioService rel;
  const _CardsResumo({required this.rel});

  @override
  Widget build(BuildContext context) => GridView.count(
    crossAxisCount: 2,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    mainAxisSpacing: 12,
    crossAxisSpacing: 12,
    childAspectRatio: 1.6,
    children: [
      _CardKpi(label: 'Total',
          valor: '${rel.total}', cor: Colors.blue.shade700),
      _CardKpi(label: 'Pendentes',
          valor: '${rel.pendentes()}', cor: Colors.orange.shade700),
      _CardKpi(label: 'Resolvidas',
          valor: '${rel.porStatus().values.elementAt(3)}',
          cor: Colors.green.shade700),
      _CardKpi(label: 'Taxa resolução',
          valor: '${rel.taxaResolucao().toStringAsFixed(1)}%',
          cor: Colors.purple.shade700),
    ],
  );
}

class _CardKpi extends StatelessWidget {
  final String label;
  final String valor;
  final Color cor;
  const _CardKpi(
      {required this.label, required this.valor, required this.cor});

  @override
  Widget build(BuildContext context) => Card(
    color: cor.withValues(alpha: 0.1),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label,
              style: TextStyle(
                  color: cor, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(valor,
              style: TextStyle(
                  color: cor,
                  fontSize: 24,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    ),
  );
}


class _SecaoDistribuicao extends StatelessWidget {
  final String titulo;
  final Map<String, int> dados;
  final int total;
  const _SecaoDistribuicao(
      {required this.titulo,
      required this.dados,
      required this.total});

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16)),
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
                      Text('${e.value}  '
                          '(${(pct * 100).toStringAsFixed(1)}%)'),
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
