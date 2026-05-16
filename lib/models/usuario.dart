import 'tipo_usuario.dart';

/// Modelo de usuário autenticado (cidadão ou órgão).
class Usuario {
  final String id;
  String nome;
  String email;
  String senha;
  String? orgaoNome;
  String? cnpj;   // apenas órgão
  String? cpf;    // apenas cidadão
  final TipoUsuario tipo;

  Usuario({
    required this.id,
    required this.nome,
    required this.email,
    required this.senha,
    this.orgaoNome,
    this.cnpj,
    this.cpf,
    required this.tipo,
  });
}