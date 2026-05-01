import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/denuncia.dart';
import '../models/status_denuncia.dart';

class DenunciaCard extends StatelessWidget {
  final Denuncia denuncia;
  final VoidCallback onTap;
  final bool showClassificacao;

  const DenunciaCard({super.key, required this.denuncia, required this.onTap, this.showClassificacao = false});

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
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            Container(
              width: 50, height: 50,
              decoration: BoxDecoration(color: _corStatus(denuncia.statusDenuncia).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.pets, color: _corStatus(denuncia.statusDenuncia)),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(denuncia.tipo, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(denuncia.descricao.length > 40 ? '\${denuncia.descricao.substring(0, 40)}...' : denuncia.descricao, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              const SizedBox(height: 4),
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: _corStatus(denuncia.statusDenuncia).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                  child: Text(denuncia.statusDenuncia.label, style: TextStyle(fontSize: 11, color: _corStatus(denuncia.statusDenuncia), fontWeight: FontWeight.w600)),
                ),
                if (showClassificacao && denuncia.classificacao != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                    child: Text(denuncia.classificacao!.label, style: const TextStyle(fontSize: 11, color: Colors.red)),
                  ),
                ],
                const Spacer(),
                Text(DateFormat('dd/MM').format(denuncia.dataCriacao), style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
              ]),
            ])),
          ]),
        ),
      ),
    );
  }
}
