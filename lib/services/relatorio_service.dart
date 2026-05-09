import '../models/denuncia.dart';
import '../models/status_denuncia.dart';
import '../models/tipo_ocorrencia.dart';
import '../models/classificacao_urgencia.dart';

/* Serviço responsável por gerar relatórios consolidados das denúncias
para o painel do órgão responsável. */

class RelatorioService {
  final List<Denuncia> denuncias;

  RelatorioService(this.denuncias);

  int get total => denuncias.length;

  Map<StatusDenuncia, int> porStatus() {
    final m = <StatusDenuncia, int>{
      for (final s in StatusDenuncia.values) s: 0,
    };
    for (final d in denuncias) {
      m[d.status] = (m[d.status] ?? 0) + 1;
    }
    return m;
  }

  Map<TipoOcorrencia, int> porTipo() {
    final m = <TipoOcorrencia, int>{
      for (final t in TipoOcorrencia.values) t: 0,
    };
    for (final d in denuncias) {
      m[d.tipo] = (m[d.tipo] ?? 0) + 1;
    }
    return m;
  }

  Map<ClassificacaoUrgencia, int> porUrgencia() {
    final m = <ClassificacaoUrgencia, int>{
      for (final u in ClassificacaoUrgencia.values) u: 0,
    };
    for (final d in denuncias) {
      m[d.urgencia] = (m[d.urgencia] ?? 0) + 1;
    }
    return m;
  }

  /// Percentual de denúncias resolvidas sobre o total.
  double taxaResolucao() {
    if (denuncias.isEmpty) return 0;
    final resolvidas = denuncias
        .where((d) => d.status == StatusDenuncia.resolvida)
        .length;
    return (resolvidas / denuncias.length) * 100;
  }

  /// Denúncias ainda abertas (em análise ou em andamento).
  int pendentes() => denuncias
      .where((d) =>
          d.status == StatusDenuncia.emAnalise ||
          d.status == StatusDenuncia.emAndamento)
      .length;

  /// Texto resumido (impressão / cópia).
  String gerarTexto() {
    final b = StringBuffer();
    b.writeln('Relatório de Denúncias — Voz Animal');
    b.writeln('Gerado em: ${DateTime.now()}');
    b.writeln('Total de denúncias: $total');
    b.writeln('Pendentes: ${pendentes()}');
    b.writeln('Taxa de resolução: ${taxaResolucao().toStringAsFixed(1)}%');
    b.writeln('');
    b.writeln('-- Por status --');
    porStatus().forEach((k, v) => b.writeln('${k.label}: $v'));
    b.writeln('');
    b.writeln('-- Por tipo de ocorrência --');
    porTipo().forEach((k, v) => b.writeln('${k.label}: $v'));
    b.writeln('');
    b.writeln('-- Por urgência --');
    porUrgencia().forEach((k, v) => b.writeln('${k.label}: $v'));
    return b.toString();
  }

  /// CSV para exportação/cópia.
  String gerarCsv() {
    final b = StringBuffer();
    b.writeln('id,criadoEm,tipo,status,urgencia,localizacao,descricao');
    for (final d in denuncias) {
      final loc =
          d.localizacao?.resumo().replaceAll(',', ';') ?? '';
      final desc = d.descricao.replaceAll('\n', ' ').replaceAll(',', ';');
      b.writeln(
          '${d.id},${d.criadoEm.toIso8601String()},${d.tipo.label},${d.status.label},${d.urgencia.label},$loc,$desc');
    }
    return b.toString();
  }
}
