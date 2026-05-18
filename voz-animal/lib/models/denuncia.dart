import 'package:voz_animal/models/registro_base.dart';
import 'package:voz_animal/models/localizacao.dart';
import 'package:voz_animal/models/tipo_ocorrencia.dart';
import 'package:voz_animal/models/status_denuncia.dart';

/// Classe Denuncia — herda de RegistroBase (HERANÇA).
/// Implementa métodos abstratos (POLIMORFISMO).
class Denuncia extends RegistroBase {
  final String _descricao;
  final String _fotoUrl;
  final Localizacao _localizacao;
  final TipoOcorrencia _tipoOcorrencia;
  final String _usuarioId;
  final String _nomeUsuario;

  Denuncia({
    required String id,
    required String descricao,
    required String fotoUrl,
    required Localizacao localizacao,
    required TipoOcorrencia tipoOcorrencia,
    required String usuarioId,
    required String nomeUsuario,
    DateTime? dataCriacao,
    StatusDenuncia status = StatusDenuncia.pendente,
  })  : _descricao = descricao,
        _fotoUrl = fotoUrl,
        _localizacao = localizacao,
        _tipoOcorrencia = tipoOcorrencia,
        _usuarioId = usuarioId,
        _nomeUsuario = nomeUsuario,
        super(
          id: id,
          dataCriacao: dataCriacao ?? DateTime.now(),
          status: status,
        );

  // Getters (encapsulamento)
  String get descricao => _descricao;
  String get fotoUrl => _fotoUrl;
  Localizacao get localizacao => _localizacao;
  TipoOcorrencia get tipoOcorrencia => _tipoOcorrencia;
  String get usuarioId => _usuarioId;
  String get nomeUsuario => _nomeUsuario;

  /// Polimorfismo: implementação do método abstrato
  @override
  String obterResumo() {
    return '\${_tipoOcorrencia.descricao} — \${_localizacao.endereco}';
  }

  /// Polimorfismo: implementação da validação
  @override
  bool isValido() {
    return _descricao.isNotEmpty && _usuarioId.isNotEmpty;
  }

  void marcarComoResolvida() {
    atualizarStatus(StatusDenuncia.resolvida);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'descricao': _descricao,
      'fotoUrl': _fotoUrl,
      'localizacao': _localizacao.toMap(),
      'tipoOcorrencia': _tipoOcorrencia.codigo,
      'usuarioId': _usuarioId,
      'nomeUsuario': _nomeUsuario,
      'dataCriacao': dataCriacao.toIso8601String(),
      'status': status.name,
    };
  }
}
