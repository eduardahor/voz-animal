/// Enum que define os tipos de ocorrência possíveis.
enum TipoOcorrencia {
  abandono('Abandono', 'animal_abandoned'),
  mausTratos('Maus-tratos', 'animal_abuse'),
  pedidoAjuda('Pedido de Ajuda', 'help_request'),
  animalPerdido('Animal Perdido', 'lost_animal'),
  animalFerido('Animal Ferido', 'injured_animal');

  final String descricao;
  final String codigo;

  const TipoOcorrencia(this.descricao, this.codigo);

  @override
  String toString() => descricao;
}
