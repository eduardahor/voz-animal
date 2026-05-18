import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/tipo_usuario.dart';
import '../../services/auth_service.dart';

class CadastroScreen extends StatefulWidget {
  final TipoUsuario tipo;

  const CadastroScreen({super.key, required this.tipo});

  @override
  State<CadastroScreen> createState() => _CadastroScreenState();
}

class _CadastroScreenState extends State<CadastroScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _email = TextEditingController();
  final _senha = TextEditingController();
  final _orgao = TextEditingController();
  final _cnpj = TextEditingController();

  bool _carregando = false;

  @override
  void dispose() {
    _nome.dispose();
    _email.dispose();
    _senha.dispose();
    _orgao.dispose();
    _cnpj.dispose();
    super.dispose();
  }

  Future<void> _cadastrar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _carregando = true);

    final auth = Provider.of<AuthService>(context, listen: false);
    final isOrgao = widget.tipo == TipoUsuario.orgao;

    final erro = await auth.cadastrar(
      nome: _nome.text.trim(),
      email: _email.text.trim(),
      senha: _senha.text,
      tipo: widget.tipo,
      orgaoNome: isOrgao ? _orgao.text.trim() : null,
      cnpj: isOrgao ? _cnpj.text.trim() : null,
    );

    if (!mounted) return;

    setState(() => _carregando = false);

    if (erro != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(erro), 
          backgroundColor: Colors.red,
        ),
      );
    } else {
      // Cadastro feito com sucesso! Retorna para o início.
      Navigator.popUntil(context, (route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOrgao = widget.tipo == TipoUsuario.orgao;

    return Scaffold(
      appBar: AppBar(
        title: Text(isOrgao ? 'Cadastro de Órgão' : 'Cadastro de Cidadão'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nome,
                  decoration: InputDecoration(
                    labelText: isOrgao ? 'Nome do Responsável' : 'Nome Completo',
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Informe o nome' : null,
                ),
                const SizedBox(height: 16),
                
                // Campos exclusivos para Órgão
                if (isOrgao) ...[
                  TextFormField(
                    controller: _orgao,
                    decoration: const InputDecoration(
                      labelText: 'Nome do Órgão (Ex: ONG Patinhas)',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value == null || value.trim().isEmpty ? 'Informe o órgão' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _cnpj,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'CNPJ (Opcional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'E-mail',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || !value.contains('@')
                      ? 'Informe um e-mail válido'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _senha,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Senha (mínimo 8 caracteres)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.length < 8
                      ? 'A senha deve ter no mínimo 8 caracteres'
                      : null,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _carregando ? null : _cadastrar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: _carregando
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Cadastrar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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