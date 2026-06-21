const List<String> ufsBrasil = [
  'AC','AL','AP','AM','BA','CE','DF','ES','GO','MA','MT','MS','MG',
  'PA','PB','PR','PE','PI','RJ','RN','RS','RO','RR','SC','SP','SE','TO',
];

class Localizacao {
  String rua;
  String numero;
  String bairro;
  String cidade;
  String cep;
  double? latitude;
  double? longitude;
  double? precisaoMetros;

  String _estado;

  Localizacao({
    required this.rua,
    this.numero = '',
    this.bairro = '',
    required this.cidade,
    required String estado,
    this.cep = '',
    this.latitude,
    this.longitude,
    this.precisaoMetros,
  }) : _estado = estado.toUpperCase();

  String get estado => _estado;
  set estado(String v) => _estado = v.toUpperCase();

  /// Endereço completo formatado para exibição (rua, número — bairro).
  String get endereco {
    final partes = <String>[];
    if (rua.trim().isNotEmpty) {
      partes.add(numero.trim().isNotEmpty ? '${rua.trim()}, ${numero.trim()}' : rua.trim());
    }
    if (bairro.trim().isNotEmpty) partes.add(bairro.trim());
    return partes.join(' — ');
  }

  /// Localização veio do GPS.
  bool get temGps => latitude != null && longitude != null;

  /// Precisão do GPS como texto legível.
  String get precisaoLabel {
    if (precisaoMetros == null) return 'Manual';
    if (precisaoMetros! <= 5)   return 'Excelente (±${precisaoMetros!.toStringAsFixed(0)} m)';
    if (precisaoMetros! <= 15)  return 'Boa (±${precisaoMetros!.toStringAsFixed(0)} m)';
    if (precisaoMetros! <= 50)  return 'Razoável (±${precisaoMetros!.toStringAsFixed(0)} m)';
    return 'Baixa (±${precisaoMetros!.toStringAsFixed(0)} m)';
  }

  int get precisaoCor {
    if (precisaoMetros == null) return 0xFF9E9E9E;
    if (precisaoMetros! <= 5)   return 0xFF4CAF50;
    if (precisaoMetros! <= 15)  return 0xFF8BC34A;
    if (precisaoMetros! <= 50)  return 0xFFFFC107;
    return 0xFFFF5722;
  }

  static final RegExp _regexCep = RegExp(r'^\d{5}-?\d{3}$');

  /// Validação pensada para o cenário real: um cidadão denunciando uma
  /// ocorrência de rua quase nunca sabe o CEP ou o número exato do imóvel.
  /// Por isso CEP e número são sempre OPCIONAIS — o que é obrigatório é
  /// haver uma referência mínima de onde a ocorrência aconteceu:
  /// (rua OU GPS) + cidade + estado.
  bool valido() {
    if (temGps) {
      // GPS já garante a localização exata; texto é só complemento.
      return true;
    }

    final cepOk = cep.trim().isEmpty || _regexCep.hasMatch(cep.trim());

    return rua.trim().length >= 3 &&
        cidade.trim().length >= 2 &&
        ufsBrasil.contains(_estado) &&
        cepOk;
  }

  String resumo() {
    if (temGps && cidade.isEmpty) {
      return '${endereco.isEmpty ? "Local marcado no mapa" : endereco} '
          '(GPS: ${latitude!.toStringAsFixed(5)}, ${longitude!.toStringAsFixed(5)})';
    }
    final end = endereco.isEmpty ? 'Endereço não detalhado' : endereco;
    return '$end — $cidade/$_estado'
        '${cep.isNotEmpty ? " (CEP $cep)" : ""}';
  }

  @override
  String toString() => resumo();

  // ── Serialização ──────────────────────────────────────────────

  Map<String, dynamic> toMap() => {
    'rua': rua,
    'numero': numero,
    'bairro': bairro,
    'cidade': cidade,
    'estado': _estado,
    'cep': cep,
    if (latitude != null) 'latitude': latitude,
    if (longitude != null) 'longitude': longitude,
    if (precisaoMetros != null) 'precisaoMetros': precisaoMetros,
  };

  factory Localizacao.fromMap(Map<String, dynamic> m) => Localizacao(
    rua: (m['rua'] ?? m['endereco'] ?? '') as String, // compat com dados antigos
    numero: (m['numero'] ?? '') as String,
    bairro: (m['bairro'] ?? '') as String,
    cidade: m['cidade'] as String,
    estado: m['estado'] as String,
    cep: (m['cep'] ?? '') as String,
    latitude: (m['latitude'] as num?)?.toDouble(),
    longitude: (m['longitude'] as num?)?.toDouble(),
    precisaoMetros: (m['precisaoMetros'] as num?)?.toDouble(),
  );
}
