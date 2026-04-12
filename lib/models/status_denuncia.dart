/// Enum que define os status possíveis de uma denúncia.
enum StatusDenuncia {
  pendente('Pendente', 0xFFFFA726),
  emAnalise('Em Análise', 0xFF42A5F5),
  resolvida('Resolvida', 0xFF66BB6A);

  final String descricao;
  final int corHex;

  const StatusDenuncia(this.descricao, this.corHex);

  @override
  String toString() => descricao;
}
