import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/denuncia.dart';
import '../../models/tipo_ocorrencia.dart';
import '../foto_denuncia.dart';
import '../shared/badges.dart';

class DetalheDenunciaUsuarioScreen extends StatelessWidget {
  final Denuncia denuncia;
  const DetalheDenunciaUsuarioScreen(
      {super.key, required this.denuncia});

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd/MM/yyyy HH:mm');
    final d  = denuncia;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Minha Denúncia'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: FotoDenuncia(path: d.fotoUrl),
            ),
            const SizedBox(height: 16),

            // Badges
            Wrap(spacing: 8, children: [
              StatusBadge(d.status),
              UrgenciaBadge(d.urgencia),
            ]),
            const SizedBox(height: 12),

            _info('Tipo',         d.tipo.label),
            _info('Registrada em', df.format(d.criadoEm)),
            if (d.orgaoResponsavelNome != null)
              _info('Responsável', d.orgaoResponsavelNome!),
            if (d.acceptedAt != null)
              _info('Assumida em', df.format(d.acceptedAt!)),

            const Divider(height: 28),
            const Text('Descrição',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(d.descricao),

            const Divider(height: 28),
            const Text('Local da ocorrência',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (d.localizacao == null)
              const Text('Não informado')
            else ...[
              Container(
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: LinearGradient(
                    colors: [
                      Colors.blue.shade100,
                      Colors.green.shade100
                    ],
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.location_on,
                      color: Colors.redAccent, size: 40),
                ),
              ),
              const SizedBox(height: 8),
              Text(d.localizacao!.resumo()),
            ],
          ],
        ),
      ),
    );
  }

  Widget _info(String label, String valor) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(children: [
      Text('$label: ',
          style: const TextStyle(fontWeight: FontWeight.bold)),
      Expanded(child: Text(valor)),
    ]),
  );
}
