import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/tipo_usuario.dart';
import '../../services/auth_service.dart';


class _CpfInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue old, TextEditingValue nv) {
    final d = nv.text.replaceAll(RegExp(r'\D'), '');
    final b = StringBuffer();
    for (var i = 0; i < d.length && i < 11; i++) {
      if (i == 3 || i == 6) b.write('.');
      if (i == 9) b.write('-');
      b.write(d[i]);
    }
    final t = b.toString();
    return TextEditingValue(text: t, selection: TextSelection.collapsed(offset: t.length));
  }
}

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

class _TelefoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue old, TextEditingValue nv) {
    final d = nv.text.replaceAll(RegExp(r'\D'), '');
    final b = StringBuffer();
    for (var i = 0; i < d.length && i < 11; i++) {
      if (i == 0) b.write('(');
      if (i == 2) b.write(') ');
      if (d.length == 11 && i == 7) b.write('-');
      if (d.length <= 10 && i == 6) b.write('-');
      b.write(d[i]);
    }
    final t = b.toString();
    return TextEditingValue(text: t, selection: TextSelection.collapsed(offset: t.length));
  }
}


class CadastroScreen extends StatefulWidget {
  final TipoUsuario tipo;
  const CadastroScreen({super.key, required this.tipo});

  @override
  State<CadastroScreen> createState() => _CadastroScreenState();
}

class _CadastroScreenState extends State<CadastroScreen> {
  final _formKey         = GlobalKey<FormState>();
  final _nome            = TextEditingController();
  final _email           = TextEditingController();
  final _senha           = TextEditingController();
  final _confirmaSenha   = TextEditingController();
  final _orgao           = TextEditingController();
  final _cnpj            = TextEditingController();
  final _cpf             = TextEditingController();
  final _telefone        = TextEditingController();

  bool _senhaVisivel         = false;
  bool _confirmaSenhaVisivel = false;
  bool _carregando           = false;

  Color get _cor => widget.tipo == TipoUsuario.cidadao
      ? Colors.blue.shade700
      : Colors.green.shade700;

  bool get _isOrgao => widget.tipo == TipoUsuario.orgao;

  @override
  void dispose() {
    _nome.dispose();
    _email.dispose();
    _senha.dispose();
    _confirmaSenha.dispose();
    _orgao.dispose();
    _cnpj.dispose();
    _cpf.dispose();
    _telefone.dispose();
    super.dispose();
  }

  Future<void> _cadastrar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _carregando = true);

    final erro = await context.read<AuthService>().cadastrar(
          nome:      _nome.text.trim(),
          email:     _email.text.trim(),
          senha:     _senha.text,
          tipo:      widget.tipo,
          orgaoNome: _isOrgao  ? _orgao.text.trim() : null,
          cnpj:      _isOrgao  ? _cnpj.text.trim()  : null,
          cpf:       !_isOrgao ? _cpf.text.trim()    : null,
          telefone:  !_isOrgao ? _telefone.text.trim() : null, // ← NOVO
        );

    if (!mounted) return;
    setState(() => _carregando = false);

    if (erro != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(erro)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cadastro realizado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.popUntil(context, (r) => r.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isOrgao ? 'Cadastro do Órgão' : 'Cadastro do Cidadão'),
        backgroundColor: _cor,
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
                Icon(
                  _isOrgao ? Icons.verified_user : Icons.person_add,
                  size: 64,
                  color: _cor,
                ),
                const SizedBox(height: 12),
                Text(
                  _isOrgao ? 'Novo Órgão Responsável' : 'Nova Conta de Cidadão',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _cor,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Preencha os dados abaixo para criar sua conta.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54, fontSize: 14),
                ),
                const SizedBox(height: 28),

                TextFormField(
                  controller: _nome,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nome completo',
                    prefixIcon: Icon(Icons.badge_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Informe o nome' : null,
                ),
                const SizedBox(height: 16),

                if (!_isOrgao) ...[
                  TextFormField(
                    controller: _cpf,
                    keyboardType: TextInputType.number,
                    inputFormatters: [_CpfInputFormatter()],
                    decoration: const InputDecoration(
                      labelText: 'CPF',
                      hintText: '000.000.000-00',
                      prefixIcon: Icon(Icons.badge_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      final d = (v ?? '').replaceAll(RegExp(r'\D'), '');
                      return d.length != 11 ? 'CPF inválido (11 dígitos)' : null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _telefone,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [_TelefoneInputFormatter()],
                    decoration: const InputDecoration(
                      labelText: 'Telefone / WhatsApp *',
                      hintText: '(00) 00000-0000',
                      prefixIcon: Icon(Icons.phone_outlined),
                      border: OutlineInputBorder(),
                      helperText:
                          'Usado para contato sobre suas denúncias',
                    ),
                    validator: (v) {
                      final d = (v ?? '').replaceAll(RegExp(r'\D'), '');
                      if (d.length < 10 || d.length > 11) {
                        return 'Informe um telefone válido com DDD';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                if (_isOrgao) ...[
                  TextFormField(
                    controller: _orgao,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Nome do órgão',
                      prefixIcon: Icon(Icons.business_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Informe o nome do órgão'
                        : null,
                  ),
                  const SizedBox(height: 16),
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

                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'E-mail',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      (v == null || !v.contains('@') || !v.contains('.'))
                          ? 'E-mail inválido'
                          : null,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _senha,
                  obscureText: !_senhaVisivel,
                  decoration: InputDecoration(
                    labelText: 'Senha',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(_senhaVisivel
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () =>
                          setState(() => _senhaVisivel = !_senhaVisivel),
                    ),
                  ),
                  validator: (v) => (v == null || v.length < 8)
                      ? 'Mínimo de 8 caracteres'
                      : null,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _confirmaSenha,
                  obscureText: !_confirmaSenhaVisivel,
                  decoration: InputDecoration(
                    labelText: 'Confirmar senha',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(_confirmaSenhaVisivel
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () => setState(
                          () => _confirmaSenhaVisivel = !_confirmaSenhaVisivel),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Confirme sua senha';
                    if (v != _senha.text) return 'As senhas não coincidem';
                    return null;
                  },
                ),
                const SizedBox(height: 28),

                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _cor,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _carregando ? null : _cadastrar,
                    child: _carregando
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'CRIAR CONTA',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Já tem uma conta? ',
                        style: TextStyle(color: Colors.black54)),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Text(
                        'Fazer login',
                        style: TextStyle(
                          color: _cor,
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
