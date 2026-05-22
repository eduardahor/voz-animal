import 'package:flutter/foundation.dart';
import '../models/denuncia.dart';
import '../models/tipo_ocorrencia.dart';
import '../models/status_denuncia.dart';
import '../models/classificacao_urgencia.dart';
import '../models/localizacao.dart';
import '../models/tipo_usuario.dart';
import '../models/usuario.dart';

class DenunciaService extends ChangeNotifier {
  final List<Denuncia> _denuncias = [];

  List<Denuncia> get todas => List.unmodifiable(_denuncias);

  List<Denuncia> doUsuario(String usuarioId) =>
      _denuncias.where((d) => d.usuarioId == usuarioId).toList();

/* Cria uma nova denúncia validando regras de negócio.
Lança ArgumentError caso a denúncia seja inválida. */
  Denuncia criar({
    required String usuarioId,
    required String descricao,
    required TipoOcorrencia tipo,
    required Localizacao localizacao,
    String? fotoPath,
  }) {
    if (descricao.trim().length < 20) {
      throw ArgumentError('Descrição precisa ter ao menos 20 caracteres.');
    }
    if (!localizacao.valido()) {
      throw ArgumentError('Localização inválida.');
    }

    final d = Denuncia(
      id: 'd-${DateTime.now().microsecondsSinceEpoch}',
      usuarioId: usuarioId,
      descricao: descricao.trim(),
      tipo: tipo,
      urgencia: _classificarUrgenciaInicial(tipo),
      localizacao: localizacao,
      fotoPath: fotoPath,
    );

    if (!d.valido()) {
      throw ArgumentError('Denúncia inválida.');
    }

    _denuncias.add(d);
    notifyListeners();
    return d;
  }

  /// Apenas órgãos podem alterar o status.
  void alterarStatus({
    required Usuario solicitante,
    required String denunciaId,
    required StatusDenuncia novo,
  }) {
    if (solicitante.tipo != TipoUsuario.orgao) {
      throw StateError('Apenas órgãos podem alterar o status.');
    }
    final d = _denuncias.firstWhere((e) => e.id == denunciaId);
    d.status = novo;
    notifyListeners();
  }

  Map<StatusDenuncia, int> estatisticasPorStatus() {
    final m = <StatusDenuncia, int>{
      for (final s in StatusDenuncia.values) s: 0,
    };
    for (final d in _denuncias) {
      m[d.status] = (m[d.status] ?? 0) + 1;
    }
    return m;
  }

  ClassificacaoUrgencia _classificarUrgenciaInicial(TipoOcorrencia t) {
    switch (t) {
      case TipoOcorrencia.agressao:
      case TipoOcorrencia.mutilacao:
      case TipoOcorrencia.abusoSexual:
      case TipoOcorrencia.rinha:
        return ClassificacaoUrgencia.critica;
      case TipoOcorrencia.traficoSilvestres:
      case TipoOcorrencia.aprisionamento:
        return ClassificacaoUrgencia.alta;
      case TipoOcorrencia.abandono:
      case TipoOcorrencia.negligencia:
        return ClassificacaoUrgencia.media;
    }
  }
}
