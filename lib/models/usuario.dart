import 'tipo_usuario.dart';


class Usuario {
  final String id;
  String nome;
  String email;
  String senha;
  String? orgaoNome;
  String? cnpj;
  String? cpf;
  String? telefone;
  final TipoUsuario tipo;

  Usuario({
    required this.id,
    required this.nome,
    required this.email,
    required this.senha,
    this.orgaoNome,
    this.cnpj,
    this.cpf,
    this.telefone,
    required this.tipo,
  });
}
