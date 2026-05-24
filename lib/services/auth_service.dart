import 'package:flutter/foundation.dart';
import '../models/usuario.dart';
import '../models/tipo_usuario.dart';


class AuthService extends ChangeNotifier {
  Usuario? _usuarioAtual;
  final List<_Conta> _contas = [];

  Usuario? get usuarioAtual => _usuarioAtual;
  bool get autenticado => _usuarioAtual != null;

  bool get logado => autenticado;
  bool get isOrgao =>
      _usuarioAtual != null && _usuarioAtual!.tipo == TipoUsuario.orgao;
  bool get isCidadao =>
      _usuarioAtual != null && _usuarioAtual!.tipo == TipoUsuario.cidadao;

  Future<bool> login({
    required String email,
    required String senha,
    required TipoUsuario tipoEsperado,
    String? cnpj,
  }) async {
    if (email.isEmpty || senha.length < 4) return false;

    final conta = _contas.cast<_Conta?>().firstWhere(
          (c) =>
              c!.email.toLowerCase() == email.toLowerCase() &&
              c.tipo == tipoEsperado,
          orElse: () => null,
        );

    if (conta != null && conta.senha != senha) return false;

    if (tipoEsperado == TipoUsuario.orgao) {
      if (cnpj == null || cnpj.trim().isEmpty) return false;

      final cnpjInformado = cnpj.replaceAll(RegExp(r'\D'), '');
      final cnpjCadastrado = (conta!.cnpj ?? '').replaceAll(RegExp(r'\D'), '');

      if (cnpjInformado != cnpjCadastrado) return false;
    }

    _usuarioAtual = Usuario(
      id: conta?.id ?? 'u-${DateTime.now().millisecondsSinceEpoch}',
      nome: conta?.nome ??
          (tipoEsperado == TipoUsuario.orgao ? 'Órgão Responsável' : 'Cidadão'),
      email: email,
      senha: senha,
      tipo: tipoEsperado,
      cnpj: conta?.cnpj,
      cpf: conta?.cpf,
    );
    notifyListeners();
    return true;
  }


  String? cadastrar({
    required String nome,
    required String email,
    required String senha,
    required TipoUsuario tipo,
    String? orgaoNome,
    String? cnpj,
    String? cpf,
  }) {
    if (nome.trim().isEmpty) return 'Informe o nome.';
    if (!email.contains('@')) return 'E-mail inválido.';
    if (senha.length < 8) return 'Senha precisa ter ao menos 8 caracteres.';

    if (tipo == TipoUsuario.orgao) {
      if (orgaoNome == null || orgaoNome.trim().isEmpty) {
        return 'Informe o nome do órgão.';
      }
      final cnpjLimpo = (cnpj ?? '').replaceAll(RegExp(r'\D'), '');
      if (cnpjLimpo.length != 14) return 'CNPJ inválido (14 dígitos).';
    }

    if (tipo == TipoUsuario.cidadao) {
      final cpfLimpo = (cpf ?? '').replaceAll(RegExp(r'\D'), '');
      if (cpfLimpo.length != 11) return 'CPF inválido (11 dígitos).';
    }

    // Verificação de duplicidades
    final emailDuplicado = _contas.any(
      (c) => c.email.toLowerCase() == email.toLowerCase() && c.tipo == tipo,
    );
    if (emailDuplicado) return 'Já existe uma conta com este e-mail.';

    if (tipo == TipoUsuario.cidadao && cpf != null) {
      final cpfLimpo = cpf.replaceAll(RegExp(r'\D'), '');
      final cpfDuplicado = _contas.any(
        (c) =>
            c.tipo == TipoUsuario.cidadao &&
            (c.cpf ?? '').replaceAll(RegExp(r'\D'), '') == cpfLimpo,
      );
      if (cpfDuplicado) return 'Já existe uma conta com este CPF.';
    }

    if (tipo == TipoUsuario.orgao && cnpj != null) {
      final cnpjLimpo = cnpj.replaceAll(RegExp(r'\D'), '');
      final cnpjDuplicado = _contas.any(
        (c) =>
            c.tipo == TipoUsuario.orgao &&
            (c.cnpj ?? '').replaceAll(RegExp(r'\D'), '') == cnpjLimpo,
      );
      if (cnpjDuplicado) return 'Já existe uma conta com este CNPJ.';
    }


    final conta = _Conta(
      id: 'u-${DateTime.now().millisecondsSinceEpoch}',
      nome: tipo == TipoUsuario.orgao ? (orgaoNome ?? nome) : nome,
      email: email,
      senha: senha,
      tipo: tipo,
      cnpj: cnpj,
      cpf: cpf,
    );
    _contas.add(conta);
    _usuarioAtual = Usuario(
      id: conta.id,
      nome: conta.nome,
      email: conta.email,
      senha: conta.senha,
      tipo: conta.tipo,
      cnpj: conta.cnpj,
      cpf: conta.cpf,
    );
    notifyListeners();
    return null;
  }

  void logout() {
    _usuarioAtual = null;
    notifyListeners();
  }


  void atualizarPerfil() => notifyListeners();
}

class _Conta {
  final String id;
  final String nome;
  final String email;
  final String senha;
  final TipoUsuario tipo;
  final String? cnpj;
  final String? cpf;

  _Conta({
    required this.id,
    required this.nome,
    required this.email,
    required this.senha,
    required this.tipo,
    this.cnpj,
    this.cpf,
  });
}
