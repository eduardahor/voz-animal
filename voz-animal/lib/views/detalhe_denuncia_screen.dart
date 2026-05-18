import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/status_denuncia.dart';
import '../services/denuncia_service.dart';

class DetalheDenunciaScreen extends StatelessWidget {
  final String denunciaId;

  const DetalheDenunciaScreen({super.key, required this.denunciaId});

  @override
  Widget build(BuildContext context) {
    final denunciaService = context.watch<DenunciaService>();
    final denuncia = denunciaService.buscarPorId(denunciaId);

    if (denuncia == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Denúncia')),
        body: const Center(child: Text('Denúncia não encontrada')),
      );
    }

    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes'),
        actions: [
          if (denuncia.status != StatusDenuncia.resolvida)
            TextButton.icon(
              onPressed: () {
                denunciaService.marcarComoResolvida(denunciaId);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Denúncia marcada como resolvida!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              icon: const Icon(Icons.check_circle, color: Colors.white),
              label: const Text('Resolver', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Placeholder de imagem
            Container(
              width: double.infinity,
              height: 220,
              color: Colors.grey.shade200,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image, size: 64, color: Colors.grey),
                    SizedBox(height: 8),
                    Text('Foto não disponível',
                        style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status e tipo
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Color(denuncia.status.corHex).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          denuncia.status.descricao,
                          style: TextStyle(
                            color: Color(denuncia.status.corHex),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          denuncia.tipoOcorrencia.descricao,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Resumo (polimorfismo)
                  Text(
                    denuncia.obterResumo(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Descrição
                  const Text(
                    'Descrição',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    denuncia.descricao,
                    style: const TextStyle(fontSize: 15, height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  // Informações
                  _InfoRow(
                    icon: Icons.location_on,
                    label: 'Local',
                    value: denuncia.localizacao.endereco,
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    icon: Icons.person,
                    label: 'Denunciante',
                    value: denuncia.nomeUsuario,
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    icon: Icons.calendar_today,
                    label: 'Data',
                    value: dateFormat.format(denuncia.dataCriacao),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Text(value, style: const TextStyle(fontSize: 15)),
            ],
          ),
        ),
      ],
    );
  }
}
