enum TipoOcorrencia {
  abandono('Abandono', 'pets'),
  mausTrato('Maus-tratos', 'warning'),
  animalPerdido('Animal Perdido', 'search'),
  animalFerido('Animal Ferido', 'local_hospital'),
  envenenamento('Envenenamento', 'dangerous'),
  criacaoIlegal('Criação Ilegal', 'gavel'),
  outros('Outros', 'more_horiz');

  final String label;
  final String iconName;
  const TipoOcorrencia(this.label, this.iconName);
}
