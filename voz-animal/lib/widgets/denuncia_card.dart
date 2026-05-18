import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/denuncia.dart';

/// Widget reutilizável para exibir um card de denúncia na listagem.
class DenunciaCard extends StatelessWidget {
  final Denuncia denuncia;
  final VoidCallback onTap;

  const DenunciaCard({
    super.key,
    required this.denuncia,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: tipo + status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        _iconePorTipo(denuncia.tipoOcorrencia.codigo),
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        denuncia.tipoOcorrencia.descricao,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Color(denuncia.status.corHex).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      denuncia.status.descricao,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(denuncia.status.corHex),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Descrição
              Text(
                denuncia.descricao,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 12),
              // Footer: local + data
              Row(
                children: [
                  const Icon(Icons.location_on, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      denuncia.localizacao.endereco,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    dateFormat.format(denuncia.dataCriacao),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconePorTipo(String codigo) {
    switch (codigo) {
      case 'animal_abandoned':
        return Icons.home_outlined;
      case 'animal_abuse':
        return Icons.warning_amber;
      case 'help_request':
        return Icons.sos;
      case 'lost_animal':
        return Icons.search;
      case 'injured_animal':
        return Icons.healing;
      default:
        return Icons.pets;
    }
  }
}
