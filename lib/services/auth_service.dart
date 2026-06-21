import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/usuario.dart';
import '../models/tipo_usuario.dart';

enum LoginResultado {
  sucesso,
  usuarioNaoEncontrado,
  senhaIncorreta,
  cnpjIncorreto,
  erro,
}

const _kColecaoCpfs  = 'cpfs_em_uso';
const _kColecaoCnpjs = 'cnpjs_em_uso';

class AuthService extends ChangeNotifier {
  AuthService() {
    _ouvirMudancasDeAutenticacao();
  }

  Usuario? _usuarioAtual;
  bool _carregandoSessao = true;

  Usuario? get usuarioAtual     => _usuarioAtual;
  bool     get autenticado      => _usuarioAtual != null;
  bool     get logado           => autenticado;
  bool     get carregandoSessao => _carregandoSessao;

  bool get isOrgao   => _usuarioAtual?.tipo == TipoUsuario.orgao;
  bool get isCidadao => _usuarioAtual?.tipo == TipoUsuario.cidadao;

  final _db   = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;


  void _ouvirMudancasDeAutenticacao() {
    _auth.authStateChanges().listen((user) async {
      if (user == null) {
        _usuarioAtual = null;
        _carregandoSessao = false;
        notifyListeners();
        return;
      }

      try {
        final doc = await _db.collection('usuarios').doc(user.uid).get();
        if (doc.exists) {
          _usuarioAtual = _docToUsuario(doc);
        } else {
          // (ex.: cadastro interrompido no meio do caminho). Desloga por
          // segurança em vez de deixar o app num estado inconsistente.
          await _auth.signOut();
          _usuarioAtual = null;
        }
      } catch (e) {
        if (kDebugMode) print('[AuthService] Erro ao restaurar sessão: $e');
        _usuarioAtual = null;
      } finally {
        _carregandoSessao = false;
        notifyListeners();
      }
    });
  }

  Future<LoginResultado> login({
    required String email,
    required String senha,
    required TipoUsuario tipoEsperado,
    String? cnpj,
  }) async {
    if (email.isEmpty || senha.length < 8) return LoginResultado.erro;

    try {
      final credenciais = await _auth.signInWithEmailAndPassword(
        email: email.toLowerCase().trim(),
        password: senha,
      );

      final uid = credenciais.user?.uid;
      if (uid == null) return LoginResultado.erro;

      final doc = await _db.collection('usuarios').doc(uid).get();

      if (!doc.exists) {
        await _auth.signOut();
        return LoginResultado.usuarioNaoEncontrado;
      }

      final dados = doc.data()!;

      if (dados['tipo'] != tipoEsperado.name) {
        await _auth.signOut();
        return LoginResultado.usuarioNaoEncontrado;
      }

      if (tipoEsperado == TipoUsuario.orgao) {
        if (cnpj == null || cnpj.trim().isEmpty) {
          await _auth.signOut();
          return LoginResultado.cnpjIncorreto;
        }
        final informado  = cnpj.replaceAll(RegExp(r'\D'), '');
        final cadastrado = (dados['cnpj'] ?? '').toString().replaceAll(RegExp(r'\D'), '');
        if (informado != cadastrado) {
          await _auth.signOut();
          return LoginResultado.cnpjIncorreto;
        }
      }

      _usuarioAtual = _docToUsuario(doc);
      notifyListeners();
      return LoginResultado.sucesso;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' ||
          e.code == 'invalid-email' ||
          e.code == 'invalid-credential') {
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

    String? cnpjLimpo;
    if (tipo == TipoUsuario.orgao) {
      if (orgaoNome == null || orgaoNome.trim().isEmpty) return 'Informe o nome do órgão.';
      cnpjLimpo = (cnpj ?? '').replaceAll(RegExp(r'\D'), '');
      if (cnpjLimpo.length != 14) return 'CNPJ inválido (14 dígitos).';
    }

    String cpfLimpoFinal = '';
    String foneLimpo = '';
    if (tipo == TipoUsuario.cidadao) {
      // CPF é OPCIONAL para o cidadão (ver justificativa LGPD/jurídica:
      // a denúncia em si não exige identificação unívoca; CPF só passa
      // a ter utilidade se o órgão precisar converter em procedimento
      // formal, caso em que o próprio órgão pode solicitar depois).
      cpfLimpoFinal = (cpf ?? '').replaceAll(RegExp(r'\D'), '');
      if (cpfLimpoFinal.isNotEmpty && cpfLimpoFinal.length != 11) {
        return 'CPF inválido (11 dígitos) — ou deixe em branco.';
      }

      foneLimpo = (telefone ?? '').replaceAll(RegExp(r'\D'), '');
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

      if (tipo == TipoUsuario.cidadao && cpfLimpoFinal.isNotEmpty) {
        final jaExiste = await _db.collection(_kColecaoCpfs).doc(cpfLimpoFinal).get();
        if (jaExiste.exists) return 'Já existe uma conta com este CPF.';
      }
      if (tipo == TipoUsuario.orgao && cnpjLimpo != null) {
        final jaExiste = await _db.collection(_kColecaoCnpjs).doc(cnpjLimpo).get();
        if (jaExiste.exists) return 'Já existe uma conta com este CNPJ.';
      }

      final credenciais = await _auth.createUserWithEmailAndPassword(

      final credenciais = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.toLowerCase().trim(),
        password: senha,
      );

      final userAuth = credenciais.user;
      if (userAuth == null) return 'Erro ao criar credenciais de autenticação.';

      final batch = _db.batch();
      final ref = _db.collection('usuarios').doc(userAuth.uid);

      batch.set(ref, {
        'nome':      tipo == TipoUsuario.orgao ? (orgaoNome ?? nome) : nome,
        'email':     email.toLowerCase().trim(),
        'tipo':      tipo.name,
        if (tipo == TipoUsuario.orgao) 'orgaoNome': orgaoNome?.trim(),
        if (tipo == TipoUsuario.orgao && cnpjLimpo != null) 'cnpj': cnpjLimpo,
        if (tipo == TipoUsuario.cidadao && cpfLimpoFinal.isNotEmpty)
          'cpf': cpfLimpoFinal,
        if (tipo == TipoUsuario.cidadao && foneLimpo.isNotEmpty)
          'telefone': foneLimpo,
        'criadoEm': FieldValue.serverTimestamp(),
      });

      if (tipo == TipoUsuario.cidadao && cpfLimpoFinal.isNotEmpty) {
        batch.set(_db.collection(_kColecaoCpfs).doc(cpfLimpoFinal), {
          'criadoEm': FieldValue.serverTimestamp(),
        });
      }
      if (tipo == TipoUsuario.orgao && cnpjLimpo != null) {
        batch.set(_db.collection(_kColecaoCnpjs).doc(cnpjLimpo), {
          'criadoEm': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      _usuarioAtual = Usuario(
        id:       userAuth.uid,
        nome:     tipo == TipoUsuario.orgao ? (orgaoNome ?? nome) : nome,
        email:    email.toLowerCase().trim(),
        tipo:     tipo,
        cnpj:     cnpjLimpo,
        cpf:      cpfLimpoFinal.isNotEmpty ? cpfLimpoFinal : null,
        telefone: tipo == TipoUsuario.cidadao ? foneLimpo : null,
      );

      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') return 'Já existe uma conta com este e-mail.';
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
    String? senhaAtual,
    String? novaSenha,
  }) async {
    final u = _usuarioAtual;
    final userAuth = _auth.currentUser;
    if (u == null || userAuth == null) return 'Sessão expirada.';

    try {
      if (novaSenha != null && novaSenha.isNotEmpty) {
        if (senhaAtual == null || senhaAtual.isEmpty) {
          return 'Informe a senha atual para trocar a senha.';
        }
        final credencial = EmailAuthProvider.credential(
          email: userAuth.email ?? u.email,
          password: senhaAtual,
        );
        await userAuth.reauthenticateWithCredential(credencial);
        await userAuth.updatePassword(novaSenha);
      }

      final cpfLimpo  = cpf?.replaceAll(RegExp(r'\D'), '');
      final cnpjLimpo = cnpj?.replaceAll(RegExp(r'\D'), '');

      final updates = <String, dynamic>{
        'nome':  nome.trim(),
        'email': email.toLowerCase().trim(),
        if (telefone != null && telefone.isNotEmpty)
          'telefone': telefone.replaceAll(RegExp(r'\D'), ''),
        if (cpfLimpo != null && cpfLimpo.isNotEmpty) 'cpf': cpfLimpo,
        if (cnpjLimpo != null && cnpjLimpo.isNotEmpty) 'cnpj': cnpjLimpo,
        'atualizadoEm': FieldValue.serverTimestamp(),
      };

      await _db.collection('usuarios').doc(u.id).update(updates);

      // Mantém os documentos-índice de CPF/CNPJ em sincronia: se o valor
      // mudou, libera o antigo (best-effort) e reserva o novo.
      if (cpfLimpo != null && cpfLimpo.isNotEmpty && cpfLimpo != u.cpf) {
        await _db.collection(_kColecaoCpfs).doc(cpfLimpo)
            .set({'criadoEm': FieldValue.serverTimestamp()});
        if (u.cpf != null && u.cpf!.isNotEmpty) {
          await _db.collection(_kColecaoCpfs).doc(u.cpf).delete();
        }
      }
      if (cnpjLimpo != null && cnpjLimpo.isNotEmpty && cnpjLimpo != u.cnpj) {
        await _db.collection(_kColecaoCnpjs).doc(cnpjLimpo)
            .set({'criadoEm': FieldValue.serverTimestamp()});
        if (u.cnpj != null && u.cnpj!.isNotEmpty) {
          await _db.collection(_kColecaoCnpjs).doc(u.cnpj).delete();
        }
      }

      u.nome  = nome.trim();
      u.email = email.toLowerCase().trim();
      if (telefone != null) u.telefone = telefone.replaceAll(RegExp(r'\D'), '');
      if (cpfLimpo != null) u.cpf = cpfLimpo;
      if (cnpjLimpo != null) u.cnpj = cnpjLimpo;

      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        return 'Senha atual incorreta.';
      }
      if (e.code == 'requires-recent-login') {
        return 'Por segurança, faça login novamente antes de trocar a senha.';
      }
      if (e.code == 'weak-password') return 'A nova senha informada é muito fraca.';
      return 'Erro ao atualizar segurança da conta: ${e.message}';
    } catch (e) {
      if (kDebugMode) print('[AuthService] Erro ao atualizar perfil: $e');
      return 'Erro ao salvar alterações.';
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    // _usuarioAtual é limpo automaticamente pelo listener de
    // authStateChanges() registrado em _ouvirMudancasDeAutenticacao().
  }

  Future<String?> deletarConta() async {
    final u = _usuarioAtual;
    final userAuth = _auth.currentUser;

    if (u == null || userAuth == null) {
      return 'Sessão expirada ou usuário não localizado.';
    }

    try {
      await _db.collection('usuarios').doc(u.id).delete();

      // Libera o CPF/CNPJ reservado por essa conta, senão ninguém mais
      // (nem o próprio dono) conseguiria cadastrar esse valor de novo.
      if (u.cpf != null && u.cpf!.isNotEmpty) {
        await _db.collection(_kColecaoCpfs).doc(u.cpf).delete();
      }
      if (u.cnpj != null && u.cnpj!.isNotEmpty) {
        await _db.collection(_kColecaoCnpjs).doc(u.cnpj).delete();
      }

      await userAuth.delete();
      return null;// sucesso
      
      await _limparSessao();
      _usuarioAtual = null;
      notifyListeners();

      return null;
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

  static Usuario _docToUsuario(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    final tipo = d['tipo'] == 'orgao' ? TipoUsuario.orgao : TipoUsuario.cidadao;
    return Usuario(
      id:       doc.id,
      nome:     d['orgaoNome'] ?? d['nome'] ?? '',
      email:    d['email']  ?? '',
      tipo:     tipo,
      cnpj:     d['cnpj']      as String?,
      cpf:      d['cpf']       as String?,
      telefone: d['telefone']  as String?,
    );
  }
}
