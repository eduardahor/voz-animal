/// Classe que representa uma localização geográfica (simulada).
class Localizacao {
  final double _latitude;
  final double _longitude;
  final String _endereco;

  // Encapsulamento: campos privados com getters
  Localizacao({
    required double latitude,
    required double longitude,
    required String endereco,
  })  : _latitude = latitude,
        _longitude = longitude,
        _endereco = endereco;

  double get latitude => _latitude;
  double get longitude => _longitude;
  String get endereco => _endereco;

  /// Localização simulada padrão
  factory Localizacao.simulada() {
    return Localizacao(
      latitude: -23.5505,
      longitude: -46.6333,
      endereco: 'Av. Paulista, 1000 - São Paulo, SP',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'latitude': _latitude,
      'longitude': _longitude,
      'endereco': _endereco,
    };
  }

  factory Localizacao.fromMap(Map<String, dynamic> map) {
    return Localizacao(
      latitude: map['latitude'] as double,
      longitude: map['longitude'] as double,
      endereco: map['endereco'] as String,
    );
  }

  @override
  String toString() => _endereco;
}
