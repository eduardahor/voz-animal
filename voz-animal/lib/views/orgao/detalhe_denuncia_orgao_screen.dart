import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/denuncia.dart';
import '../../models/status_denuncia.dart';
import '../../models/tipo_ocorrencia.dart';
import '../../models/classificacao_urgencia.dart';
import '../../services/auth_service.dart';
import '../../services/denuncia_service.dart';

class DetalhesDenunciaOrgaoScreen extends StatefulWidget {
  final Denuncia denuncia;
  const DetalhesDenunciaOrgaoScreen({super.key, required this.denuncia});

  @override
  State<DetalhesDenunciaOrgaoScreen> createState() => _DetalhesDenunciaOrgaoScreenState();
}

class _DetalhesDenunciaOrgaoScreenState extends State<DetalhesDenunciaOrgaoScreen> {
  late StatusDenuncia _statusSelecionado;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    _statusSelecionado = widget.denuncia.status;
  }

  Future<void> _atualizarCaso(StatusDenuncia novoStatus) async {
    setState(() => _salvando = true);
    final orgaoId = Provider.of<AuthService>(context, listen: false).usuarioAtual?.id ?? '';
    
    await Provider.of<DenunciaService>(context, listen: false).alterarStatus(
      denunciaId: widget.denuncia.id,
      novoStatus: novoStatus,
      orgaoId: orgaoId,
    );

    if (!mounted) return;
    setState(() => _salvando = false);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(novoStatus == StatusDenuncia.emAndamento ? 'Você assumiu este caso!' : 'Status atualizado!'), backgroundColor: Colors.green),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.denuncia;
    final isCasoNovo = d.status == StatusDenuncia.emAnalise;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do Caso'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tipo: ${d.tipo.label}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Urgência: ${d.urgencia.label}', style: const TextStyle(fontSize: 16, color: Colors.red)),
                    const Divider(height: 30),
                    const Text('Descrição:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Text(d.descricao, style: const TextStyle(fontSize: 16)),
                    const Divider(height: 30),
                    const Text('Localização:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Text(d.localizacao?.resumo() ?? 'Não informada', style: const TextStyle(fontSize: 16)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            if (isCasoNovo) ...[
              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.back_hand),
                  label: _salvando ? const CircularProgressIndicator(color: Colors.white) : const Text('ASSUMIR ESTE CASO', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
                  onPressed: _salvando ? null : () => _atualizarCaso(StatusDenuncia.emAndamento),
                ),
              ),
            ] else ...[
              const Text('Finalizar Caso:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              DropdownButtonFormField<StatusDenuncia>(
                value: _statusSelecionado,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: StatusDenuncia.emAndamento, child: Text('Em andamento (Trabalhando)')),
                  DropdownMenuItem(value: StatusDenuncia.resolvida, child: Text('Resolvida (Animal salvo)')),
                  DropdownMenuItem(value: StatusDenuncia.arquivada, child: Text('Arquivada (Trote/Inválida)')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _statusSelecionado = val);
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: _salvando ? const CircularProgressIndicator(color: Colors.white) : const Text('SALVAR NOVO STATUS', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
                  onPressed: _salvando ? null : () => _atualizarCaso(_statusSelecionado),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}