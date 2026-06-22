import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/denuncia.dart';
import '../models/historico_item.dart';
import '../models/status_denuncia.dart';
import '../models/tipo_ocorrencia.dart';
import '../models/localizacao.dart';
import '../models/classificacao_urgencia.dart';
import '../exceptions/claim_exception.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

const Duration _kBloqueio  = Duration(hours: 48);
const Duration _kAutoReset = Duration(hours: 48);

class DenunciaRepository {
  DenunciaRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('denuncias');

  DocumentReference<Map<String, dynamic>> _doc(String id) => _col.doc(id);

  CollectionReference<Map<String, dynamic>> _historico(String id) =>
      _doc(id).collection('historico');


  Stream<List<Denuncia>> abertas() => _col
      .where('status', isEqualTo: 'aberta')
      .orderBy('urgencia', descending: true)
      .orderBy('criadoEm', descending: true)
      .snapshots()
      .map(_mapSnap);

  Stream<List<Denuncia>> doOrgao(String orgaoId) => _col
      .where('orgaoResponsavelId', isEqualTo: orgaoId)
      .orderBy('atualizadoEm', descending: true)
      .snapshots()
      .map(_mapSnap);

  Stream<List<Denuncia>> doCidadao(String usuarioId) => _col
      .where('usuarioId', isEqualTo: usuarioId)
      .orderBy('criadoEm', descending: true)
      .snapshots()
      .map(_mapSnap);

  Stream<List<HistoricoItem>> historicoDe(String denunciaId) =>
      _historico(denunciaId)
          .orderBy('ocorridoEm')
          .snapshots()
          .map((s) => s.docs.map(HistoricoItem.fromFirestore).toList());


  Future<String> criar({
    required String usuarioId,
    required String descricao,
    required TipoOcorrencia tipo,
    required Localizacao localizacao,
    String? fotoUrl,
    String? denuncianteNome,
    String? denuncianteTelefone,
    String? denuncianteEmail,
    String? denuncianteCpf,
  }) async {
    if (descricao.trim().length < 20) {
      throw ArgumentError('Descrição precisa ter ao menos 20 caracteres.');
    }
    if (!localizacao.valido()) {
      throw ArgumentError('Localização inválida.');
    }

    final ref = _col.doc();
    final urgencia = _urgenciaInicial(tipo);
    final batch = _db.batch();

    String? linkPublicoDaFoto;

    if (fotoUrl != null && !fotoUrl.startsWith('assets/')) {
      try {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('denuncias')
            .child(ref.id)
            .child('foto_ocorrencia.jpg');

        final uploadTask = await storageRef.putFile(File(fotoUrl));

        linkPublicoDaFoto = await uploadTask.ref.getDownloadURL();
      } catch (e) {
        throw Exception('Erro ao fazer o upload da foto da denúncia: $e');
      }
    } else if (fotoUrl?.startsWith('assets/') == true) {
      linkPublicoDaFoto = fotoUrl;
    }

    batch.set(ref, {
      'usuarioId':           usuarioId,
      'descricao':           descricao.trim(),
      'tipo':                tipo.firestoreValue,
      'urgencia':            urgencia.firestoreValue,
      'status':              'aberta',
      if (linkPublicoDaFoto != null) 'fotoUrl': linkPublicoDaFoto, // Salvando o Link da Nuvem!
      'localizacao':         localizacao.toMap(),
      'orgaoResponsavelId':  null,
      'orgaoResponsavelNome': null,
      'acceptedAt':          null,
      'devolvidaAt':         null,
      'bloqueadosAte':       <String, dynamic>{},
      if (denuncianteNome != null) 'denuncianteNome': denuncianteNome,
      if (denuncianteTelefone != null) 'denuncianteTelefone': denuncianteTelefone,
      if (denuncianteEmail != null) 'denuncianteEmail': denuncianteEmail,
      if (denuncianteCpf != null) 'denuncianteCpf': denuncianteCpf,
      'criadoEm':            FieldValue.serverTimestamp(),
      'atualizadoEm':        FieldValue.serverTimestamp(),
    });

    batch.set(_historico(ref.id).doc(), {
      'acao':       'criado',
      'ocorridoEm': FieldValue.serverTimestamp(),
    });

    await batch.commit();
    return ref.id;
  }


  Future<void> registrarVisualizacaoDadosDenunciante({
    required String denunciaId,
    required String orgaoId,
    required String orgaoNome,
  }) async {
    try {
      await _historico(denunciaId).add({
        'acao':      'dados_denunciante_visualizados',
        'orgaoId':   orgaoId,
        'orgaoNome': orgaoNome,
        'ocorridoEm': FieldValue.serverTimestamp(),
      });
    } catch (_) {

    }
  }

  Future<void> assumir({
    required String denunciaId,
    required String orgaoId,
    required String orgaoNome,
  }) async {
    final docRef  = _doc(denunciaId);
    final histRef = _historico(denunciaId).doc();

    await _db.runTransaction<void>((tx) async {
      final snap = await tx.get(docRef);
      if (!snap.exists) throw DenunciaNotFoundException();

      final data   = snap.data()!;
      final status = StatusDenunciaX.fromFirestore(data['status'] as String);

      if (status != StatusDenuncia.aberta) {
        throw DenunciaJaAssumidaException();
      }

      final rawBloq = data['bloqueadosAte'] as Map<String, dynamic>? ?? {};
      if (rawBloq.containsKey(orgaoId)) {
        final ate = (rawBloq[orgaoId] as Timestamp).toDate();
        if (DateTime.now().isBefore(ate)) throw OrgaoBloqueadoException(ate);
      }

      tx.update(docRef, {
        'status':               'em_analise',
        'orgaoResponsavelId':   orgaoId,
        'orgaoResponsavelNome': orgaoNome,
        'acceptedAt':           FieldValue.serverTimestamp(),
        'devolvidaAt':          null,
        'atualizadoEm':         FieldValue.serverTimestamp(),
      });

      tx.set(histRef, {
        'acao':           'assumiu',
        'orgaoId':        orgaoId,
        'orgaoNome':      orgaoNome,
        'statusAnterior': 'aberta',
        'statusNovo':     'em_analise',
        'ocorridoEm':     FieldValue.serverTimestamp(),
      });
    });
  }


  Future<void> devolver({
    required String denunciaId,
    required String orgaoId,
    required String orgaoNome,
    String? observacao,
  }) async {
    final docRef  = _doc(denunciaId);
    final histRef = _historico(denunciaId).doc();

    await _db.runTransaction<void>((tx) async {
      final snap = await tx.get(docRef);
      if (!snap.exists) throw DenunciaNotFoundException();

      final data        = snap.data()!;
      final responsavel = data['orgaoResponsavelId'] as String?;
      if (responsavel != orgaoId) throw SemPermissaoException();

      final statusAtual =
          StatusDenunciaX.fromFirestore(data['status'] as String);
      if (statusAtual != StatusDenuncia.emAnalise &&
          statusAtual != StatusDenuncia.emAndamento) {
        throw TransicaoInvalidaException(statusAtual.label, 'aberta');
      }

      final bloqueioAte =
          Timestamp.fromDate(DateTime.now().add(_kBloqueio));

      tx.update(docRef, {
        'status':               'aberta',
        'orgaoResponsavelId':   null,
        'orgaoResponsavelNome': null,
        'acceptedAt':           null,
        'devolvidaAt':          FieldValue.serverTimestamp(),
        'bloqueadosAte.$orgaoId': bloqueioAte,
        'atualizadoEm':         FieldValue.serverTimestamp(),
      });

      tx.set(histRef, {
        'acao':           'devolveu',
        'orgaoId':        orgaoId,
        'orgaoNome':      orgaoNome,
        'statusAnterior': statusAtual.firestoreValue,
        'statusNovo':     'aberta',
        if (observacao != null) 'observacao': observacao,
        'ocorridoEm':     FieldValue.serverTimestamp(),
      });
    });
  }


  Future<void> alterarStatus({
    required String denunciaId,
    required String orgaoId,
    required String orgaoNome,
    required StatusDenuncia novo,
    String? observacao,
  }) async {
    final docRef  = _doc(denunciaId);
    final histRef = _historico(denunciaId).doc();

    await _db.runTransaction<void>((tx) async {
      final snap = await tx.get(docRef);
      if (!snap.exists) throw DenunciaNotFoundException();

      final data        = snap.data()!;
      final responsavel = data['orgaoResponsavelId'] as String?;
      if (responsavel != orgaoId) throw SemPermissaoException();

      final atual =
          StatusDenunciaX.fromFirestore(data['status'] as String);
      if (!atual.podeTansicionarPara(novo)) {
        throw TransicaoInvalidaException(atual.label, novo.label);
      }

      tx.update(docRef, {
        'status':       novo.firestoreValue,
        'atualizadoEm': FieldValue.serverTimestamp(),
      });

      tx.set(histRef, {
        'acao':           'status_alterado',
        'orgaoId':        orgaoId,
        'orgaoNome':      orgaoNome,
        'statusAnterior': atual.firestoreValue,
        'statusNovo':     novo.firestoreValue,
        if (observacao != null) 'observacao': observacao,
        'ocorridoEm':     FieldValue.serverTimestamp(),
      });
    });
  }


  Future<void> resetarDenunciasExpiradas() async {
    final limite = Timestamp.fromDate(
        DateTime.now().subtract(_kAutoReset));

    final snap = await _col
        .where('status', isEqualTo: 'em_analise')
        .where('acceptedAt', isLessThan: limite)
        .limit(20)
        .get();

    if (snap.docs.isEmpty) return;

    final batch = _db.batch();
    for (final doc in snap.docs) {
      final orgaoId   = doc.data()['orgaoResponsavelId']   as String?;
      final orgaoNome = doc.data()['orgaoResponsavelNome'] as String?;

      batch.update(doc.reference, {
        'status':               'aberta',
        'orgaoResponsavelId':   null,
        'orgaoResponsavelNome': null,
        'acceptedAt':           null,
        'atualizadoEm':         FieldValue.serverTimestamp(),
      });

      batch.set(_historico(doc.id).doc(), {
        'acao':           'auto_reset',
        'orgaoId':        orgaoId,
        'orgaoNome':      orgaoNome,
        'statusAnterior': 'em_analise',
        'statusNovo':     'aberta',
        'observacao':
            'Resetada automaticamente após ${_kAutoReset.inHours}h.',
        'ocorridoEm':     FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }


  List<Denuncia> _mapSnap(
          QuerySnapshot<Map<String, dynamic>> snap) =>
      snap.docs.map(Denuncia.fromFirestore).toList();

  static ClassificacaoUrgencia _urgenciaInicial(TipoOcorrencia t) {
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
