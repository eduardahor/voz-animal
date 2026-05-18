import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';

class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Puxa o serviço de autenticação para pegarmos os dados do usuário logado
    final auth = Provider.of<AuthService>(context);
    final usuario = auth.usuarioAtual;

    // Tela de carregamento caso os dados ainda estejam chegando do Firebase
    if (usuario == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isOrgao = auth.isOrgao;
    final cor = isOrgao ? Colors.green.shade700 : Colors.blue.shade700;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Perfil'),
        backgroundColor: cor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Ícone do Perfil
            CircleAvatar(
              radius: 50,
              backgroundColor: isOrgao ? Colors.green.shade100 : Colors.blue.shade100,
              child: Icon(
                isOrgao ? Icons.account_balance : Icons.person,
                size: 50,
                color: cor,
              ),
            ),
            const SizedBox(height: 24),
            
            // Card com as informações do Banco de Dados
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.badge_outlined, color: cor),
                      title: const Text('Nome'),
                      subtitle: Text(usuario.nome, style: const TextStyle(fontSize: 16)),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(Icons.email_outlined, color: cor),
                      title: const Text('E-mail'),
                      subtitle: Text(usuario.email, style: const TextStyle(fontSize: 16)),
                    ),
                    
                    // Mostra o CNPJ apenas se for um Órgão
                    if (isOrgao && usuario.cnpj != null && usuario.cnpj!.isNotEmpty) ...[
                      const Divider(height: 1),
                      ListTile(
                        leading: Icon(Icons.numbers, color: cor),
                        title: const Text('CNPJ'),
                        subtitle: Text(usuario.cnpj!, style: const TextStyle(fontSize: 16)),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Botão de Sair da Conta
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.exit_to_app),
                label: const Text('Sair da Conta', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                onPressed: () async {
                  // Desloga do Firebase e volta para a tela inicial!
                  await auth.logout();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}