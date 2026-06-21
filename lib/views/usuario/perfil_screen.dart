import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/tipo_usuario.dart';
import '../../services/auth_service.dart';


class _CpfInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buf = StringBuffer();
    for (var i = 0; i < digits.length && i < 11; i++) {
      if (i == 3 || i == 6) buf.write('.');
      if (i == 9) buf.write('-');
      buf.write(digits[i]);
    }
    final text = buf.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

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

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nome;
  late final TextEditingController _email;
  late final TextEditingController _cnpj;
  late final TextEditingController _cpf;
  late final TextEditingController _telefone;
  final _senhaAtual = TextEditingController();
  final _novaSenha = TextEditingController();
  final _confirmaSenha = TextEditingController();

  bool _senhaAtualVisivel = false;
  bool _novaSenhaVisivel = false;
  bool _confirmaSenhaVisivel = false;
  bool _carregando = false;
  bool _alterarSenha = false;

  @override
  void initState() {
    super.initState();
    final usuario = context.read<AuthService>().usuarioAtual!;
    _nome = TextEditingController(text: usuario.nome);
    _email = TextEditingController(text: usuario.email);
    _cnpj = TextEditingController(text: usuario.cnpj ?? '');
    _cpf = TextEditingController(text: usuario.cpf ?? '');
    _telefone = TextEditingController(text: usuario.telefone ?? '');
  }

  @override
  void dispose() {
    _nome.dispose();
    _email.dispose();
    _cnpj.dispose();
    _cpf.dispose();
    _telefone.dispose();
    _senhaAtual.dispose();
    _novaSenha.dispose();
    _confirmaSenha.dispose();
    super.dispose();
  }

  Color get _cor {
    final tipo = context.read<AuthService>().usuarioAtual?.tipo;
    return tipo == TipoUsuario.orgao
        ? Colors.green.shade700
        : Colors.blue.shade700;
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _carregando = true);

    final auth    = context.read<AuthService>();
    final usuario = auth.usuarioAtual!;

    // Valida senha atual antes de prosseguir
    if (_alterarSenha && _senhaAtual.text != usuario.senha) {
      setState(() => _carregando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Senha atual incorreta.')),
      );
      return;
    }

    final erro = await auth.atualizarPerfil(
      nome:      _nome.text.trim(),
      email:     _email.text.trim(),
      telefone:  usuario.tipo == TipoUsuario.cidadao ? _telefone.text.trim() : null,
      cpf:       usuario.tipo == TipoUsuario.cidadao ? _cpf.text.trim()   : null,
      cnpj:      usuario.tipo == TipoUsuario.orgao   ? _cnpj.text.trim()  : null,
      novaSenha: _alterarSenha && _novaSenha.text.isNotEmpty ? _novaSenha.text : null,
    );

    if (!mounted) return;
    setState(() => _carregando = false);

    if (erro != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(erro), backgroundColor: Colors.red.shade700),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Dados atualizados com sucesso!'),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.pop(context);
  }

  void _confirmarExclusaoDeConta(BuildContext context) {
    showDialog(
      context: context,
      builder: (contextDialog) => AlertDialog(
        title: const Text('Excluir Conta', style: TextStyle(color: Colors.red)),
        content: const Text(
          'Tem certeza que deseja excluir sua conta permanentemente? \n\n'
              'Esta ação não pode ser desfeita e todos os seus dados serão apagados.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(contextDialog),
            child: const Text('Cancelar'),
          ),
          TextButton( // Botão sem borda, apenas texto
            onPressed: () async {
              Navigator.pop(contextDialog);
              setState(() => _carregando = true);

              final erro = await context.read<AuthService>().deletarConta();

              if (!context.mounted) return;
              setState(() => _carregando = false);

              if (erro != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(erro), backgroundColor: Colors.red.shade700, duration: const Duration(seconds: 6)),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sua conta foi excluída com sucesso.'), backgroundColor: Colors.green),
                );
                // A tela de login será chamada automaticamente pelo RouterScreen devido ao notifyListeners()
                Navigator.pop(context);
              }
            },
            child: const Text('Excluir Tudo', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<AuthService>().usuarioAtual!;
    final isOrgao = usuario.tipo == TipoUsuario.orgao;
    final cor = _cor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Perfil'),
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
                Center(
                  child: CircleAvatar(
                    radius: 44,
                    backgroundColor: cor.withValues(alpha: 0.15),
                    child: Icon(
                      isOrgao ? Icons.verified_user : Icons.person,
                      size: 48,
                      color: cor,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    usuario.nome,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                Center(
                  child: Chip(
                    label:
                        Text(isOrgao ? 'Órgão Responsável' : 'Cidadão'),
                    backgroundColor: cor.withValues(alpha: 0.12),
                    labelStyle: TextStyle(color: cor, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 28),

                _SectionHeader(titulo: 'Dados Pessoais', cor: cor),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _nome,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nome completo',
                    prefixIcon: Icon(Icons.badge_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Informe o nome'
                      : null,
                ),
                const SizedBox(height: 16),

                if (!isOrgao) ...[
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
                      final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
                      if (digits.length != 11) return 'CPF inválido (11 dígitos)';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                if (!isOrgao) ...[
                  TextFormField(
                    controller: _telefone,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Telefone / WhatsApp',
                      hintText: '(00) 00000-0000',
                      prefixIcon: Icon(Icons.phone_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      final d = (v ?? '').replaceAll(RegExp(r'\D'), '');
                      if (d.isNotEmpty && (d.length < 10 || d.length > 11)) {
                        return 'Telefone inválido (com DDD)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                if (isOrgao) ...[
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
                      final digits =
                          (v ?? '').replaceAll(RegExp(r'\D'), '');
                      if (digits.length != 14) {
                        return 'CNPJ inválido (14 dígitos)';
                      }
                      return null;
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
                  validator: (v) => (v == null || !v.contains('@'))
                      ? 'E-mail inválido'
                      : null,
                ),
                const SizedBox(height: 24),

                _SectionHeader(titulo: 'Segurança', cor: cor),
                const SizedBox(height: 12),

                SwitchListTile(
                  value: _alterarSenha,
                  onChanged: (val) {
                    setState(() {
                      _alterarSenha = val;
                      if (!val) {
                        _senhaAtual.clear();
                        _novaSenha.clear();
                        _confirmaSenha.clear();
                      }
                    });
                  },
                  title: const Text('Alterar senha'),
                  secondary: Icon(Icons.lock_outline, color: cor),
                  activeThumbColor: cor,
                  contentPadding: EdgeInsets.zero,
                ),

                if (_alterarSenha) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _senhaAtual,
                    obscureText: !_senhaAtualVisivel,
                    decoration: InputDecoration(
                      labelText: 'Senha atual',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(_senhaAtualVisivel
                            ? Icons.visibility_off
                            : Icons.visibility),
                        onPressed: () => setState(() =>
                            _senhaAtualVisivel = !_senhaAtualVisivel),
                      ),
                    ),
                    validator: (v) {
                      if (!_alterarSenha) return null;
                      if (v == null || v.isEmpty) return 'Informe a senha atual';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _novaSenha,
                    obscureText: !_novaSenhaVisivel,
                    decoration: InputDecoration(
                      labelText: 'Nova senha',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(_novaSenhaVisivel
                            ? Icons.visibility_off
                            : Icons.visibility),
                        onPressed: () => setState(
                            () => _novaSenhaVisivel = !_novaSenhaVisivel),
                      ),
                    ),
                    validator: (v) {
                      if (!_alterarSenha) return null;
                      if (v == null || v.length < 8) return 'Mínimo de 8 caracteres';
                      if (v == _senhaAtual.text) return 'A nova senha não pode ser igual a atual';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmaSenha,
                    obscureText: !_confirmaSenhaVisivel,
                    decoration: InputDecoration(
                      labelText: 'Confirmar nova senha',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(_confirmaSenhaVisivel
                            ? Icons.visibility_off
                            : Icons.visibility),
                        onPressed: () => setState(() =>
                            _confirmaSenhaVisivel = !_confirmaSenhaVisivel),
                      ),
                    ),
                    validator: (v) {
                      if (!_alterarSenha) return null;
                      if (v == null || v.isEmpty) return 'Confirme a nova senha';
                      if (v != _novaSenha.text) return 'As senhas não coincidem';
                      return null;
                    },
                  ),
                ],

                const SizedBox(height: 32),

                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cor,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _carregando ? null : _salvar,
                    child: _carregando
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'SALVAR ALTERAÇÕES',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
                const SizedBox(height: 32),

                _SectionHeader(titulo: 'Zona de Perigo', cor: Colors.red.shade700),
                const SizedBox(height: 12),

                TextButton(
                  onPressed: _carregando ? null : () => _confirmarExclusaoDeConta(context),
                  child: Text(
                    'Excluir Minha Conta',
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String titulo;
  final Color cor;
  const _SectionHeader({required this.titulo, required this.cor});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          titulo,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: cor,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Divider(color: cor.withValues(alpha: 0.3))),
      ],
    );
  }
}
