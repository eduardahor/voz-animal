import 'package:flutter/foundation.dart';
import '../models/usuario.dart';
import '../models/tipo_usuario.dart';

/// Serviço simples de autenticação simulada (login + cadastro em memória).
class AuthService extends ChangeNotifier {
  Usuario? _usuarioAtual;
  final List<_Conta> _contas = [];

  Usuario? get usuarioAtual => _usuarioAtual;
  bool get autenticado => _usuarioAtual != null;

  // Aliases para compatibilidade com telas que usam logado / isOrgao.
  bool get logado => autenticado;
  bool get isOrgao =>
      _usuarioAtual != null && _usuarioAtual!.tipo == TipoUsuario.orgao;
  bool get isCidadao =>
      _usuarioAtual != null && _usuarioAtual!.tipo == TipoUsuario.cidadao;

  Future<bool> login({
    required String email,
    required String senha,
    required TipoUsuario tipoEsperado,
  }) async {
    if (email.isEmpty || senha.length < 4) return false;

    // Procura conta cadastrada com mesmo email + tipo.
    final conta = _contas.cast<_Conta?>().firstWhere(
          (c) =>
              c!.email.toLowerCase() == email.toLowerCase() &&
              c.tipo == tipoEsperado,
          orElse: () => null,
        );
    if (conta != null && conta.senha != senha) return false;

    _usuarioAtual = Usuario(
      id: conta?.id ?? 'u-${DateTime.now().millisecondsSinceEpoch}',
      nome: conta?.nome ??
          (tipoEsperado == TipoUsuario.orgao
              ? 'Órgão Responsável'
              : 'Cidadão'),
      email: email,
      senha: senha,
      tipo: tipoEsperado,
    );
    notifyListeners();
    return true;
  }

  /// Cadastra um novo usuário/órgão. Retorna `null` em sucesso ou
  /// uma mensagem de erro descritiva.
  String? cadastrar({
    required String nome,
    required String email,
    required String senha,
    required TipoUsuario tipo,
    String? orgaoNome,
  }) {
    if (nome.trim().isEmpty) return 'Informe o nome.';
    if (!email.contains('@')) return 'E-mail inválido.';
    if (senha.length < 8) return 'Senha precisa ter ao menos 8 caracteres.';
    if (tipo == TipoUsuario.orgao &&
        (orgaoNome == null || orgaoNome.trim().isEmpty)) {
      return 'Informe o nome do órgão.';
    }
    final jaExiste = _contas.any((c) =>
        c.email.toLowerCase() == email.toLowerCase() && c.tipo == tipo);
    if (jaExiste) return 'Já existe uma conta com este e-mail.';

    final conta = _Conta(
      id: 'u-${DateTime.now().millisecondsSinceEpoch}',
      nome: tipo == TipoUsuario.orgao ? (orgaoNome ?? nome) : nome,
      email: email,
      senha: senha,
      tipo: tipo,
    );
    _contas.add(conta);
    _usuarioAtual = Usuario(
      id: conta.id,
      nome: conta.nome,
      email: conta.email,
      senha: conta.senha,
      tipo: conta.tipo,
    );
    notifyListeners();
    return null;
  }

  void logout() {
    _usuarioAtual = null;
    notifyListeners();
  }
}

class _Conta {
  final String id;
  final String nome;
  final String email;
  final String senha;
  final TipoUsuario tipo;
  _Conta({
    required this.id,
    required this.nome,
    required this.email,
    required this.senha,
    required this.tipo,
  });
}
