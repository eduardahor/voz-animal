import 'package:flutter/material.dart';
import '../../models/status_denuncia.dart';
import '../../models/classificacao_urgencia.dart';

class StatusBadge extends StatelessWidget {
  final StatusDenuncia status;
  const StatusBadge(this.status, {super.key});

  Color get _cor {
    switch (status) {
      case StatusDenuncia.emAnalise:
        return Colors.blue;
      case StatusDenuncia.emAndamento:
        return Colors.purple;
      case StatusDenuncia.resolvida:
        return Colors.green;
      case StatusDenuncia.arquivada:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _cor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _cor),
      ),
      child: Text(status.label,
          style: TextStyle(color: _cor, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }
}

class UrgenciaBadge extends StatelessWidget {
  final ClassificacaoUrgencia urgencia;
  const UrgenciaBadge(this.urgencia, {super.key});

  Color get _cor {
    switch (urgencia) {
      case ClassificacaoUrgencia.baixa:
        return Colors.green;
      case ClassificacaoUrgencia.media:
        return Colors.amber;
      case ClassificacaoUrgencia.alta:
        return Colors.deepOrange;
      case ClassificacaoUrgencia.critica:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _cor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text('Urgência: ${urgencia.label}',
          style: TextStyle(color: _cor, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }
}
