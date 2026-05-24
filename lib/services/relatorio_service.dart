import '../models/denuncia.dart';
import '../models/status_denuncia.dart';
import '../models/tipo_ocorrencia.dart';
import '../models/classificacao_urgencia.dart';

class RelatorioService {
  final List<Denuncia> denuncias;
  RelatorioService(this.denuncias);

  int get total => denuncias.length;

  Map<StatusDenuncia, int> porStatus() {
    final m = {for (final s in StatusDenuncia.values) s: 0};
    for (final d in denuncias) {
      m[d.status] = (m[d.status] ?? 0) + 1;
    }
    return m;
  }

  Map<TipoOcorrencia, int> porTipo() {
    final m = {for (final t in TipoOcorrencia.values) t: 0};
    for (final d in denuncias) {
      m[d.tipo] = (m[d.tipo] ?? 0) + 1;
    }
    return m;
  }

  Map<ClassificacaoUrgencia, int> porUrgencia() {
    final m = {for (final u in ClassificacaoUrgencia.values) u: 0};
    for (final d in denuncias) {
      m[d.urgencia] = (m[d.urgencia] ?? 0) + 1;
    }
    return m;
  }

  double taxaResolucao() {
    if (denuncias.isEmpty) return 0;
    final r = denuncias.where((d) => d.status == StatusDenuncia.resolvida).length;
    return (r / denuncias.length) * 100;
  }

  int pendentes() => denuncias
      .where((d) =>
  d.status == StatusDenuncia.aberta ||
      d.status == StatusDenuncia.emAnalise ||
      d.status == StatusDenuncia.emAndamento)
      .length;

  String gerarTexto() {
    final b = StringBuffer()
      ..writeln('Relatório de Denúncias — Voz Animal')
      ..writeln('Gerado em: ${DateTime.now()}')
      ..writeln('Total: $total | Pendentes: ${pendentes()}')
      ..writeln('Taxa resolução: ${taxaResolucao().toStringAsFixed(1)}%')
      ..writeln('\n-- Por status --');
    porStatus().forEach((k, v) => b.writeln('${k.label}: $v'));
    b.writeln('\n-- Por tipo --');
    porTipo().forEach((k, v) => b.writeln('${k.label}: $v'));
    b.writeln('\n-- Por urgência --');
    porUrgencia().forEach((k, v) => b.writeln('${k.label}: $v'));
    return b.toString();
  }

  String gerarCsv() {
    final b = StringBuffer()
      ..writeln('id,criadoEm,tipo,status,urgencia,orgaoResponsavel,localizacao,descricao');
    for (final d in denuncias) {
      final loc = d.localizacao?.resumo().replaceAll(',', ';') ?? '';
      final desc = d.descricao.replaceAll('\n', ' ').replaceAll(',', ';');
      final orgao = (d.orgaoResponsavelNome ?? '').replaceAll(',', ';');
      b.writeln('${d.id},${d.criadoEm.toIso8601String()},'
          '${d.tipo.label},${d.status.label},${d.urgencia.label},$orgao,$loc,$desc');
    }
    return b.toString();
  }
}