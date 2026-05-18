import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/tipo_usuario.dart';
import '../../services/auth_service.dart';
import '../router_screen.dart';
import 'cadastro_screen.dart';

class _CnpjInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buf = StringBuffer();
    for (var i = 0; i < digits.length && i < 14; i++) {
      if (i == 2 || i == 5) buf.write('.');
      if (i == 8) buf.write('/');
      if (i == 12) buf.write('-');
      buf.write(digits[i]);
    }
    final text = buf.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
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
  final _email = TextEditingController();
  final _cnpj = TextEditingController();
  final _senha = TextEditingController();

  bool _senhaVisivel = false;
  bool _carregando = false;

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
    
    final ok = await context.read<AuthService>().login(
          email: _email.text.trim(),
          senha: _senha.text,
          tipoEsperado: widget.tipo,
        );
        
    if (!mounted) return;
    setState(() => _carregando = false);
    
    if (ok) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const RouterScreen()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isOrgao
              ? 'E-mail, CNPJ ou senha incorretos.'
              : 'E-mail ou senha incorretos.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cor = _isOrgao ? Colors.green.shade700 : Colors.blue.shade700;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_isOrgao ? 'Login do Órgão' : 'Login do Cidadão'),
        backgroundColor: cor,
        foregroundColor: Colors.white,
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

                // E-mail (ambos)
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
                    if (!v.contains('@') || !v.contains('.')) {
                      return 'E-mail inválido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // CNPJ (apenas órgão) - Apenas visual/segurança extra na tela
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
                      final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
                      if (digits.length != 14) return 'CNPJ inválido (14 dígitos)';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                // Senha (ambos)
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
                  validator: (v) => (v == null || v.length < 6)
                      ? 'Mínimo de 6 caracteres'
                      : null,
                ),
                const SizedBox(height: 28),

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
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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