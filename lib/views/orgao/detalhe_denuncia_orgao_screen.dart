import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/classificacao_urgencia.dart';
import '../../models/denuncia.dart';
import '../../models/status_denuncia.dart';
import '../../models/tipo_ocorrencia.dart';
import '../../services/auth_service.dart';
import '../../services/denuncia_service.dart';
import '../foto_denuncia.dart';

class DetalheDenunciaOrgaoScreen extends StatelessWidget {
  final Denuncia denuncia;
  const DetalheDenunciaOrgaoScreen({super.key, required this.denuncia});

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd/MM/yyyy HH:mm');
    final auth = context.read<AuthService>();
    final svc = context.read<DenunciaService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestão da Denúncia'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: FotoDenuncia(path: denuncia.fotoPath),
            ),
            const SizedBox(height: 16),
            Text('Tipo: ${denuncia.tipo.label}'),
            Text('Urgência: ${denuncia.urgencia.label}'),
            Text('Registrada em: ${df.format(denuncia.criadoEm)}'),
            const Divider(height: 32),
            const Text('Descrição',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Text(denuncia.descricao),
            const Divider(height: 32),
            const Text('Local',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Text(denuncia.localizacao?.resumo() ?? 'Não informado'),
            const Divider(height: 32),
            const Text('Alterar status',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: StatusDenuncia.values.map((s) {
                final selecionado = s == denuncia.status;
                return ChoiceChip(
                  label: Text(s.label),
                  selected: selecionado,
                  onSelected: (_) {
                    svc.alterarStatus(
                      solicitante: auth.usuarioAtual!,
                      denunciaId: denuncia.id,
                      novo: s,
                    );
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
