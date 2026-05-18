import 'registro_base.dart';
import 'tipo_ocorrencia.dart';
import 'status_denuncia.dart';
import 'classificacao_urgencia.dart';
import 'localizacao.dart';

class Denuncia extends RegistroBase {
  final String usuarioId;
  String? orgaoId; 
  String descricao;
  TipoOcorrencia tipo;
  StatusDenuncia status;
  ClassificacaoUrgencia urgencia;
  String? fotoPath;
  Localizacao? localizacao;

  Denuncia({
    required super.id,
    required this.usuarioId,
    this.orgaoId,
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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'criadoEm': criadoEm.toIso8601String(),
      'usuarioId': usuarioId,
      'orgaoId': orgaoId,
      'descricao': descricao,
      'tipo': tipo.name, 
      'status': status.name,
      'urgencia': urgencia.name,
      'fotoPath': fotoPath,
      'localizacao': localizacao?.toMap(),
    };
  }

  factory Denuncia.fromMap(Map<String, dynamic> map) {
    return Denuncia(
      id: map['id'] ?? '',
      criadoEm: map['criadoEm'] != null ? DateTime.parse(map['criadoEm']) : null,
      usuarioId: map['usuarioId'] ?? '',
      orgaoId: map['orgaoId'],
      descricao: map['descricao'] ?? '',
      tipo: TipoOcorrencia.values.byName(map['tipo'] ?? 'negligencia'),
      status: StatusDenuncia.values.byName(map['status'] ?? 'emAnalise'),
      urgencia: ClassificacaoUrgencia.values.byName(map['urgencia'] ?? 'media'),
      fotoPath: map['fotoPath'],
      localizacao: map['localizacao'] != null ? Localizacao.fromMap(map['localizacao']) : null,
    );
  }
}