import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class CadastroScreen extends StatefulWidget {
  const CadastroScreen({super.key});
  @override
  State<CadastroScreen> createState() => _CadastroScreenState();
}

class _CadastroScreenState extends State<CadastroScreen> {
  final _nomeCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  void _registrar() {
    if (!_formKey.currentState!.validate()) return;
    final ok = context.read<AuthService>().registrar(
      nome: _nomeCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      senha: _senhaCtrl.text,
    );
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Conta criada! Faça login.'), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('E-mail já cadastrado'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cadastro')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(children: [
            TextFormField(
              controller: _nomeCtrl,
              decoration: const InputDecoration(labelText: 'Nome completo', prefixIcon: Icon(Icons.person), border: OutlineInputBorder()),
              validator: (v) => v != null && v.length >= 3 ? null : 'Mínimo 3 caracteres',
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailCtrl,
              decoration: const InputDecoration(labelText: 'E-mail', prefixIcon: Icon(Icons.email), border: OutlineInputBorder()),
              validator: (v) => v != null && v.contains('@') ? null : 'E-mail inválido',
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _senhaCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Senha', prefixIcon: Icon(Icons.lock), border: OutlineInputBorder()),
              validator: (v) => v != null && v.length >= 6 ? null : 'Mínimo 6 caracteres',
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity, height: 48,
              child: FilledButton(onPressed: _registrar, child: const Text('Criar Conta')),
            ),
          ]),
        ),
      ),
    );
  }
}
