class Localizacao {
  final double latitude;
  final double longitude;
  final String? endereco;

  Localizacao({
    required this.latitude,
    required this.longitude,
    this.endereco,
  });

  String get enderecoFormatado =>
      endereco ?? 'Lat: \${latitude.toStringAsFixed(4)}, Lng: \${longitude.toStringAsFixed(4)}';
}
