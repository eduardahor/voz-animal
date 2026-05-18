import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/denuncia.dart';
import '../models/status_denuncia.dart';

class DenunciaService extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 1. Aba "Novos Casos": Busca apenas o que está Em Análise (ninguém pegou)
  Stream<List<Denuncia>> get casosAbertos {
    return _db.collection('denuncias')
        .where('status', isEqualTo: StatusDenuncia.emAnalise.name)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Denuncia.fromMap(doc.data()))
            .toList());
  }

  // 2. Aba "Meus Casos": Busca apenas o que está Em Andamento e pertence a este Órgão
  Stream<List<Denuncia>> meusCasosOrgao(String orgaoId) {
    return _db.collection('denuncias')
        .where('status', isEqualTo: StatusDenuncia.emAndamento.name)
        .where('orgaoId', isEqualTo: orgaoId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Denuncia.fromMap(doc.data()))
            .toList());
  }

  // 3. NOVO - Aba "Finalizados": Busca casos Resolvidos ou Arquivados por este Órgão
  Stream<List<Denuncia>> casosFinalizadosOrgao(String orgaoId) {
    return _db.collection('denuncias')
        .where('orgaoId', isEqualTo: orgaoId)
        .where('status', whereIn: [StatusDenuncia.resolvida.name, StatusDenuncia.arquivada.name])
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Denuncia.fromMap(doc.data()))
            .toList());
  }

  // 4. Home do Cidadão: Busca as denúncias feitas por ele
  Stream<List<Denuncia>> minhasDenuncias(String usuarioId) {
    return _db.collection('denuncias')
        .where('usuarioId', isEqualTo: usuarioId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Denuncia.fromMap(doc.data()))
            .toList());
  }

  // 5. Relatórios: Busca absolutamente tudo
  Stream<List<Denuncia>> get todasAsDenuncias {
    return _db.collection('denuncias')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Denuncia.fromMap(doc.data()))
            .toList());
  }

  Future<void> criarDenuncia(Denuncia denuncia) async {
    try {
      await _db.collection('denuncias').doc(denuncia.id).set(denuncia.toMap());
      notifyListeners();
    } catch (e) {
      print("Erro ao criar denúncia: $e");
    }
  }

  Future<void> alterarStatus({
    required String denunciaId,
    required StatusDenuncia novoStatus,
    required String orgaoId,
  }) async {
    try {
      await _db.collection('denuncias').doc(denunciaId).update({
        'status': novoStatus.name,
        'orgaoId': orgaoId,
      });
      notifyListeners();
    } catch (e) {
      print("Erro ao alterar status: $e");
    }
  }
}