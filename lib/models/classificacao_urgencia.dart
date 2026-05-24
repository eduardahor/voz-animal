enum ClassificacaoUrgencia { baixa, media, alta, critica }

extension ClassificacaoUrgenciaX on ClassificacaoUrgencia {
  String get label {
    switch (this) {
      case ClassificacaoUrgencia.baixa:   return 'Baixa';
      case ClassificacaoUrgencia.media:   return 'Média';
      case ClassificacaoUrgencia.alta:    return 'Alta';
      case ClassificacaoUrgencia.critica: return 'Crítica';
    }
  }

  int get prioridade {
    switch (this) {
      case ClassificacaoUrgencia.baixa:   return 1;
      case ClassificacaoUrgencia.media:   return 2;
      case ClassificacaoUrgencia.alta:    return 3;
      case ClassificacaoUrgencia.critica: return 4;
    }
  }

  String get firestoreValue {
    switch (this) {
      case ClassificacaoUrgencia.baixa:   return 'baixa';
      case ClassificacaoUrgencia.media:   return 'media';
      case ClassificacaoUrgencia.alta:    return 'alta';
      case ClassificacaoUrgencia.critica: return 'critica';
    }
  }

  static ClassificacaoUrgencia fromFirestore(String v) {
    switch (v) {
      case 'baixa':   return ClassificacaoUrgencia.baixa;
      case 'media':   return ClassificacaoUrgencia.media;
      case 'alta':    return ClassificacaoUrgencia.alta;
      case 'critica': return ClassificacaoUrgencia.critica;
      default: throw ArgumentError('ClassificacaoUrgencia desconhecida: $v');
    }
  }
}
