import 'tipo_usuario.dart';

class Usuario {
  String id;
  String nome;
  String email;
  final String _senha;
  final TipoUsuario tipo;
  final String? orgaoNome;
  final DateTime dataCadastro;

  Usuario({
    required this.id,
    required this.nome,
    required this.email,
    required String senha,
    this.tipo = TipoUsuario.cidadao,
    this.orgaoNome,
  })  : _senha = senha,
        dataCadastro = DateTime.now();

  bool verificarSenha(String senha) => _senha == senha;
  bool autenticar(String senha) => _senha == senha;
}
