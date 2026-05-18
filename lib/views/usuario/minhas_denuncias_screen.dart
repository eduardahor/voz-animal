import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/denuncia.dart';
import '../../models/status_denuncia.dart';
import '../../models/tipo_ocorrencia.dart';
import '../../services/auth_service.dart';
import '../../services/denuncia_service.dart';

class MinhasDenunciasScreen extends StatelessWidget {
  const MinhasDenunciasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final usuario = Provider.of<AuthService>(context, listen: false).usuarioAtual!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Denúncias'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      // Usa o StreamBuilder para puxar só as denúncias deste cidadão do Firebase
      body: StreamBuilder<List<Denuncia>>(
        stream: Provider.of<DenunciaService>(context, listen: false).minhasDenuncias(usuario.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final denuncias = snapshot.data ?? [];

          if (denuncias.isEmpty) {
            return const Center(
              child: Text('Você ainda não registrou nenhuma denúncia.', style: TextStyle(fontSize: 16)),
            );
          }

          // Ordena pelas denúncias mais recentes no topo
          denuncias.sort((a, b) => b.criadoEm.compareTo(a.criadoEm));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: denuncias.length,
            itemBuilder: (context, index) {
              final d = denuncias[index];
              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(d.tipo.label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text(d.descricao, maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 12),
                      Text('Status: ${d.status.label}', style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}