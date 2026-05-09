/// Classe abstrata base para qualquer registro persistente do domínio.
/// Garante encapsulamento de id e data de criação imutável.
abstract class RegistroBase {
  final String _id;
  final DateTime _criadoEm;

  RegistroBase({required String id, DateTime? criadoEm})
      : _id = id,
        _criadoEm = criadoEm ?? DateTime.now();

  String get id => _id;
  DateTime get criadoEm => _criadoEm;

  /// Cada subclasse deve validar a si mesma.
  bool valido();

  /// Resumo textual usado em listas.
  String resumo();
}
