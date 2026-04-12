import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/usuario.dart';

/// Serviço de autenticação — gerencia login, cadastro e sessão.
/// Separação de responsabilidades (Service layer).
class AuthService extends ChangeNotifier {
  Usuario? _usuarioLogado;
  final List<Usuario> _usuarios = [];
  final _uuid = const Uuid();

  Usuario? get usuarioLogado => _usuarioLogado;
  bool get isAutenticado => _usuarioLogado != null;

  /// Cadastra um novo usuário
  Future<bool> cadastrar({
    required String nome,
    required String email,
    required String senha,
    String telefone = '',
  }) async {
    // Simula delay de rede
    await Future.delayed(const Duration(milliseconds: 800));

    // Verifica se email já existe
    final existente = _usuarios.any((u) => u.email == email);
    if (existente) return false;

    final usuario = Usuario(
      id: _uuid.v4(),
      nome: nome,
      email: email,
      senha: senha,
      telefone: telefone,
    );

    _usuarios.add(usuario);
    _usuarioLogado = usuario;
    notifyListeners();
    return true;
  }

  /// Realiza login
  Future<bool> login({
    required String email,
    required String senha,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));

    try {
      final usuario = _usuarios.firstWhere(
        (u) => u.email == email && u.validarSenha(senha),
      );
      _usuarioLogado = usuario;
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Realiza logout
  void logout() {
    _usuarioLogado = null;
    notifyListeners();
  }
}
