/// Classe que representa um usuário do sistema.
/// Demonstra encapsulamento com campos privados e getters/setters.
class Usuario {
  final String _id;
  final String _nome;
  final String _email;
  String _senha;
  String _telefone;
  DateTime _dataCadastro;

  Usuario({
    required String id,
    required String nome,
    required String email,
    required String senha,
    String telefone = '',
  })  : _id = id,
        _nome = nome,
        _email = email,
        _senha = senha,
        _telefone = telefone,
        _dataCadastro = DateTime.now();

  // Getters (encapsulamento)
  String get id => _id;
  String get nome => _nome;
  String get email => _email;
  String get telefone => _telefone;
  DateTime get dataCadastro => _dataCadastro;

  // Setter com validação
  set telefone(String value) {
    if (value.length >= 10 || value.isEmpty) {
      _telefone = value;
    }
  }

  bool validarSenha(String senha) => _senha == senha;

  void alterarSenha(String senhaAtual, String novaSenha) {
    if (validarSenha(senhaAtual)) {
      _senha = novaSenha;
    } else {
      throw Exception('Senha atual incorreta');
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': _id,
      'nome': _nome,
      'email': _email,
      'telefone': _telefone,
      'dataCadastro': _dataCadastro.toIso8601String(),
    };
  }
}
