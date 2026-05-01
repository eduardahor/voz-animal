abstract class RegistroBase {
  String id;
  String status;
  final DateTime dataCriacao;

  RegistroBase({
    required this.id,
    required this.status,
    DateTime? dataCriacao,
  }) : dataCriacao = dataCriacao ?? DateTime.now();

  String get resumo;
  bool validar();
}
