import '../models/localizacao.dart';

/// Serviço de localização simulada e validação de endereço.
class LocalizacaoService {
  /// Mock determinístico — em produção usaria geolocator + reverse geocoding.
  Future<Localizacao> obterAtualSimulada() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return Localizacao(
      endereco: 'Av. Paulista, 1000',
      cidade: 'São Paulo',
      estado: 'SP',
      cep: '01310-100',
      latitude: -23.5613,
      longitude: -46.6558,
    );
  }

  bool validarEndereco(Localizacao loc) => loc.valido();
}
