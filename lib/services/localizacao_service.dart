import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
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


sealed class CepResult {
  const CepResult();
}

final class CepSuccess extends CepResult {
  final String rua;
  final String bairro;
  final String cidade;
  final String estado;
  const CepSuccess({
    required this.rua,
    required this.bairro,
    required this.cidade,
    required this.estado,
  });
}

final class CepNaoEncontrado extends CepResult {
  const CepNaoEncontrado();
}

final class CepFalhaRede extends CepResult {
  const CepFalhaRede();
}

class LocalizacaoService {

  Future<GpsResult> obterLocalizacaoAtual() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return const GpsFailure(
          'GPS desativado. Ative a localização nas configurações do dispositivo.');
    }

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

    final Position position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 0,
        timeLimit: Duration(seconds: 20),
      ),
    );

    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isEmpty) {
        return GpsSuccess(Localizacao(
          rua: 'Localização GPS',
          cidade: '',
          estado: '',
          latitude: position.latitude,
          longitude: position.longitude,
          precisaoMetros: position.accuracy,
        ));
      }

      final p = placemarks.first;
      final rua    = p.street ?? p.thoroughfare ?? '';
      final numero = p.subThoroughfare ?? '';
      final bairro = p.subLocality ?? '';
      final cidade = p.subAdministrativeArea
                  ?? p.administrativeArea
                  ?? p.locality
                  ?? '';
      final estado = normalizarEstado(p.administrativeArea ?? '');
      final cep    = formatarCep(p.postalCode ?? '');

      return GpsSuccess(Localizacao(
        rua: rua.isNotEmpty
            ? rua
            : 'GPS (${position.latitude.toStringAsFixed(5)}, '
              '${position.longitude.toStringAsFixed(5)})',
        numero: numero,
        bairro: bairro,
        cidade: cidade,
        estado: estado,
        cep: cep,
        latitude: position.latitude,
        longitude: position.longitude,
        precisaoMetros: position.accuracy,
      ));
    } catch (_) {
      return GpsSuccess(Localizacao(
        rua: 'Lat: ${position.latitude.toStringAsFixed(6)}, '
             'Lon: ${position.longitude.toStringAsFixed(6)}',
        cidade: '',
        estado: '',
        latitude: position.latitude,
        longitude: position.longitude,
        precisaoMetros: position.accuracy,
      ));
    }
  }

  // ── Busca por CEP (ViaCEP) ────────────────────────────────────────────────
  //
  // Usada para AUTO-PREENCHER rua/bairro/cidade/UF quando o usuário sabe o
  // CEP — mas o CEP nunca é exigido. Se a busca falhar (CEP não existe, sem
  // internet, etc.) o usuário simplesmente continua preenchendo manualmente.

  Future<CepResult> buscarPorCep(String cepBruto) async {
    final digits = cepBruto.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 8) return const CepNaoEncontrado();

    try {
      final uri = Uri.parse('https://viacep.com.br/ws/$digits/json/');
      final resp = await http.get(uri).timeout(const Duration(seconds: 6));

      if (resp.statusCode != 200) return const CepFalhaRede();

      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      if (data['erro'] == true) return const CepNaoEncontrado();

      return CepSuccess(
        rua:    (data['logradouro'] as String?) ?? '',
        bairro: (data['bairro']     as String?) ?? '',
        cidade: (data['localidade'] as String?) ?? '',
        estado: (data['uf']         as String?) ?? '',
      );
    } catch (_) {
      return const CepFalhaRede();
    }
  }

  bool validarEndereco(Localizacao loc) => loc.valido();

  static String normalizarEstado(String raw) {
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

  static String formatarCep(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 8) return '${digits.substring(0, 5)}-${digits.substring(5)}';
    return raw;
  }
}
