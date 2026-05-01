import 'package:flutter/foundation.dart';
import '../models/usuario.dart';
import '../models/tipo_usuario.dart';

class AuthService extends ChangeNotifier {
  Usuario? _usuarioLogado;
  final List<Usuario> _usuarios = [];

  Usuario? get usuarioLogado => _usuarioLogado;
  bool get estaLogado => _usuarioLogado != null;

  Usuario? get usuarioAtual => _usuarioLogado;

  AuthService() {
    _usuarios.add(Usuario(
      id: 'orgao1',
      nome: 'Fiscal Ambiental',
      email: 'orgao@voz.animal',
      senha: '123456',
      tipo: TipoUsuario.orgao,
      orgaoNome: 'IBAMA',
    ));
  }

  bool login(String email, String senha) {
    try {
      final u = _usuarios.firstWhere(
        (u) => u.email == email && u.autenticar(senha),
      );
      _usuarioLogado = u;
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  bool registrar({
    required String nome,
    required String email,
    required String senha,
    TipoUsuario tipo = TipoUsuario.cidadao,
    String? orgaoNome,
  }) {
    if (_usuarios.any((u) => u.email == email)) return false;
    final novo = Usuario(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      nome: nome,
      email: email,
      senha: senha,
      tipo: tipo,
      orgaoNome: orgaoNome,
    );
    _usuarios.add(novo);
    _usuarioLogado = novo;
    notifyListeners();
    return true;
  }

  void logout() {
    _usuarioLogado = null;
    notifyListeners();
  }
}
