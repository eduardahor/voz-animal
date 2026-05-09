import 'tipo_usuario.dart';

/// Modelo de usuário autenticado (cidadão ou órgão).
class Usuario {
  final String id;
  String nome;
  String email;
  String senha;
  String? orgaoNome;
  final TipoUsuario tipo;

  Usuario({
    required this.id,
    required this.nome,
    required this.email,
    required this.senha,
    this.orgaoNome,
    required this.tipo,
  });
}