const List<String> ufsBrasil = [
  'AC','AL','AP','AM','BA','CE','DF','ES','GO','MA','MT','MS','MG',
  'PA','PB','PR','PE','PI','RJ','RN','RS','RO','RR','SC','SP','SE','TO',
];

class Localizacao {
  String endereco;
  String cidade;
  String cep;
  double? latitude;
  double? longitude;
  double? precisaoMetros;

  String _estado;

  Localizacao({
    required this.endereco,
    required this.cidade,
    required String estado,
    required this.cep,
    this.latitude,
    this.longitude,
    this.precisaoMetros,
  }) : _estado = estado.toUpperCase();

  String get estado => _estado;
  set estado(String v) => _estado = v.toUpperCase();

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

  static final RegExp _regexCep     = RegExp(r'^\d{5}-?\d{3}$');
  static final RegExp _regexNumero  = RegExp(r'\d+');

  bool valido() {
    // Se tem coordenadas GPS, o endereço mínimo é aceito
    if (temGps) {
      return endereco.trim().isNotEmpty;
    }
    // Validação completa para endereço manual
    return endereco.trim().length >= 5 &&
        _regexNumero.hasMatch(endereco) &&
        cidade.trim().length >= 2 &&
        ufsBrasil.contains(_estado) &&
        _regexCep.hasMatch(cep.trim());
  }

  String resumo() {
    if (temGps && cidade.isEmpty) {
      return '$endereco (GPS: ${latitude!.toStringAsFixed(5)}, '
          '${longitude!.toStringAsFixed(5)})';
    }
    return '$endereco — $cidade/$_estado'
        '${cep.isNotEmpty ? " (CEP $cep)" : ""}';
  }

  @override
  String toString() => resumo();


  Map<String, dynamic> toMap() => {
    'endereco': endereco,
    'cidade': cidade,
    'estado': _estado,
    'cep': cep,
    if (latitude != null) 'latitude': latitude,
    if (longitude != null) 'longitude': longitude,
    if (precisaoMetros != null) 'precisaoMetros': precisaoMetros,
  };

  factory Localizacao.fromMap(Map<String, dynamic> m) => Localizacao(
    endereco: m['endereco'] as String,
    cidade: m['cidade'] as String,
    estado: m['estado'] as String,
    cep: m['cep'] as String,
    latitude: (m['latitude'] as num?)?.toDouble(),
    longitude: (m['longitude'] as num?)?.toDouble(),
    precisaoMetros: (m['precisaoMetros'] as num?)?.toDouble(),
  );
}
