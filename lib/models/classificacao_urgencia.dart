/// Escala de urgência usada na triagem das ocorrências.
enum ClassificacaoUrgencia { baixa, media, alta, critica }

// E É ESTA EXTENSÃO AQUI QUE FAZ O ".label" FUNCIONAR NA URGÊNCIA!
extension ClassificacaoUrgenciaX on ClassificacaoUrgencia {
  String get label {
    switch (this) {
      case ClassificacaoUrgencia.baixa:
        return 'Baixa';
      case ClassificacaoUrgencia.media:
        return 'Média';
      case ClassificacaoUrgencia.alta:
        return 'Alta';
      case ClassificacaoUrgencia.critica:
        return 'Crítica';
    }
  }

  /// Peso numérico para ordenação.
  int get prioridade {
    switch (this) {
      case ClassificacaoUrgencia.baixa:
        return 1;
      case ClassificacaoUrgencia.media:
        return 2;
      case ClassificacaoUrgencia.alta:
        return 3;
      case ClassificacaoUrgencia.critica:
        return 4;
    }
  }
}