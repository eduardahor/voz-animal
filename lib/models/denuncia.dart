import 'localizacao.dart';
import 'registro_base.dart';
import 'status_denuncia.dart';
import 'classificacao.dart';


class Denuncia extends RegistroBase {
  final String descricao;
  final String tipo;
  final Localizacao localizacao;
  final String usuarioId;
  final String? fotoUrl;
  final String? observacaoOrgao;
  StatusDenuncia statusDenuncia;
  ClassificacaoUrgencia? classificacao;

  Denuncia({
    required super.id,
    required this.descricao,
    required this.tipo,
    required this.localizacao,
    required this.usuarioId,
    this.fotoUrl,
    this.observacaoOrgao,
    this.statusDenuncia = StatusDenuncia.pendente,
    this.classificacao,
  }) : super(status: StatusDenuncia.pendente.name);

  String get tipoOcorrencia => tipo;

  @override
  String get resumo => '$tipo: $descricao';

  @override
  bool validar() => descricao.isNotEmpty && tipo.isNotEmpty;
}
