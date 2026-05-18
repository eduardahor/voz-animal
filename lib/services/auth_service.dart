import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/usuario.dart';
import '../models/tipo_usuario.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Usuario? _usuarioAtual;
  Usuario? get usuarioAtual => _usuarioAtual;

  bool get logado => _usuarioAtual != null;
  bool get isOrgao => _usuarioAtual?.tipo == TipoUsuario.orgao.name;

  AuthService() {
    _verificarSessaoAtual();
  }

  Future<void> _verificarSessaoAtual() async {
    try {
      User? firebaseUser = _auth.currentUser;
      
      if (firebaseUser != null) {
        final doc = await _db.collection('usuarios').doc(firebaseUser.uid).get();
        
        if (doc.exists) {
          _usuarioAtual = Usuario.fromMap(doc.data()!);
          notifyListeners();
        } else {
          print("Usuário fantasma detectado no cache. Forçando logout...");
          await logout();
        }
      }
    } catch (e) {
      print("Erro ao verificar sessão no fundo: ${e.toString()}");
      await logout(); 
    }
  }

  Future<bool> login({
    required String email,
    required String senha,
    required TipoUsuario tipoEsperado,
  }) async {
    if (email.isEmpty || senha.length < 8) return false;

    try {
      UserCredential resultado = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: senha,
      );

      if (resultado.user != null) {
        final doc = await _db.collection('usuarios').doc(resultado.user!.uid).get();
        if (doc.exists) {
          final usuarioCarregado = Usuario.fromMap(doc.data()!);
          if (usuarioCarregado.tipo == tipoEsperado.name) {
            _usuarioAtual = usuarioCarregado;
            notifyListeners();
            return true;
          }
        }
      }
      
      await logout();
      return false;
    } catch (e) {
      print("Login falhou. Erro interceptado com segurança: ${e.toString()}");
      return false;
    }
  }

  Future<String?> cadastrar({
    required String nome,
    required String email,
    required String senha,
    required TipoUsuario tipo,
    String? orgaoNome,
    String? cnpj,
  }) async {
    if (nome.trim().isEmpty) return 'Informe o nome.';
    if (!email.contains('@')) return 'E-mail inválido.';
    if (senha.length < 8) return 'Senha precisa ter ao menos 8 caracteres.';
    if (tipo == TipoUsuario.orgao && (orgaoNome == null || orgaoNome.trim().isEmpty)) {
      return 'Informe o nome do órgão.';
    }

    try {
      UserCredential resultado = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: senha,
      );

      if (resultado.user != null) {
        final novoUsuario = Usuario(
          id: resultado.user!.uid,
          nome: tipo == TipoUsuario.orgao ? (orgaoNome ?? nome) : nome,
          email: email.trim(),
          senha: '', 
          tipo: tipo.name,
          cnpj: cnpj,
          orgaoNome: orgaoNome,
        );

        await _db.collection('usuarios')
            .doc(novoUsuario.id)
            .set(novoUsuario.toMap());

        _usuarioAtual = novoUsuario;
        notifyListeners();
        return null; 
      }
      return 'Não foi possível criar a conta.';
    } catch (e) {
      String erroText = e.toString();
      
      if (erroText.contains('email-already-in-use')) {
        return 'Já existe uma conta com este e-mail.';
      } else if (erroText.contains('weak-password')) {
        return 'A senha digitada é muito fraca.';
      } else if (erroText.contains('invalid-email')) {
        return 'Formato de e-mail inválido.';
      }
      
      return 'Erro ao tentar cadastrar. Tente novamente.';
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    _usuarioAtual = null;
    notifyListeners();
  }
}