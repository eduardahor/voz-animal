import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/denuncia.dart';
import '../../models/classificacao_urgencia.dart';
import '../../models/status_denuncia.dart';
import '../../models/tipo_ocorrencia.dart';
import '../foto_denuncia.dart';

class DetalheDenunciaUsuarioScreen extends StatelessWidget {
  final Denuncia denuncia;
  const DetalheDenunciaUsuarioScreen({super.key, required this.denuncia});

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd/MM/yyyy HH:mm');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhe da Denúncia'),
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
              child: FotoDenuncia(path: denuncia.fotoPath),
            ),
            const SizedBox(height: 16),
            _info('Tipo', denuncia.tipo.label),
            _info('Status', denuncia.status.label),
            _info('Urgência', denuncia.urgencia.label),
            _info('Registrada em', df.format(denuncia.criadoEm)),
            const Divider(height: 32),
            const Text('Descrição',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(denuncia.descricao),
            const Divider(height: 32),
            const Text('Local da ocorrência',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (denuncia.localizacao == null)
              const Text('Não informado')
            else ...[
              Container(
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade100, Colors.green.shade100],
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.location_on,
                      color: Colors.redAccent, size: 40),
                ),
              ),
              const SizedBox(height: 8),
              Text(denuncia.localizacao!.resumo()),
            ],
          ],
        ),
      ),
    );
  }

  Widget _info(String label, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('$label: ',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(valor)),
        ],
      ),
    );
  }
}
