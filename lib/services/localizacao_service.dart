import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../models/localizacao.dart';

sealed class GpsResult {
  const GpsResult();
}

final class GpsSuccess extends GpsResult {
  final Localizacao localizacao;
  const GpsSuccess(this.localizacao);
}

final class GpsFailure extends GpsResult {
  final String mensagem;
  const GpsFailure(this.mensagem);
}

class LocalizacaoService {
  Future<GpsResult> obterLocalizacaoAtual() async {
    // Verifica se o serviço de GPS está ativado no dispositivo
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return const GpsFailure(
          'GPS desativado. Ative a localização nas configurações do dispositivo.');
    }

    // Verifica e solicita permissão
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return const GpsFailure(
            'Permissão de localização negada. '
            'Permita o acesso para usar esta função.');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return const GpsFailure(
          'Permissão de localização bloqueada permanentemente. '
          'Acesse as configurações do app para habilitar.');
    }

    // Obtém posição com alta precisão (melhor para marcar ocorrências)
    final Position position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,   // GPS chip + triangulação
        distanceFilter: 0,                 // sem filtro de distância
        timeLimit: Duration(seconds: 20),  // timeout para não travar a UI
      ),
    );

    // Reverse geocoding: reverte as coordenadas para texto legivel
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isEmpty) {
        return GpsSuccess(Localizacao(
          endereco: 'Localização GPS',
          cidade: '',
          estado: '',
          cep: '',
          latitude: position.latitude,
          longitude: position.longitude,
          precisaoMetros: position.accuracy,
        ));
      }

      final p = placemarks.first;

      // Monta endereço no padrão brasileiro
      final rua    = p.street    ?? p.thoroughfare  ?? '';
      final numero = p.subThoroughfare ?? '';
      final bairro = p.subLocality ?? p.locality    ?? '';
      final cidade = p.subAdministrativeArea
                  ?? p.administrativeArea
                  ?? p.locality
                  ?? '';
      final estado = _normalizarEstado(p.administrativeArea ?? '');
      final cep    = _formatarCep(p.postalCode ?? '');

      final enderecoCompleto = [
        if (rua.isNotEmpty) rua,
        if (numero.isNotEmpty) numero,
        if (bairro.isNotEmpty && bairro != rua) bairro,
      ].join(', ');

      return GpsSuccess(Localizacao(
        endereco: enderecoCompleto.isNotEmpty
            ? enderecoCompleto
            : 'Localização GPS (${position.latitude.toStringAsFixed(5)}, '
              '${position.longitude.toStringAsFixed(5)})',
        cidade: cidade,
        estado: estado,
        cep: cep,
        latitude: position.latitude,
        longitude: position.longitude,
        precisaoMetros: position.accuracy,
      ));
    } catch (_) {
      // Reverse geocoding falhou — retorna só as coordenadas
      return GpsSuccess(Localizacao(
        endereco: 'Lat: ${position.latitude.toStringAsFixed(6)}, '
                  'Lon: ${position.longitude.toStringAsFixed(6)}',
        cidade: '',
        estado: '',
        cep: '',
        latitude: position.latitude,
        longitude: position.longitude,
        precisaoMetros: position.accuracy,
      ));
    }
  }

  bool validarEndereco(Localizacao loc) => loc.valido();

  static String _normalizarEstado(String raw) {
    final mapa = {
      'acre': 'AC', 'alagoas': 'AL', 'amapá': 'AP', 'amazonas': 'AM',
      'bahia': 'BA', 'ceará': 'CE', 'distrito federal': 'DF',
      'espírito santo': 'ES', 'goiás': 'GO', 'maranhão': 'MA',
      'mato grosso do sul': 'MS', 'mato grosso': 'MT', 'minas gerais': 'MG',
      'pará': 'PA', 'paraíba': 'PB', 'paraná': 'PR', 'pernambuco': 'PE',
      'piauí': 'PI', 'rio de janeiro': 'RJ', 'rio grande do norte': 'RN',
      'rio grande do sul': 'RS', 'rondônia': 'RO', 'roraima': 'RR',
      'santa catarina': 'SC', 'são paulo': 'SP', 'sergipe': 'SE',
      'tocantins': 'TO',
    };
    final siglas = {
      'AC','AL','AP','AM','BA','CE','DF','ES','GO','MA','MT','MS','MG',
      'PA','PB','PR','PE','PI','RJ','RN','RS','RO','RR','SC','SP','SE','TO',
    };
    final limpo = raw.trim().toUpperCase();
    if (siglas.contains(limpo)) return limpo;
    return mapa[raw.trim().toLowerCase()] ?? raw.trim().toUpperCase();
  }

  static String _formatarCep(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 8) return '${digits.substring(0, 5)}-${digits.substring(5)}';
    return raw;
  }
}
