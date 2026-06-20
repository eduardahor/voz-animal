import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/denuncia.dart';
import '../../models/historico_item.dart';
import '../../models/localizacao.dart';
import '../../models/status_denuncia.dart';
import '../../models/tipo_ocorrencia.dart';
import '../../services/denuncia_service.dart';
import '../foto_denuncia.dart';
import '../shared/badges.dart';

class DetalheDenunciaOrgaoScreen extends StatefulWidget {
  final Denuncia denuncia;
  final String orgaoId;
  final String orgaoNome;

  const DetalheDenunciaOrgaoScreen({
    super.key,
    required this.denuncia,
    required this.orgaoId,
    required this.orgaoNome,
  });

  @override
  State<DetalheDenunciaOrgaoScreen> createState() =>
      _DetalheDenunciaOrgaoScreenState();
}

class _DetalheDenunciaOrgaoScreenState
    extends State<DetalheDenunciaOrgaoScreen> {
  bool get _souResponsavel =>
      widget.denuncia.orgaoResponsavelId == widget.orgaoId;

  @override
  void initState() {
    super.initState();
    // Auditoria LGPD: registra a visualização dos dados de contato do
    // denunciante UMA vez ao abrir a tela — só se o órgão for de fato
    // o responsável (única condição em que esses dados são exibidos).
    if (_souResponsavel) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<DenunciaService>().registrarVisualizacaoDadosDenunciante(
              denunciaId: widget.denuncia.id,
              orgaoId: widget.orgaoId,
              orgaoNome: widget.orgaoNome,
            );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd/MM/yyyy HH:mm');
    final svc = context.read<DenunciaService>();
    final d = widget.denuncia;

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
            _ContatoDenuncianteCard(
              denuncia: d,
              souResponsavel: _souResponsavel,
            ),

            const Divider(height: 28),
            const Text('Descrição',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(d.descricao),

            const Divider(height: 28),
            const Text('Local',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            if (d.localizacao == null)
              const Text('Não informado')
            else
              _LocalCard(localizacao: d.localizacao!),

            const SizedBox(height: 24),

            if (d.status == StatusDenuncia.aberta)
              _BotaoAssumir(
                denuncia: d,
                orgaoId: widget.orgaoId,
                orgaoNome: widget.orgaoNome,
                svc: svc,
              ),

            if (_souResponsavel &&
                (d.status == StatusDenuncia.emAnalise ||
                    d.status == StatusDenuncia.emAndamento)) ...[
              _BotaoAlterarStatus(denuncia: d, orgaoId: widget.orgaoId,
                  orgaoNome: widget.orgaoNome, svc: svc),
              const SizedBox(height: 8),
              _BotaoDevolver(denuncia: d, orgaoId: widget.orgaoId,
                  orgaoNome: widget.orgaoNome, svc: svc),
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

// ── Card: Contato do denunciante ────────────────────────────────────────────
//
// Regra de visibilidade (minimização de dados — LGPD):
//   • status == aberta (ninguém assumiu ainda): mostra só "Denunciante
//     identificado" + primeiro nome. Não expõe telefone/e-mail/CPF para
//     evitar que órgãos "bisbilhotem" contato sem se comprometer a atender.
//   • órgão É o responsável (assumiu a denúncia): libera nome completo,
//     telefone (botões Ligar / WhatsApp) e e-mail.
//   • CPF: nunca aparece junto com o resto — fica em uma seção colapsada
//     separada, com aviso de finalidade, e só visível ao responsável.

class _ContatoDenuncianteCard extends StatelessWidget {
  final Denuncia denuncia;
  final bool souResponsavel;

  const _ContatoDenuncianteCard({
    required this.denuncia,
    required this.souResponsavel,
  });

  @override
  Widget build(BuildContext context) {
    final d = denuncia;
    final temNome = (d.denuncianteNome ?? '').trim().isNotEmpty;

    if (!souResponsavel) {
      // Pré-claim: identificação mínima, sem dados de contato.
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(Icons.person_outline, color: Colors.grey.shade600, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                temNome
                    ? 'Denunciante identificado: ${_primeiroNome(d.denuncianteNome!)}'
                    : 'Denunciante identificado',
                style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    // Pós-claim: dados completos de contato liberados.
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.person, color: Colors.blue.shade700, size: 20),
            const SizedBox(width: 8),
            Text('Contato do denunciante',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                    fontSize: 13)),
          ]),
          const SizedBox(height: 10),

          if (temNome)
            _LinhaContato(icone: Icons.badge_outlined, texto: d.denuncianteNome!),

          if ((d.denuncianteTelefone ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _LinhaContato(
                    icone: Icons.phone_outlined,
                    texto: _formatarTelefone(d.denuncianteTelefone!),
                  ),
                ),
                IconButton(
                  tooltip: 'Ligar',
                  icon: const Icon(Icons.call, size: 20),
                  color: Colors.green.shade700,
                  onPressed: () => _ligar(d.denuncianteTelefone!),
                ),
                IconButton(
                  tooltip: 'WhatsApp',
                  icon: const Icon(Icons.chat, size: 20),
                  color: const Color(0xFF25D366),
                  onPressed: () => _whatsapp(d.denuncianteTelefone!),
                ),
              ],
            ),
          ],

          if ((d.denuncianteEmail ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            _LinhaContato(icone: Icons.email_outlined, texto: d.denuncianteEmail!),
          ],

          if ((d.denuncianteCpf ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            _SecaoCpfColapsada(cpf: d.denuncianteCpf!),
          ],
        ],
      ),
    );
  }

  static String _primeiroNome(String nomeCompleto) =>
      nomeCompleto.trim().split(' ').first;

  static String _formatarTelefone(String digits) {
    final d = digits.replaceAll(RegExp(r'\D'), '');
    if (d.length == 11) {
      return '(${d.substring(0, 2)}) ${d.substring(2, 7)}-${d.substring(7)}';
    }
    if (d.length == 10) {
      return '(${d.substring(0, 2)}) ${d.substring(2, 6)}-${d.substring(6)}';
    }
    return digits;
  }

  static Future<void> _ligar(String telefone) async {
    final digits = telefone.replaceAll(RegExp(r'\D'), '');
    final uri = Uri.parse('tel:$digits');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  static Future<void> _whatsapp(String telefone) async {
    final digits = telefone.replaceAll(RegExp(r'\D'), '');
    // WhatsApp exige código do país; assume Brasil (55) se ausente.
    final comDdi = digits.length <= 11 ? '55$digits' : digits;
    final uri = Uri.parse('https://wa.me/$comDdi');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _LinhaContato extends StatelessWidget {
  final IconData icone;
  final String texto;
  const _LinhaContato({required this.icone, required this.texto});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icone, size: 16, color: Colors.blue.shade700),
      const SizedBox(width: 8),
      Expanded(
        child: SelectableText(texto, style: const TextStyle(fontSize: 13)),
      ),
    ],
  );
}

// ── Seção colapsada: CPF para procedimento formal ───────────────────────────

class _SecaoCpfColapsada extends StatelessWidget {
  final String cpf;
  const _SecaoCpfColapsada({required this.cpf});

  String get _cpfFormatado {
    final d = cpf.replaceAll(RegExp(r'\D'), '');
    if (d.length != 11) return cpf;
    return '${d.substring(0, 3)}.${d.substring(3, 6)}.${d.substring(6, 9)}-${d.substring(9)}';
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: const Text('Dados para procedimento formal',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        leading: Icon(Icons.gavel_outlined, size: 18, color: Colors.blue.shade700),
        childrenPadding: const EdgeInsets.only(bottom: 8),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _LinhaContato(icone: Icons.badge, texto: 'CPF: $_cpfFormatado'),
                const SizedBox(height: 6),
                Text(
                  'Use apenas se for converter esta denúncia em Boletim de '
                  'Ocorrência ou processo administrativo formal.',
                  style: TextStyle(fontSize: 11, color: Colors.amber.shade900),
                ),
              ],
            ),
          ),
        ],
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
    final observacao = await showDialog<String>(
      context: context,
      builder: (_) => _DialogDevolver(),
    );
    if (observacao == null) return;

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
      case 'dados_denunciante_visualizados':
        return const Icon(Icons.visibility_outlined, color: Colors.indigo);
      default:            return const Icon(Icons.swap_horiz, color: Colors.purple);
    }
  }
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
            : Colors.green.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: loc.temGps
                ? cor.withValues(alpha: 0.3)
                : Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(loc.temGps ? Icons.gps_fixed : Icons.location_on,
                color: loc.temGps ? cor : Colors.green.shade700, size: 18),
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
                        color: cor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ),
          ]),
          if (loc.cidade.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('${loc.cidade}/${loc.estado}'
                '${loc.cep.isNotEmpty ? " — CEP ${loc.cep}" : ""}',
                style: const TextStyle(
                    color: Colors.black54, fontSize: 13)),
          ],
          if (loc.temGps) ...[
            const SizedBox(height: 6),
            SelectableText(
              'Lat: ${loc.latitude!.toStringAsFixed(6)}  '
              'Lon: ${loc.longitude!.toStringAsFixed(6)}',
              style: const TextStyle(
                  fontSize: 11,
                  color: Colors.black45,
                  fontFamily: 'monospace'),
            ),
          ],
        ],
      ),
    );
  }
}
