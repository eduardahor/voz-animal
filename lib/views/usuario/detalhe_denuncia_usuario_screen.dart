import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/denuncia.dart';
import '../../models/localizacao.dart';
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
              _LocalCard(localizacao: d.localizacao!),
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


class _LocalCard extends StatelessWidget {
  final Localizacao localizacao;
  const _LocalCard({required this.localizacao});

  @override
  Widget build(BuildContext context) {
    final loc = localizacao;
    final cor = Color(loc.precisaoCor);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: loc.temGps
            ? cor.withValues(alpha: 0.08)
            : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: loc.temGps ? cor.withValues(alpha: 0.3) : Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(
              loc.temGps ? Icons.gps_fixed : Icons.location_on,
              color: loc.temGps ? cor : Colors.blue.shade700,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(loc.endereco,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            if (loc.temGps)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: cor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(loc.precisaoLabel,
                    style: TextStyle(
                        color: cor, fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ),
          ]),
          if (loc.cidade.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('${loc.cidade}/${loc.estado}'
                '${loc.cep.isNotEmpty ? " — CEP ${loc.cep}" : ""}',
                style: const TextStyle(color: Colors.black54, fontSize: 13)),
          ],
          if (loc.temGps) ...[
            const SizedBox(height: 6),
            SelectableText(
              'Lat: ${loc.latitude!.toStringAsFixed(6)}  '
              'Lon: ${loc.longitude!.toStringAsFixed(6)}',
              style: const TextStyle(
                  fontSize: 11, color: Colors.black45,
                  fontFamily: 'monospace'),
            ),
          ],
        ],
      ),
    );
  }
}
