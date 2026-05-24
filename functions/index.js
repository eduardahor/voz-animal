// functions/index.js
// Cloud Functions para o projeto Voz Animal
// Deploy: firebase deploy --only functions

const { onSchedule } = require('firebase-functions/v2/scheduler');
const { getFirestore, FieldValue, Timestamp } = require('firebase-admin/firestore');
const { initializeApp } = require('firebase-admin/app');

initializeApp();
const db = getFirestore();

const COLECAO = 'denuncias';
const LIMITE_HORAS = 48;

/**
 * Roda a cada hora e reseta denúncias em_analise paradas há mais de 48h.
 * Prevenção: usa batch atômico, até 200 documentos por execução.
 */
exports.autoResetDenunciasExpiradas = onSchedule(
  {
    schedule: 'every 1 hours',
    timeZone: 'America/Sao_Paulo',
    region: 'southamerica-east1',   // São Paulo
    memory: '256MiB',
  },
  async (_event) => {
    const corte = Timestamp.fromMillis(
      Date.now() - LIMITE_HORAS * 60 * 60 * 1000
    );

    const snap = await db
      .collection(COLECAO)
      .where('status', '==', 'em_analise')
      .where('acceptedAt', '<', corte)
      .limit(200)
      .get();

    if (snap.empty) {
      console.log('[autoReset] Nenhuma denúncia expirada.');
      return;
    }

    const batch = db.batch();

    snap.docs.forEach((doc) => {
      const { orgaoResponsavelId, orgaoResponsavelNome } = doc.data();

      // Reseta denúncia
      batch.update(doc.ref, {
        status: 'aberta',
        orgaoResponsavelId: null,
        orgaoResponsavelNome: null,
        acceptedAt: null,
        atualizadoEm: FieldValue.serverTimestamp(),
      });

      // Registra no histórico
      const histRef = doc.ref.collection('historico').doc();
      batch.set(histRef, {
        acao: 'auto_reset',
        orgaoId: orgaoResponsavelId ?? null,
        orgaoNome: orgaoResponsavelNome ?? null,
        statusAnterior: 'em_analise',
        statusNovo: 'aberta',
        observacao: `Resetada automaticamente após ${LIMITE_HORAS}h sem movimentação.`,
        ocorridoEm: FieldValue.serverTimestamp(),
      });
    });

    await batch.commit();
    console.log(`[autoReset] ${snap.size} denúncia(s) resetada(s).`);
  }
);

/**
 * Trigger: ao criar uma denúncia, calcula urgência automaticamente no server.
 * Garante que a urgência não seja manipulada pelo cliente.
 */
exports.calcularUrgencia = require('firebase-functions/v2/firestore')
  .onDocumentCreated(`${COLECAO}/{denunciaId}`, async (event) => {
    const data = event.data?.data();
    if (!data || data.urgencia) return; // já veio com urgência

    const tipo = data.tipo;
    const urgencia = _urgenciaPorTipo(tipo);

    await event.data.ref.update({ urgencia });
    console.log(`[calcularUrgencia] ${event.params.denunciaId} → ${urgencia}`);
  });

function _urgenciaPorTipo(tipo) {
  switch (tipo) {
    case 'agressao':
    case 'mutilacao':
    case 'abuso_sexual':
    case 'rinha':
      return 'critica';
    case 'trafico_silvestres':
    case 'aprisionamento':
      return 'alta';
    default:
      return 'media';
  }
}
