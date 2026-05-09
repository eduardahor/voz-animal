/// Lista oficial de UFs do Brasil.
const List<String> ufsBrasil = [
  'AC','AL','AP','AM','BA','CE','DF','ES','GO','MA','MT','MS','MG',
  'PA','PB','PR','PE','PI','RJ','RN','RS','RO','RR','SC','SP','SE','TO',
];

/// Endereço/localização de uma ocorrência.
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
  })  : _estado = estado.toUpperCase();

  String get estado => _estado;
  set estado(String v) => _estado = v.toUpperCase();

  static final RegExp _regexCep = RegExp(r'^\d{5}-?\d{3}$');
  static final RegExp _regexEnderecoComNumero = RegExp(r'\d+');

  bool valido() {
    final enderecoOk = endereco.trim().length >= 5 &&
        _regexEnderecoComNumero.hasMatch(endereco);
    final cidadeOk = cidade.trim().length >= 2;
    final estadoOk = ufsBrasil.contains(_estado);
    final cepOk = _regexCep.hasMatch(cep.trim());
    return enderecoOk && cidadeOk && estadoOk && cepOk;
  }

  String resumo() => '$endereco — $cidade/$_estado (CEP $cep)';

  @override
  String toString() => resumo();
}