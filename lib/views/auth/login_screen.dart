import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/tipo_usuario.dart';
import '../../services/auth_service.dart';
import '../router_screen.dart';

class LoginScreen extends StatefulWidget {
  final TipoUsuario tipo;
  const LoginScreen({super.key, required this.tipo});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _senha = TextEditingController();
  bool _carregando = false;

  bool get _isOrgao => widget.tipo == TipoUsuario.orgao;

  @override
  Widget build(BuildContext context) {
    final cor = _isOrgao ? Colors.green.shade700 : Colors.blue.shade700;
    return Scaffold(
      appBar: AppBar(
        title: Text(_isOrgao ? 'Login do Órgão' : 'Login do Cidadão'),
        backgroundColor: cor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Icon(_isOrgao ? Icons.verified_user : Icons.person,
                  size: 64, color: cor),
              const SizedBox(height: 24),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'E-mail',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || !v.contains('@')) ? 'E-mail inválido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _senha,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Senha',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.length < 8)
                    ? 'Mínimo de 8 caracteres'
                    : null,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
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
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _entrar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _carregando = true);
    final ok = await context.read<AuthService>().login(
          email: _email.text.trim(),
          senha: _senha.text,
          tipoEsperado: widget.tipo,
        );
    setState(() => _carregando = false);
    if (!mounted) return;
    if (ok) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const RouterScreen()),
            (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Falha no login.')),
      );
    }
  }
}
