import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/denuncia.dart';
import '../models/status_denuncia.dart';
import '../services/denuncia_service.dart';

class DetalheDenunciaScreen extends StatelessWidget {
  final Denuncia denuncia;
  const DetalheDenunciaScreen({super.key, required this.denuncia});

  Color _corStatus(StatusDenuncia s) {
    switch (s) {
      case StatusDenuncia.pendente: return Colors.orange;
      case StatusDenuncia.emAnalise: return Colors.blue;
      case StatusDenuncia.emAndamento: return Colors.purple;
      case StatusDenuncia.resolvida: return Colors.green;
      case StatusDenuncia.arquivada: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes')),
      body: Consumer<DenunciaService>(
        builder: (_, service, __) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Foto placeholder
              Container(
                height: 200, width: double.infinity,
                decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(16)),
                child: const Icon(Icons.image, size: 60, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Row(children: [
                Chip(label: Text(denuncia.tipo), avatar: const Icon(Icons.category, size: 18)),
                const SizedBox(width: 8),
                Chip(
                  label: Text(denuncia.statusDenuncia.label),
                  backgroundColor: _corStatus(denuncia.statusDenuncia).withValues(alpha: 0.15),
                ),
                if (denuncia.classificacao != null) ...[
                  const SizedBox(width: 8),
                  Chip(label: Text('Urgência: \${denuncia.classificacao!.label}'), backgroundColor: Colors.red.withValues(alpha: 0.1)),
                ],
              ]),
              const SizedBox(height: 16),
              Text('Descrição', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(denuncia.descricao),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.location_on),
                title: Text(denuncia.localizacao.enderecoFormatado),
                subtitle: Text('Lat: \${denuncia.localizacao.latitude.toStringAsFixed(4)}, Lng: \${denuncia.localizacao.longitude.toStringAsFixed(4)}'),
              ),
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: Text(DateFormat('dd/MM/yyyy HH:mm').format(denuncia.dataCriacao)),
              ),
              if (denuncia.observacaoOrgao != null) ...[
                const Divider(),
                Text('Observação do Órgão', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(denuncia.observacaoOrgao!),
              ],
              const SizedBox(height: 24),
              if (denuncia.statusDenuncia != StatusDenuncia.resolvida)
                SizedBox(
                  width: double.infinity, height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      service.atualizarStatus(denuncia.id, StatusDenuncia.resolvida);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Marcada como resolvida!')));
                    },
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Marcar como Resolvida'),
                  ),
                ),
            ]),
          );
        },
      ),
    );
  }
}
