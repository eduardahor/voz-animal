enum StatusDenuncia { emAnalise, emAndamento, resolvida, arquivada }

extension StatusDenunciaX on StatusDenuncia {
  String get label {
    switch (this) {
      case StatusDenuncia.emAnalise:
        return 'Em análise';
      case StatusDenuncia.emAndamento:
        return 'Em andamento';
      case StatusDenuncia.resolvida:
        return 'Resolvida';
      case StatusDenuncia.arquivada:
        return 'Arquivada';
    }
  }
}
