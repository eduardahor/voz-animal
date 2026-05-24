import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/denuncia.dart';
import '../../models/historico_item.dart';
import '../../models/status_denuncia.dart';
import '../../models/tipo_ocorrencia.dart';
import '../../services/denuncia_service.dart';
import '../foto_denuncia.dart';
import '../shared/badges.dart';

class DetalheDenunciaOrgaoScreen extends StatelessWidget {
  final Denuncia denuncia;
  final String orgaoId;
  final String orgaoNome;

  const DetalheDenunciaOrgaoScreen({
    super.key,
    required this.denuncia,
    required this.orgaoId,
    required this.orgaoNome,
  });

  bool get _souResponsavel => denuncia.orgaoResponsavelId == orgaoId;

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd/MM/yyyy HH:mm');
    final svc = context.read<DenunciaService>();
    final d = denuncia;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Denúncia'),
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
              child: FotoDenuncia(path: d.fotoUrl),
            ),
            const SizedBox(height: 16),

            Wrap(spacing: 8, children: [
              StatusBadge(d.status),
              UrgenciaBadge(d.urgencia),
            ]),
            const SizedBox(height: 12),

            _Info('Tipo', d.tipo.label),
            _Info('Registrada em', df.format(d.criadoEm)),
            if (d.acceptedAt != null)
              _Info('Assumida em', df.format(d.acceptedAt!)),
            if (d.orgaoResponsavelNome != null)
              _Info('Responsável', d.orgaoResponsavelNome!),

            const Divider(height: 28),
            const Text('Descrição',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(d.descricao),

            const Divider(height: 28),
            const Text('Local',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(d.localizacao?.resumo() ?? 'Não informado'),

            const SizedBox(height: 24),

            if (d.status == StatusDenuncia.aberta)
              _BotaoAssumir(
                denuncia: d,
                orgaoId: orgaoId,
                orgaoNome: orgaoNome,
                svc: svc,
              ),

            if (_souResponsavel &&
                (d.status == StatusDenuncia.emAnalise ||
                    d.status == StatusDenuncia.emAndamento)) ...[
              _BotaoAlterarStatus(denuncia: d, orgaoId: orgaoId,
                  orgaoNome: orgaoNome, svc: svc),
              const SizedBox(height: 8),
              _BotaoDevolver(denuncia: d, orgaoId: orgaoId,
                  orgaoNome: orgaoNome, svc: svc),
            ],

            const Divider(height: 32),
            const Text('Histórico',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            _PainelHistorico(denunciaId: d.id, svc: svc),
          ],
        ),
      ),
    );
  }
}


class _Info extends StatelessWidget {
  final String label;
  final String valor;
  const _Info(this.label, this.valor);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(children: [
      Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
      Expanded(child: Text(valor)),
    ]),
  );
}


class _BotaoAssumir extends StatefulWidget {
  final Denuncia denuncia;
  final String orgaoId;
  final String orgaoNome;
  final DenunciaService svc;
  const _BotaoAssumir({required this.denuncia, required this.orgaoId,
      required this.orgaoNome, required this.svc});

  @override
  State<_BotaoAssumir> createState() => _BotaoAssumirState();
}

class _BotaoAssumirState extends State<_BotaoAssumir> {
  bool _carregando = false;

  Future<void> _assumir() async {
    setState(() => _carregando = true);
    final result = await widget.svc.assumir(
      denunciaId: widget.denuncia.id,
      orgaoId: widget.orgaoId,
      orgaoNome: widget.orgaoNome,
    );
    if (!mounted) return;
    setState(() => _carregando = false);

    _mostrarResultado(result);
    if (result is ClaimSuccess) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bloqueado = widget.denuncia.orgaoEstaBloqueado(widget.orgaoId);

    return SizedBox(
      height: 48,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green.shade700,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade300,
        ),
        onPressed: (_carregando || bloqueado) ? null : _assumir,
        icon: _carregando
            ? const SizedBox(width: 18, height: 18,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Icon(Icons.handshake_outlined),
        label: Text(bloqueado ? 'VOCÊ DEVOLVEU ESTA DENÚNCIA' : 'ASSUMIR DENÚNCIA',
            style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _mostrarResultado(ClaimResult r) {
    final ctx = context;
    if (!ctx.mounted) return;
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
      content: Text(
          r is ClaimSuccess ? r.mensagem : (r as ClaimFailure).mensagem),
      backgroundColor: r is ClaimSuccess ? Colors.green : Colors.red.shade700,
      behavior: SnackBarBehavior.floating,
    ));
  }
}


class _BotaoAlterarStatus extends StatefulWidget {
  final Denuncia denuncia;
  final String orgaoId;
  final String orgaoNome;
  final DenunciaService svc;
  const _BotaoAlterarStatus({required this.denuncia, required this.orgaoId,
      required this.orgaoNome, required this.svc});

  @override
  State<_BotaoAlterarStatus> createState() => _BotaoAlterarStatusState();
}

class _BotaoAlterarStatusState extends State<_BotaoAlterarStatus> {
  bool _carregando = false;

  Future<void> _alterar(StatusDenuncia novo) async {
    setState(() => _carregando = true);
    final result = await widget.svc.alterarStatus(
      denunciaId: widget.denuncia.id,
      orgaoId: widget.orgaoId,
      orgaoNome: widget.orgaoNome,
      novo: novo,
    );
    if (!mounted) return;
    setState(() => _carregando = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(result is ClaimSuccess
          ? result.mensagem
          : (result as ClaimFailure).mensagem),
      backgroundColor:
          result is ClaimSuccess ? Colors.green : Colors.red.shade700,
      behavior: SnackBarBehavior.floating,
    ));
    if (result is ClaimSuccess) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final permitidos = widget.denuncia.status.transicoesPermitidas;
    if (permitidos.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: permitidos.map((s) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: OutlinedButton.icon(
          onPressed: _carregando ? null : () => _alterar(s),
          icon: const Icon(Icons.swap_horiz),
          label: Text('Mover para: ${s.label}'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.green.shade700,
            side: BorderSide(color: Colors.green.shade700),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      )).toList(),
    );
  }
}


class _BotaoDevolver extends StatefulWidget {
  final Denuncia denuncia;
  final String orgaoId;
  final String orgaoNome;
  final DenunciaService svc;
  const _BotaoDevolver({required this.denuncia, required this.orgaoId,
      required this.orgaoNome, required this.svc});

  @override
  State<_BotaoDevolver> createState() => _BotaoDevolverState();
}

class _BotaoDevolverState extends State<_BotaoDevolver> {
  bool _carregando = false;

  Future<void> _devolver() async {
    // Pede confirmação + observação
    final observacao = await showDialog<String>(
      context: context,
      builder: (_) => _DialogDevolver(),
    );
    if (observacao == null) return; // cancelou

    setState(() => _carregando = true);
    final result = await widget.svc.devolver(
      denunciaId: widget.denuncia.id,
      orgaoId: widget.orgaoId,
      orgaoNome: widget.orgaoNome,
      observacao: observacao.isNotEmpty ? observacao : null,
    );
    if (!mounted) return;
    setState(() => _carregando = false);

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(result is ClaimSuccess
          ? result.mensagem
          : (result as ClaimFailure).mensagem),
      backgroundColor:
          result is ClaimSuccess ? Colors.orange : Colors.red.shade700,
      behavior: SnackBarBehavior.floating,
    ));
    if (result is ClaimSuccess) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 48,
    child: OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.orange.shade800,
        side: BorderSide(color: Colors.orange.shade800),
      ),
      onPressed: _carregando ? null : _devolver,
      icon: _carregando
          ? const SizedBox(width: 18, height: 18,
              child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.undo),
      label: const Text('DEVOLVER DENÚNCIA',
          style: TextStyle(fontWeight: FontWeight.bold)),
    ),
  );
}

class _DialogDevolver extends StatefulWidget {
  @override
  State<_DialogDevolver> createState() => _DialogDevolverState();
}

class _DialogDevolverState extends State<_DialogDevolver> {
  final _ctrl = TextEditingController();

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Devolver denúncia'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Ao devolver, a denúncia voltará para o pool de abertas e você '
          'ficará impedido de assumí-la novamente por 48 horas.',
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _ctrl,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Motivo (opcional)',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange.shade700,
          foregroundColor: Colors.white,
        ),
        onPressed: () => Navigator.pop(context, _ctrl.text),
        child: const Text('Confirmar'),
      ),
    ],
  );
}


class _PainelHistorico extends StatelessWidget {
  final String denunciaId;
  final DenunciaService svc;
  const _PainelHistorico({required this.denunciaId, required this.svc});

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd/MM HH:mm');
    return StreamBuilder<List<HistoricoItem>>(
      stream: svc.historicoDe(denunciaId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snap.data ?? [];
        if (items.isEmpty) {
          return const Text('Nenhum evento registrado.',
              style: TextStyle(color: Colors.black54));
        }
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          itemBuilder: (_, i) {
            final h = items[i];
            return ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: _icone(h.acao),
              title: Text(h.descricao,
                  style: const TextStyle(fontSize: 13)),
              subtitle: Text(df.format(h.ocorridoEm),
                  style: const TextStyle(fontSize: 11, color: Colors.black45)),
              trailing: h.observacao != null
                  ? Tooltip(
                      message: h.observacao!,
                      child: const Icon(Icons.comment_outlined,
                          size: 16, color: Colors.black38),
                    )
                  : null,
            );
          },
        );
      },
    );
  }

  Widget _icone(String acao) {
    switch (acao) {
      case 'assumiu':     return const Icon(Icons.handshake, color: Colors.green);
      case 'devolveu':    return const Icon(Icons.undo, color: Colors.orange);
      case 'auto_reset':  return const Icon(Icons.timer_off, color: Colors.grey);
      case 'criado':      return const Icon(Icons.add_circle_outline, color: Colors.blue);
      default:            return const Icon(Icons.swap_horiz, color: Colors.purple);
    }
  }
}
