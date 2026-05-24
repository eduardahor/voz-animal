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
  String _estado;

  Localizacao({
    required this.endereco,
    required this.cidade,
    required String estado,
    required this.cep,
    this.latitude,
    this.longitude,
  }) : _estado = estado.toUpperCase();

  String get estado => _estado;
  set estado(String v) => _estado = v.toUpperCase();

  static final RegExp _regexCep = RegExp(r'^\d{5}-?\d{3}$');
  static final RegExp _regexNumero = RegExp(r'\d+');

  bool valido() =>
      endereco.trim().length >= 5 &&
      _regexNumero.hasMatch(endereco) &&
      cidade.trim().length >= 2 &&
      ufsBrasil.contains(_estado) &&
      _regexCep.hasMatch(cep.trim());

  String resumo() => '$endereco — $cidade/$_estado (CEP $cep)';

  @override
  String toString() => resumo();


  Map<String, dynamic> toMap() => {
    'endereco': endereco,
    'cidade': cidade,
    'estado': _estado,
    'cep': cep,
    if (latitude != null) 'latitude': latitude,
    if (longitude != null) 'longitude': longitude,
  };

  factory Localizacao.fromMap(Map<String, dynamic> m) => Localizacao(
    endereco: m['endereco'] as String,
    cidade: m['cidade'] as String,
    estado: m['estado'] as String,
    cep: m['cep'] as String,
    latitude: (m['latitude'] as num?)?.toDouble(),
    longitude: (m['longitude'] as num?)?.toDouble(),
  );
}
