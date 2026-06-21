import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/usuario.dart';
import '../models/tipo_usuario.dart';
import 'package:firebase_auth/firebase_auth.dart';


const _kUserId    = 'session_user_id';
const _kUserTipo  = 'session_user_tipo';

enum LoginResultado {
  sucesso,
  usuarioNaoEncontrado,
  senhaIncorreta,
  cnpjIncorreto,
  erro,
}

class AuthService extends ChangeNotifier {
  AuthService() {
    _restaurarSessao();
  }

  Usuario? _usuarioAtual;
  bool _carregandoSessao = true;

  Usuario? get usuarioAtual    => _usuarioAtual;
  bool     get autenticado     => _usuarioAtual != null;
  bool     get logado          => autenticado;
  bool     get carregandoSessao => _carregandoSessao;

  bool get isOrgao   => _usuarioAtual?.tipo == TipoUsuario.orgao;
  bool get isCidadao => _usuarioAtual?.tipo == TipoUsuario.cidadao;

  final _db = FirebaseFirestore.instance;


  Future<void> _restaurarSessao() async {
    try {
      final prefs  = await SharedPreferences.getInstance();
      final userId = prefs.getString(_kUserId);
      final tipo   = prefs.getString(_kUserTipo);

      if (userId == null || tipo == null) {
        _carregandoSessao = false;
        notifyListeners();
        return;
      }

      final doc = await _db.collection('usuarios').doc(userId).get();
      if (!doc.exists) {
        await _limparSessao();
        return;
      }

      _usuarioAtual = _docToUsuario(doc);
    } catch (e) {
      if (kDebugMode) print('[AuthService] Erro ao restaurar sessão: $e');
    } finally {
      _carregandoSessao = false;
      notifyListeners();
    }
  }

  Future<LoginResultado> login({
    required String email,
    required String senha,
    required TipoUsuario tipoEsperado,
    String? cnpj,
  }) async {
    if (email.isEmpty || senha.length < 8) return LoginResultado.erro;

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.toLowerCase().trim(),
        password: senha,
      );

      final snap = await _db
          .collection('usuarios')
          .where('email', isEqualTo: email.toLowerCase().trim())
          .where('tipo', isEqualTo: tipoEsperado.name)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) {
        await FirebaseAuth.instance.signOut();
        return LoginResultado.usuarioNaoEncontrado;
      }

      final doc   = snap.docs.first;
      final dados = doc.data();

      if (dados['senha'] != senha) {
        await FirebaseAuth.instance.signOut();
        return LoginResultado.senhaIncorreta;
      }

      if (tipoEsperado == TipoUsuario.orgao) {
        if (cnpj == null || cnpj.trim().isEmpty) {
          await FirebaseAuth.instance.signOut();
          return LoginResultado.cnpjIncorreto;
        }
        final informado   = cnpj.replaceAll(RegExp(r'\D'), '');
        final cadastrado  = (dados['cnpj'] ?? '').toString().replaceAll(RegExp(r'\D'), '');
        if (informado != cadastrado) {
          await FirebaseAuth.instance.signOut();
          return LoginResultado.cnpjIncorreto;
        }
      }

      _usuarioAtual = _docToUsuario(doc);

      // Persiste sessão localmente
      await _salvarSessao(_usuarioAtual!);
      notifyListeners();
      return LoginResultado.sucesso;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'invalid-email' || e.code == 'invalid-credential') {
        return LoginResultado.usuarioNaoEncontrado;
      }
      if (e.code == 'wrong-password') return LoginResultado.senhaIncorreta;
      return LoginResultado.erro;
    } catch (e) {
      if (kDebugMode) print('[AuthService] Erro no login: $e');
      return LoginResultado.erro;
    }
  }

  Future<String?> cadastrar({
    required String nome,
    required String email,
    required String senha,
    required TipoUsuario tipo,
    String? orgaoNome,
    String? cnpj,
    String? cpf,
    String? telefone,
  }) async {
    if (nome.trim().isEmpty) return 'Informe o nome.';
    if (!email.contains('@') || !email.contains('.')) return 'E-mail inválido.';
    if (senha.length < 8) return 'Senha precisa ter ao menos 8 caracteres.';

    if (tipo == TipoUsuario.orgao) {
      if (orgaoNome == null || orgaoNome.trim().isEmpty) return 'Informe o nome do órgão.';
      final cnpjLimpo = (cnpj ?? '').replaceAll(RegExp(r'\D'), '');
      if (cnpjLimpo.length != 14) return 'CNPJ inválido (14 dígitos).';
    }

    if (tipo == TipoUsuario.cidadao) {
      final cpfLimpo = (cpf ?? '').replaceAll(RegExp(r'\D'), '');
      if (cpfLimpo.isNotEmpty && cpfLimpo.length != 11) {
        return 'CPF inválido (11 dígitos) — ou deixe em branco.';
      }

      final foneLimpo = (telefone ?? '').replaceAll(RegExp(r'\D'), '');
      if (foneLimpo.length < 10 || foneLimpo.length > 11) {
        return 'Telefone inválido. Informe DDD + número.';
      }
    }

    try {
      // Verifica e-mail duplicado
      final emailSnap = await _db
          .collection('usuarios')
          .where('email', isEqualTo: email.toLowerCase().trim())
          .where('tipo', isEqualTo: tipo.name)
          .limit(1)
          .get();
      if (emailSnap.docs.isNotEmpty) return 'Já existe uma conta com este e-mail.';

      // Verifica CPF duplicado
      if (tipo == TipoUsuario.cidadao &&
          cpf != null &&
          cpf.replaceAll(RegExp(r'\D'), '').isNotEmpty) {
        final cpfLimpo = cpf.replaceAll(RegExp(r'\D'), '');
        final cpfSnap  = await _db
            .collection('usuarios')
            .where('tipo', isEqualTo: tipo.name)
            .where('cpf', isEqualTo: cpfLimpo)
            .limit(1)
            .get();
        if (cpfSnap.docs.isNotEmpty) return 'Já existe uma conta com este CPF.';
      }

      // Verifica CNPJ duplicado
      if (tipo == TipoUsuario.orgao && cnpj != null) {
        final cnpjLimpo = cnpj.replaceAll(RegExp(r'\D'), '');
        final cnpjSnap  = await _db
            .collection('usuarios')
            .where('tipo', isEqualTo: tipo.name)
            .where('cnpj', isEqualTo: cnpjLimpo)
            .limit(1)
            .get();
        if (cnpjSnap.docs.isNotEmpty) return 'Já existe uma conta com este CNPJ.';
      }

      final credenciais = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.toLowerCase().trim(),
        password: senha,
      );

      final userAuth = credenciais.user;
      if (userAuth == null) return 'Erro ao criar credenciais de autenticação.';

      final ref = _db.collection('usuarios').doc(userAuth.uid);
      final foneLimpo = (telefone ?? '').replaceAll(RegExp(r'\D'), '');
      final cpfLimpoFinal = (cpf ?? '').replaceAll(RegExp(r'\D'), '');

      await ref.set({
        'nome':      tipo == TipoUsuario.orgao ? (orgaoNome ?? nome) : nome,
        'email':     email.toLowerCase().trim(),
        'senha':     senha,
        'tipo':      tipo.name,
        if (tipo == TipoUsuario.orgao) 'orgaoNome': orgaoNome?.trim(),
        if (tipo == TipoUsuario.orgao && cnpj != null)
          'cnpj': cnpj.replaceAll(RegExp(r'\D'), ''),
        if (tipo == TipoUsuario.cidadao && cpfLimpoFinal.isNotEmpty)
          'cpf': cpfLimpoFinal,
        if (tipo == TipoUsuario.cidadao && foneLimpo.isNotEmpty)
          'telefone': foneLimpo,
        'criadoEm': FieldValue.serverTimestamp(),
      });

      _usuarioAtual = Usuario(
        id:        userAuth.uid,
        nome:      tipo == TipoUsuario.orgao ? (orgaoNome ?? nome) : nome,
        email:     email.toLowerCase().trim(),
        senha:     senha,
        tipo:      tipo,
        cnpj:      tipo == TipoUsuario.orgao ? cnpj?.replaceAll(RegExp(r'\D'), '') : null,
        cpf:       tipo == TipoUsuario.cidadao && cpfLimpoFinal.isNotEmpty ? cpfLimpoFinal : null,
        telefone:  tipo == TipoUsuario.cidadao ? foneLimpo : null,
      );

      await _salvarSessao(_usuarioAtual!);
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') return 'Este e-mail já está em uso na autenticação.';
      if (e.code == 'weak-password') return 'A senha informada é muito fraca.';
      return 'Erro no Firebase Auth: ${e.message}';
    } catch (e) {
      if (kDebugMode) print('[AuthService] Erro no cadastro: $e');
      return 'Erro ao criar conta. Tente novamente.';
    }
  }


  Future<String?> atualizarPerfil({
    required String nome,
    required String email,
    String? telefone,
    String? cpf,
    String? cnpj,
    String? novaSenha,
  }) async {
    final u = _usuarioAtual;
    if (u == null) return 'Sessão expirada.';

    try {
      final updates = <String, dynamic>{
        'nome':  nome.trim(),
        'email': email.toLowerCase().trim(),
        if (telefone != null && telefone.isNotEmpty)
          'telefone': telefone.replaceAll(RegExp(r'\D'), ''),
        if (cpf != null && cpf.isNotEmpty)
          'cpf': cpf.replaceAll(RegExp(r'\D'), ''),
        if (cnpj != null && cnpj.isNotEmpty)
          'cnpj': cnpj.replaceAll(RegExp(r'\D'), ''),
        if (novaSenha != null && novaSenha.isNotEmpty)
          'senha': novaSenha,
        'atualizadoEm': FieldValue.serverTimestamp(),
      };

      await _db.collection('usuarios').doc(u.id).update(updates);

      u.nome  = nome.trim();
      u.email = email.toLowerCase().trim();
      if (novaSenha != null && novaSenha.isNotEmpty) u.senha = novaSenha;
      if (telefone != null) u.telefone = telefone.replaceAll(RegExp(r'\D'), '');
      if (cpf != null) u.cpf = cpf.replaceAll(RegExp(r'\D'), '');
      if (cnpj != null) u.cnpj = cnpj.replaceAll(RegExp(r'\D'), '');

      notifyListeners();
      return null;
    } catch (e) {
      if (kDebugMode) print('[AuthService] Erro ao atualizar perfil: $e');
      return 'Erro ao salvar alterações.';
    }
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    await _limparSessao();
    _usuarioAtual = null;
    notifyListeners();
  }

  Future<String?> deletarConta() async {
    final u = _usuarioAtual;
    final userAuth = FirebaseAuth.instance.currentUser;

    if (u == null) return 'Sessão expirada ou usuário não localizado.';

    try {
      await _db.collection('usuarios').doc(u.id).delete();

      if (userAuth != null) {
        await userAuth.delete();
      }

      await _limparSessao();
      _usuarioAtual = null;
      notifyListeners();

    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        return 'Por segurança, faça Logout, realize o login novamente e tente excluir a conta em seguida.';
      }
      return 'Erro ao remover autenticação: ${e.message}';
    } catch (e) {
      if (kDebugMode) print('[AuthService] Erro ao deletar conta: $e');
      return 'Erro inesperado ao excluir seus dados do banco.';
    }
  }

  Future<void> _salvarSessao(Usuario u) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUserId,   u.id);
    await prefs.setString(_kUserTipo, u.tipo.name);
  }

  Future<void> _limparSessao() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kUserId);
    await prefs.remove(_kUserTipo);
  }


  static Usuario _docToUsuario(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    final tipo = d['tipo'] == 'orgao' ? TipoUsuario.orgao : TipoUsuario.cidadao;
    return Usuario(
      id:       doc.id,
      nome:     d['orgaoNome'] ?? d['nome'] ?? '',
      email:    d['email']  ?? '',
      senha:    d['senha']  ?? '',
      tipo:     tipo,
      cnpj:     d['cnpj']      as String?,
      cpf:      d['cpf']       as String?,
      telefone: d['telefone']  as String?,
    );
  }
}


