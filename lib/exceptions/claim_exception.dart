/// Exceções de domínio do sistema de claim.
sealed class ClaimException implements Exception {
  final String mensagem;
  const ClaimException(this.mensagem);

  @override
  String toString() => mensagem;
}

final class DenunciaJaAssumidaException extends ClaimException {
  const DenunciaJaAssumidaException([
    super.mensagem = 'Esta denúncia já foi assumida por outro órgão.',
  ]);
}

final class OrgaoBloqueadoException extends ClaimException {
  final DateTime bloqueadoAte;
  OrgaoBloqueadoException(this.bloqueadoAte)
      : super(
          'Você devolveu esta denúncia recentemente e só poderá reassumi-la '
          'após ${_fmt(bloqueadoAte)}.',
        );

  static String _fmt(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/'
      '${dt.month.toString().padLeft(2, '0')} '
      '${dt.hour.toString().padLeft(2, '0')}:'
      '${dt.minute.toString().padLeft(2, '0')}';
}

final class TransicaoInvalidaException extends ClaimException {
  const TransicaoInvalidaException(String de, String para)
      : super('Não é possível mudar de "$de" para "$para".');
}

final class SemPermissaoException extends ClaimException {
  const SemPermissaoException()
      : super('Você não é o responsável por esta denúncia.');
}

final class DenunciaNotFoundException extends ClaimException {
  const DenunciaNotFoundException()
      : super('Denúncia não encontrada.');
}
