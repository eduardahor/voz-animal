import 'package:flutter/foundation.dart';
import '../models/denuncia.dart';
import '../models/localizacao.dart';
import '../models/status_denuncia.dart';
import '../models/classificacao.dart';

class DenunciaService extends ChangeNotifier {
  final List<Denuncia> _denuncias = [];

  List<Denuncia> get denuncias => List.unmodifiable(_denuncias);

  List<Denuncia> get todasDenuncias => _denuncias;

  int get totalDenuncias => _denuncias.length;
  int get totalPendentes => _denuncias.where((d) => d.statusDenuncia == StatusDenuncia.pendente).length;
  int get totalResolvidas => _denuncias.where((d) => d.statusDenuncia == StatusDenuncia.resolvida).length;

  List<Denuncia> denunciasPorUsuario(String usuarioId) {
    return _denuncias.where((denuncia) => denuncia.usuarioId == usuarioId).toList();
  }

  void criarDenuncia({
    required String descricao,
    required String tipo,
    required Localizacao localizacao,
    required String usuarioId,
    String? fotoUrl,
  }) {
    final d = Denuncia(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      descricao: descricao,
      tipo: tipo,
      localizacao: localizacao,
      usuarioId: usuarioId,
      fotoUrl: fotoUrl,
    );
    _denuncias.add(d);
    notifyListeners();
  }

  void atualizarStatus(String id, StatusDenuncia novoStatus) {
    final d = _denuncias.firstWhere((d) => d.id == id);
    d.statusDenuncia = novoStatus;
    d.status = novoStatus.name;
    notifyListeners();
  }

  void classificar(String id, ClassificacaoUrgencia c) {
    final d = _denuncias.firstWhere((d) => d.id == id);
    d.classificacao = c;
    notifyListeners();
  }
}
