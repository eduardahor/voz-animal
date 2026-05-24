import 'package:cloud_firestore/cloud_firestore.dart';
import 'status_denuncia.dart';
import 'tipo_ocorrencia.dart';
import 'classificacao_urgencia.dart';
import 'localizacao.dart';

/// Denúncia registrada por um cidadão.
class Denuncia {
  final String id;
  final String usuarioId;

  final String descricao;
  final TipoOcorrencia tipo;
  final ClassificacaoUrgencia urgencia;
  final String? fotoUrl;
  final Localizacao? localizacao;

  final StatusDenuncia status;
  final String? orgaoResponsavelId;
  final String? orgaoResponsavelNome;
  final DateTime? acceptedAt;
  final DateTime? devolvidaAt;
  final Map<String, DateTime> bloqueadosAte;

  final DateTime criadoEm;
  final DateTime? atualizadoEm;

  Denuncia({
    required this.id,
    required this.usuarioId,
    required this.descricao,
    required this.tipo,
    required this.urgencia,
    required this.status,
    required this.criadoEm,
    this.fotoUrl,
    this.localizacao,
    this.orgaoResponsavelId,
    this.orgaoResponsavelNome,
    this.acceptedAt,
    this.devolvidaAt,
    this.bloqueadosAte = const {},
    this.atualizadoEm,
  });


  factory Denuncia.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;

    final rawBloq = (data['bloqueadosAte'] as Map<String, dynamic>?) ?? {};
    final bloq = rawBloq.map(
      (k, v) => MapEntry(k, (v as Timestamp).toDate()),
    );

    return Denuncia(
      id: doc.id,
      usuarioId: data['usuarioId'] as String,
      descricao: data['descricao'] as String,
      tipo: TipoOcorrenciaX.fromFirestore(data['tipo'] as String),
      urgencia:
          ClassificacaoUrgenciaX.fromFirestore(data['urgencia'] as String),
      status: StatusDenunciaX.fromFirestore(data['status'] as String),
      fotoUrl: data['fotoUrl'] as String?,
      localizacao: data['localizacao'] != null
          ? Localizacao.fromMap(data['localizacao'] as Map<String, dynamic>)
          : null,
      orgaoResponsavelId: data['orgaoResponsavelId'] as String?,
      orgaoResponsavelNome: data['orgaoResponsavelNome'] as String?,
      acceptedAt: _ts(data['acceptedAt']),
      devolvidaAt: _ts(data['devolvidaAt']),
      bloqueadosAte: bloq,
      criadoEm: _ts(data['criadoEm']) ?? DateTime.now(),
      atualizadoEm: _ts(data['atualizadoEm']),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'usuarioId': usuarioId,
        'descricao': descricao,
        'tipo': tipo.firestoreValue,
        'urgencia': urgencia.firestoreValue,
        'status': status.firestoreValue,
        if (fotoUrl != null) 'fotoUrl': fotoUrl,
        if (localizacao != null) 'localizacao': localizacao!.toMap(),
        'orgaoResponsavelId': orgaoResponsavelId,
        'orgaoResponsavelNome': orgaoResponsavelNome,
        'acceptedAt':
            acceptedAt != null ? Timestamp.fromDate(acceptedAt!) : null,
        'devolvidaAt':
            devolvidaAt != null ? Timestamp.fromDate(devolvidaAt!) : null,
        'bloqueadosAte': bloqueadosAte
            .map((k, v) => MapEntry(k, Timestamp.fromDate(v))),
      };

  static DateTime? _ts(dynamic v) =>
      v is Timestamp ? v.toDate() : null;


  bool get estaAberta => status == StatusDenuncia.aberta;

  bool orgaoEstaBloqueado(String orgaoId) {
    final ate = bloqueadosAte[orgaoId];
    return ate != null && DateTime.now().isBefore(ate);
  }

  bool valido() =>
      descricao.trim().length >= 20 &&
      (localizacao == null || localizacao!.valido());

  String resumo() => '${tipo.label} — ${status.label} (${urgencia.label})';

  Denuncia copyWith({
    StatusDenuncia? status,
    String? orgaoResponsavelId,
    String? orgaoResponsavelNome,
    DateTime? acceptedAt,
    DateTime? devolvidaAt,
    Map<String, DateTime>? bloqueadosAte,
  }) =>
      Denuncia(
        id: id,
        usuarioId: usuarioId,
        descricao: descricao,
        tipo: tipo,
        urgencia: urgencia,
        status: status ?? this.status,
        fotoUrl: fotoUrl,
        localizacao: localizacao,
        orgaoResponsavelId: orgaoResponsavelId ?? this.orgaoResponsavelId,
        orgaoResponsavelNome:
            orgaoResponsavelNome ?? this.orgaoResponsavelNome,
        acceptedAt: acceptedAt ?? this.acceptedAt,
        devolvidaAt: devolvidaAt ?? this.devolvidaAt,
        bloqueadosAte: bloqueadosAte ?? this.bloqueadosAte,
        criadoEm: criadoEm,
        atualizadoEm: DateTime.now(),
      );
}
