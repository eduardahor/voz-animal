enum StatusDenuncia {
  pendente('Pendente'),
  emAnalise('Em Análise'),
  emAndamento('Em Andamento'),
  resolvida('Resolvida'),
  arquivada('Arquivada');

  final String label;
  const StatusDenuncia(this.label);

}
