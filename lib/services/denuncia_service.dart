import 'package:flutter/foundation.dart';
import '../models/denuncia.dart';
import '../models/historico_item.dart';
import '../models/status_denuncia.dart';
import '../models/tipo_ocorrencia.dart';
import '../models/localizacao.dart';
import '../repositories/denuncia_repository.dart';
import '../exceptions/claim_exception.dart';


sealed class ClaimResult {
  const ClaimResult();
}
final class ClaimSuccess extends ClaimResult {
  final String mensagem;
  const ClaimSuccess(this.mensagem);
}
final class ClaimFailure extends ClaimResult {
  final String mensagem;
  final bool bloqueado;
  const ClaimFailure(this.mensagem, {this.bloqueado = false});
}

/// Service de denúncias: orquestra Repository e expõe Streams para a UI.
class DenunciaService extends ChangeNotifier {
  DenunciaService({DenunciaRepository? repo})
      : _repo = repo ?? DenunciaRepository();

  final DenunciaRepository _repo;


  Stream<List<Denuncia>> abertas() => _repo.abertas();

  Stream<List<Denuncia>> doOrgao(String orgaoId) => _repo.doOrgao(orgaoId);

  Stream<List<Denuncia>> doCidadao(String usuarioId) =>
      _repo.doCidadao(usuarioId);

  Stream<List<HistoricoItem>> historicoDe(String denunciaId) =>
      _repo.historicoDe(denunciaId);


  Future<String?> criar({
    required String usuarioId,
    required String descricao,
    required TipoOcorrencia tipo,
    required Localizacao localizacao,
    String? fotoUrl,
  }) async {
    try {
      return await _repo.criar(
        usuarioId: usuarioId,
        descricao: descricao,
        tipo: tipo,
        localizacao: localizacao,
        fotoUrl: fotoUrl,
      );
    } catch (e) {
      debugPrint('[DenunciaService.criar] $e');
      rethrow;
    }
  }


  Future<ClaimResult> assumir({
    required String denunciaId,
    required String orgaoId,
    required String orgaoNome,
  }) async {
    try {
      await _repo.assumir(
        denunciaId: denunciaId,
        orgaoId: orgaoId,
        orgaoNome: orgaoNome,
      );
      return const ClaimSuccess('Denúncia assumida com sucesso!');
    } on DenunciaJaAssumidaException catch (e) {
      return ClaimFailure(e.mensagem);
    } on OrgaoBloqueadoException catch (e) {
      return ClaimFailure(e.mensagem, bloqueado: true);
    } on ClaimException catch (e) {
      return ClaimFailure(e.mensagem);
    } catch (e) {
      debugPrint('[DenunciaService.assumir] $e');
      return const ClaimFailure('Erro inesperado. Tente novamente.');
    }
  }


  Future<ClaimResult> devolver({
    required String denunciaId,
    required String orgaoId,
    required String orgaoNome,
    String? observacao,
  }) async {
    try {
      await _repo.devolver(
        denunciaId: denunciaId,
        orgaoId: orgaoId,
        orgaoNome: orgaoNome,
        observacao: observacao,
      );
      return const ClaimSuccess('Denúncia devolvida. Outros órgãos poderão assumí-la.');
    } on ClaimException catch (e) {
      return ClaimFailure(e.mensagem);
    } catch (e) {
      debugPrint('[DenunciaService.devolver] $e');
      return const ClaimFailure('Erro inesperado. Tente novamente.');
    }
  }


  Future<ClaimResult> alterarStatus({
    required String denunciaId,
    required String orgaoId,
    required String orgaoNome,
    required StatusDenuncia novo,
    String? observacao,
  }) async {
    try {
      await _repo.alterarStatus(
        denunciaId: denunciaId,
        orgaoId: orgaoId,
        orgaoNome: orgaoNome,
        novo: novo,
        observacao: observacao,
      );
      return ClaimSuccess('Status alterado para "${novo.label}".');
    } on ClaimException catch (e) {
      return ClaimFailure(e.mensagem);
    } catch (e) {
      debugPrint('[DenunciaService.alterarStatus] $e');
      return const ClaimFailure('Erro inesperado. Tente novamente.');
    }
  }

  Future<void> resetarExpiradas() => _repo.resetarDenunciasExpiradas();
}
