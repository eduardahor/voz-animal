import 'package:cloud_firestore/cloud_firestore.dart';

class HistoricoItem {
  final String id;
  final String acao;
  final String? orgaoId;
  final String? orgaoNome;
  final String? statusAnterior;
  final String? statusNovo;
  final String? observacao;
  final DateTime ocorridoEm;

  const HistoricoItem({
    required this.id,
    required this.acao,
    this.orgaoId,
    this.orgaoNome,
    this.statusAnterior,
    this.statusNovo,
    this.observacao,
    required this.ocorridoEm,
  });

  factory HistoricoItem.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return HistoricoItem(
      id: doc.id,
      acao: data['acao'] as String,
      orgaoId: data['orgaoId'] as String?,
      orgaoNome: data['orgaoNome'] as String?,
      statusAnterior: data['statusAnterior'] as String?,
      statusNovo: data['statusNovo'] as String?,
      observacao: data['observacao'] as String?,
      ocorridoEm:
          (data['ocorridoEm'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'acao': acao,
        if (orgaoId != null) 'orgaoId': orgaoId,
        if (orgaoNome != null) 'orgaoNome': orgaoNome,
        if (statusAnterior != null) 'statusAnterior': statusAnterior,
        if (statusNovo != null) 'statusNovo': statusNovo,
        if (observacao != null) 'observacao': observacao,
        'ocorridoEm': FieldValue.serverTimestamp(),
      };

  String get descricao {
    switch (acao) {
      case 'assumiu':
        return '${orgaoNome ?? orgaoId} assumiu a denúncia';
      case 'devolveu':
        return '${orgaoNome ?? orgaoId} devolveu a denúncia';
      case 'auto_reset':
        return 'Devolvida automaticamente após 48h';
      case 'status_alterado':
        return 'Status: $statusAnterior → $statusNovo';
      case 'criado':
        return 'Denúncia registrada pelo cidadão';
      default:
        return acao;
    }
  }
}
