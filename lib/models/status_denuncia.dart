enum StatusDenuncia { aberta, emAnalise, emAndamento, resolvida, recusada }

extension StatusDenunciaX on StatusDenuncia {
  String get label {
    switch (this) {
      case StatusDenuncia.aberta:       return 'Aberta';
      case StatusDenuncia.emAnalise:    return 'Em análise';
      case StatusDenuncia.emAndamento:  return 'Em andamento';
      case StatusDenuncia.resolvida:    return 'Resolvida';
      case StatusDenuncia.recusada:     return 'Recusada';
    }
  }

  /// Valor serializado no Firestore.
  String get firestoreValue {
    switch (this) {
      case StatusDenuncia.aberta:       return 'aberta';
      case StatusDenuncia.emAnalise:    return 'em_analise';
      case StatusDenuncia.emAndamento:  return 'em_andamento';
      case StatusDenuncia.resolvida:    return 'resolvida';
      case StatusDenuncia.recusada:     return 'recusada';
    }
  }

  static StatusDenuncia fromFirestore(String v) {
    switch (v) {
      case 'aberta':        return StatusDenuncia.aberta;
      case 'em_analise':    return StatusDenuncia.emAnalise;
      case 'em_andamento':  return StatusDenuncia.emAndamento;
      case 'resolvida':     return StatusDenuncia.resolvida;
      case 'recusada':      return StatusDenuncia.recusada;
      default: throw ArgumentError('Status desconhecido: $v');
    }
  }

  List<StatusDenuncia> get transicoesPermitidas {
    switch (this) {
      case StatusDenuncia.emAnalise:   return [StatusDenuncia.emAndamento, StatusDenuncia.recusada];
      case StatusDenuncia.emAndamento: return [StatusDenuncia.resolvida, StatusDenuncia.recusada];
      default:                         return [];
    }
  }

  bool podeTansicionarPara(StatusDenuncia novo) =>
      transicoesPermitidas.contains(novo);
}
