enum TipoOcorrencia {
  abandono, agressao, negligencia, mutilacao,
  aprisionamento, traficoSilvestres, rinha, abusoSexual,
}

extension TipoOcorrenciaX on TipoOcorrencia {
  String get label {
    switch (this) {
      case TipoOcorrencia.abandono:           return 'Abandono';
      case TipoOcorrencia.agressao:           return 'Violência Física';
      case TipoOcorrencia.negligencia:        return 'Negligência';
      case TipoOcorrencia.mutilacao:          return 'Mutilação';
      case TipoOcorrencia.aprisionamento:     return 'Aprisionamento Inadequado';
      case TipoOcorrencia.traficoSilvestres:  return 'Tráfico de Silvestres';
      case TipoOcorrencia.rinha:              return 'Rinha';
      case TipoOcorrencia.abusoSexual:        return 'Abuso Sexual';
    }
  }

  String get descricao {
    switch (this) {
      case TipoOcorrencia.abandono:           return 'Deixar animais em via pública, casas vazias ou locais sem assistência.';
      case TipoOcorrencia.agressao:           return 'Espancamento, ferimentos propositais, queimaduras e envenenamento.';
      case TipoOcorrencia.negligencia:        return 'Animal sem comida, água, abrigo ou em locais sujos/sem higiene.';
      case TipoOcorrencia.mutilacao:          return 'Cortes, amputações ou intervenções cruéis sem necessidade médica.';
      case TipoOcorrencia.aprisionamento:     return 'Manter o animal preso em correntes curtas ou espaços muito pequenos.';
      case TipoOcorrencia.traficoSilvestres:  return 'Comercialização ou captura ilegal de animais silvestres.';
      case TipoOcorrencia.rinha:              return 'Promoção ou participação em brigas de animais.';
      case TipoOcorrencia.abusoSexual:        return 'Qualquer ato de natureza sexual contra animais (zoofilia).';
    }
  }

  String get firestoreValue {
    switch (this) {
      case TipoOcorrencia.abandono:           return 'abandono';
      case TipoOcorrencia.agressao:           return 'agressao';
      case TipoOcorrencia.negligencia:        return 'negligencia';
      case TipoOcorrencia.mutilacao:          return 'mutilacao';
      case TipoOcorrencia.aprisionamento:     return 'aprisionamento';
      case TipoOcorrencia.traficoSilvestres:  return 'trafico_silvestres';
      case TipoOcorrencia.rinha:              return 'rinha';
      case TipoOcorrencia.abusoSexual:        return 'abuso_sexual';
    }
  }

  static TipoOcorrencia fromFirestore(String v) {
    switch (v) {
      case 'abandono':            return TipoOcorrencia.abandono;
      case 'agressao':            return TipoOcorrencia.agressao;
      case 'negligencia':         return TipoOcorrencia.negligencia;
      case 'mutilacao':           return TipoOcorrencia.mutilacao;
      case 'aprisionamento':      return TipoOcorrencia.aprisionamento;
      case 'trafico_silvestres':  return TipoOcorrencia.traficoSilvestres;
      case 'rinha':               return TipoOcorrencia.rinha;
      case 'abuso_sexual':        return TipoOcorrencia.abusoSexual;
      default: throw ArgumentError('TipoOcorrencia desconhecido: $v');
    }
  }
}
