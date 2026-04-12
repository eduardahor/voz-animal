import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/denuncia.dart';
import '../models/localizacao.dart';
import '../models/tipo_ocorrencia.dart';
import '../models/status_denuncia.dart';

/// Serviço de gerenciamento de denúncias.
class DenunciaService extends ChangeNotifier {
  final List<Denuncia> _denuncias = [];
  final _uuid = const Uuid();

  List<Denuncia> get denuncias => List.unmodifiable(_denuncias);

  List<Denuncia> get denunciasPendentes =>
      _denuncias.where((d) => d.status == StatusDenuncia.pendente).toList();

  List<Denuncia> get denunciasResolvidas =>
      _denuncias.where((d) => d.status == StatusDenuncia.resolvida).toList();

  List<Denuncia> denunciasPorUsuario(String usuarioId) =>
      _denuncias.where((d) => d.usuarioId == usuarioId).toList();

  Denuncia? buscarPorId(String id) {
    try {
      return _denuncias.firstWhere((d) => d.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Cria uma nova denúncia
  Future<Denuncia> criarDenuncia({
    required String descricao,
    required TipoOcorrencia tipoOcorrencia,
    required String usuarioId,
    required String nomeUsuario,
    String? fotoUrl,
    Localizacao? localizacao,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final denuncia = Denuncia(
      id: _uuid.v4(),
      descricao: descricao,
      fotoUrl: fotoUrl ?? '',
      localizacao: localizacao ?? Localizacao.simulada(),
      tipoOcorrencia: tipoOcorrencia,
      usuarioId: usuarioId,
      nomeUsuario: nomeUsuario,
    );

    if (!denuncia.isValido()) {
      throw Exception('Denúncia inválida. Verifique os campos obrigatórios.');
    }

    _denuncias.insert(0, denuncia);
    notifyListeners();
    return denuncia;
  }

  /// Marca denúncia como resolvida
  void marcarComoResolvida(String denunciaId) {
    final denuncia = buscarPorId(denunciaId);
    if (denuncia != null) {
      denuncia.marcarComoResolvida();
      notifyListeners();
    }
  }

  /// Adiciona dados de exemplo
  void carregarDadosExemplo(String usuarioId, String nomeUsuario) {
    if (_denuncias.isNotEmpty) return;

    final exemplos = [
      Denuncia(
        id: _uuid.v4(),
        descricao: 'Cachorro abandonado em frente ao supermercado. Aparenta estar desnutrido e com ferimentos nas patas.',
        fotoUrl: '',
        localizacao: Localizacao(
          latitude: -23.5489,
          longitude: -46.6388,
          endereco: 'Rua Augusta, 500 - São Paulo, SP',
        ),
        tipoOcorrencia: TipoOcorrencia.abandono,
        usuarioId: usuarioId,
        nomeUsuario: nomeUsuario,
        dataCriacao: DateTime.now().subtract(const Duration(days: 2)),
      ),
      Denuncia(
        id: _uuid.v4(),
        descricao: 'Gato preso em árvore há mais de 24 horas. Precisa de resgate urgente.',
        fotoUrl: '',
        localizacao: Localizacao(
          latitude: -23.5600,
          longitude: -46.6500,
          endereco: 'Praça da Sé, 100 - São Paulo, SP',
        ),
        tipoOcorrencia: TipoOcorrencia.pedidoAjuda,
        usuarioId: usuarioId,
        nomeUsuario: nomeUsuario,
        dataCriacao: DateTime.now().subtract(const Duration(hours: 5)),
      ),
      Denuncia(
        id: _uuid.v4(),
        descricao: 'Vizinho mantém cão acorrentado sem água e comida. Situação recorrente.',
        fotoUrl: '',
        localizacao: Localizacao(
          latitude: -23.5430,
          longitude: -46.6290,
          endereco: 'Rua Consolação, 1200 - São Paulo, SP',
        ),
        tipoOcorrencia: TipoOcorrencia.mausTratos,
        usuarioId: usuarioId,
        nomeUsuario: nomeUsuario,
        dataCriacao: DateTime.now().subtract(const Duration(days: 1)),
        status: StatusDenuncia.emAnalise,
      ),
    ];

    _denuncias.addAll(exemplos);
    notifyListeners();
  }
}
