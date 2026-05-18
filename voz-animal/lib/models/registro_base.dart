import 'package:voz_animal/models/status_denuncia.dart';

/// Classe abstrata base que demonstra ABSTRAÇÃO.
/// Define a interface comum para registros no sistema.
abstract class RegistroBase {
  final String id;
  final DateTime dataCriacao;
  StatusDenuncia _status;

  RegistroBase({
    required this.id,
    required this.dataCriacao,
    StatusDenuncia status = StatusDenuncia.pendente,
  }) : _status = status;

  StatusDenuncia get status => _status;

  /// Método abstrato — cada subclasse implementa (polimorfismo)
  String obterResumo();

  /// Método abstrato para validação
  bool isValido();

  /// Template method com comportamento padrão
  void atualizarStatus(StatusDenuncia novoStatus) {
    _status = novoStatus;
  }
}
