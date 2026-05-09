import 'registro_base.dart';
import 'tipo_ocorrencia.dart';
import 'status_denuncia.dart';
import 'classificacao_urgencia.dart';
import 'localizacao.dart';

/// Denúncia registrada por um cidadão.
class Denuncia extends RegistroBase {
  final String usuarioId;
  String descricao;
  TipoOcorrencia tipo;
  StatusDenuncia status;
  ClassificacaoUrgencia urgencia;
  String? fotoPath;
  Localizacao? localizacao;

  Denuncia({
    required super.id,
    required this.usuarioId,
    required this.descricao,
    required this.tipo,
    required this.urgencia,
    this.status = StatusDenuncia.emAnalise,
    this.fotoPath,
    this.localizacao,
    super.criadoEm,
  });

  @override
  bool valido() {
    if (descricao.trim().length < 20) return false;
    if (localizacao == null || !localizacao!.valido()) return false;
    return true;
  }

  @override
  String resumo() => '${tipo.label} — ${status.label} (${urgencia.label})';
}