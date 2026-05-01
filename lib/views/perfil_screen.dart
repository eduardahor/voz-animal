import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/denuncia_service.dart';

class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final usuario = auth.usuarioLogado;
    final denunciaService = Provider.of<DenunciaService>(context);
    final totalDenuncias = usuario != null
        ? denunciaService.denunciasPorUsuario(usuario.id).length
        : 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Meu Perfil')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const CircleAvatar(radius: 50, child: Icon(Icons.person, size: 50)),
            const SizedBox(height: 16),
            Text(usuario?.nome ?? 'Usuario',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(usuario?.email ?? '',
                style: TextStyle(fontSize: 16, color: Colors.grey.withValues(alpha: 0.8))),
            const SizedBox(height: 24),
            Card(
              child: ListTile(
                leading: const Icon(Icons.report),
                title: const Text('Minhas Denuncias'),
                trailing: Text('$totalDenuncias'),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                auth.logout();
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
              },
              icon: const Icon(Icons.logout),
              label: const Text('Sair'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
