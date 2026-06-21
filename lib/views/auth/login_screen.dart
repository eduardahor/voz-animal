import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/tipo_usuario.dart';
import '../../services/auth_service.dart';
import '../router_screen.dart';
import '../shared/font_size_controls.dart';
import 'cadastro_screen.dart';

class _CnpjInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue old, TextEditingValue nv) {
    final d = nv.text.replaceAll(RegExp(r'\D'), '');
    final b = StringBuffer();
    for (var i = 0; i < d.length && i < 14; i++) {
      if (i == 2 || i == 5) b.write('.');
      if (i == 8) b.write('/');
      if (i == 12) b.write('-');
      b.write(d[i]);
    }
    final t = b.toString();
    return TextEditingValue(text: t, selection: TextSelection.collapsed(offset: t.length));
  }
}

class LoginScreen extends StatefulWidget {
  final TipoUsuario tipo;
  const LoginScreen({super.key, required this.tipo});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email   = TextEditingController();
  final _cnpj    = TextEditingController();
  final _senha   = TextEditingController();

  bool _senhaVisivel = false;
  bool _carregando   = false;

  bool get _isOrgao => widget.tipo == TipoUsuario.orgao;

  @override
  void dispose() {
    _email.dispose();
    _cnpj.dispose();
    _senha.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _carregando = true);

    final resultado = await context.read<AuthService>().login(
          email:        _email.text.trim(),
          senha:        _senha.text,
          tipoEsperado: widget.tipo,
          cnpj:         _isOrgao ? _cnpj.text.trim() : null,
        );

    if (!mounted) return;
    setState(() => _carregando = false);

    if (resultado == LoginResultado.sucesso) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const RouterScreen()),
        (_) => false,
      );
      return;
    }

    final msg = switch (resultado) {
      LoginResultado.usuarioNaoEncontrado =>
      'E-mail ou senha incorretos.',
      LoginResultado.senhaIncorreta =>
      'E-mail ou senha incorretos.',
      LoginResultado.cnpjIncorreto =>
      'CNPJ não corresponde ao cadastro deste e-mail.',
      _ => 'Erro ao fazer login. Tente novamente.',
    };

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cor = _isOrgao ? Colors.green.shade700 : Colors.blue.shade700;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isOrgao ? 'Login do Órgão' : 'Login do Cidadão'),
        backgroundColor: cor,
        foregroundColor: Colors.white,
        actions: const [FontSizeControls()],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                Icon(_isOrgao ? Icons.verified_user : Icons.person,
                    size: 64, color: cor),
                const SizedBox(height: 24),

                // E-mail
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'E-mail',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Informe o e-mail';
                    if (!v.contains('@') || !v.contains('.')) return 'E-mail inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // CNPJ
                if (_isOrgao) ...[
                  TextFormField(
                    controller: _cnpj,
                    keyboardType: TextInputType.number,
                    inputFormatters: [_CnpjInputFormatter()],
                    decoration: const InputDecoration(
                      labelText: 'CNPJ',
                      hintText: '00.000.000/0000-00',
                      prefixIcon: Icon(Icons.numbers_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      final d = (v ?? '').replaceAll(RegExp(r'\D'), '');
                      return d.length != 14 ? 'CNPJ inválido (14 dígitos)' : null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                // Senha
                TextFormField(
                  controller: _senha,
                  obscureText: !_senhaVisivel,
                  decoration: InputDecoration(
                    labelText: 'Senha',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _senhaVisivel ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () =>
                          setState(() => _senhaVisivel = !_senhaVisivel),
                    ),
                  ),
                  validator: (v) => (v == null || v.length < 8)
                      ? 'Mínimo de 8 caracteres'
                      : null,
                ),
                const SizedBox(height: 28),

                // Botão entrar
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cor,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _carregando ? null : _entrar,
                    child: _carregando
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('ENTRAR',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Não tem uma conta? ',
                        style: TextStyle(color: Colors.black54)),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CadastroScreen(tipo: widget.tipo),
                        ),
                      ),
                      child: Text(
                        'Cadastre-se',
                        style: TextStyle(
                          color: cor,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
