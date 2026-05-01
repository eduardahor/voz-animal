import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../models/tipo_usuario.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _carregando = false;

  void _login() {
    setState(() => _carregando = true);
    final auth = Provider.of<AuthService>(context, listen: false);
    final ok = auth.login(_emailController.text, _senhaController.text);
    setState(() => _carregando = false);

    if (ok) {
      if (auth.usuarioLogado?.tipo == TipoUsuario.orgao) {
        Navigator.pushReplacementNamed(context, '/orgao_home');
      } else {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email ou senha incorretos')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.pets, size: 80, color: Colors.green),
              const SizedBox(height: 16),
              const Text('Voz Animal', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 32),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _senhaController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Senha', prefixIcon: Icon(Icons.lock)),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _carregando ? null : _login,
                  child: _carregando ? const CircularProgressIndicator() : const Text('Entrar'),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/registro'),
                child: const Text('Criar conta'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
