class Usuario {
  final String _id;
  final String _nome;
  final String _email;
  String _senha;
  String _telefone;
  DateTime _dataCadastro;
  
  final String _tipo;
  final String? _cnpj; 
  final String? _orgaoNome; 

  Usuario({
    required String id,
    required String nome,
    required String email,
    required String senha,
    required String tipo,
    String telefone = '',
    String? cnpj,
    String? orgaoNome,
    DateTime? dataCadastro,
  })  : _id = id,
        _nome = nome,
        _email = email,
        _senha = senha,
        _tipo = tipo,
        _telefone = telefone,
        _dataCadastro = dataCadastro ?? DateTime.now(),
        _cnpj = cnpj,
        _orgaoNome = orgaoNome;

  String get id => _id;
  String get nome => _nome;
  String get email => _email;
  String get telefone => _telefone;
  String get tipo => _tipo;
  String? get cnpj => _cnpj;
  String? get orgaoNome => _orgaoNome;
  DateTime get dataCadastro => _dataCadastro;

  set telefone(String value) {
    if (value.length >= 10 || value.isEmpty) {
      _telefone = value;
    }
  }

  factory Usuario.fromMap(Map<String, dynamic> map) {
    return Usuario(
      id: map['id'] ?? '',
      nome: map['nome'] ?? '',
      email: map['email'] ?? '',
      senha: '', 
      tipo: map['tipo'] ?? 'cidadao',
      telefone: map['telefone'] ?? '',
      cnpj: map['cnpj'],
      orgaoNome: map['orgaoNome'],
      dataCadastro: map['dataCadastro'] != null 
          ? DateTime.parse(map['dataCadastro']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    final Map<String, dynamic> map = {
      'id': _id,
      'nome': _nome,
      'email': _email,
      'tipo': _tipo,
      'telefone': _telefone,
      'dataCadastro': _dataCadastro.toIso8601String(),
    };

    if (_cnpj != null && _cnpj!.isNotEmpty) {
      map['cnpj'] = _cnpj!;
    }
    if (_orgaoNome != null && _orgaoNome!.isNotEmpty) {
      map['orgaoNome'] = _orgaoNome!;
    }

    return map;
  }

  bool validarSenha(String senha) => _senha == senha;
}