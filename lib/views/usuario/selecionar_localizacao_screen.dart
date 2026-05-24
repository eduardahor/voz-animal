import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/localizacao.dart';
import '../../services/localizacao_service.dart';


class SelecionarLocalizacaoScreen extends StatefulWidget {
  final Localizacao? inicial;
  const SelecionarLocalizacaoScreen({super.key, this.inicial});

  @override
  State<SelecionarLocalizacaoScreen> createState() =>
      _SelecionarLocalizacaoScreenState();
}

class _SelecionarLocalizacaoScreenState
    extends State<SelecionarLocalizacaoScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _endereco;
  late final TextEditingController _cidade;
  late final TextEditingController _cep;
  String _uf = 'SP';
  bool _buscandoGps = false;

  @override
  void initState() {
    super.initState();
    _endereco = TextEditingController(text: widget.inicial?.endereco ?? '');
    _cidade = TextEditingController(text: widget.inicial?.cidade ?? '');
    _cep = TextEditingController(text: widget.inicial?.cep ?? '');
    if (widget.inicial != null) _uf = widget.inicial!.estado;
  }

  @override
  void dispose() {
    _endereco.dispose();
    _cidade.dispose();
    _cep.dispose();
    super.dispose();
  }

  Future<void> _usarLocalizacaoAtual() async {
    setState(() => _buscandoGps = true);
    final loc =
        await context.read<LocalizacaoService>().obterAtualSimulada();
    setState(() {
      _endereco.text = loc.endereco;
      _cidade.text = loc.cidade;
      _cep.text = loc.cep;
      _uf = loc.estado;
      _buscandoGps = false;
    });
  }

  void _confirmar() {
    if (!_formKey.currentState!.validate()) return;
    final loc = Localizacao(
      endereco: _endereco.text.trim(),
      cidade: _cidade.text.trim(),
      estado: _uf,
      cep: _cep.text.trim(),
    );
    final svc = context.read<LocalizacaoService>();
    if (!svc.validarEndereco(loc)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Endereço inválido. Revise os campos.')),
      );
      return;
    }
    Navigator.pop(context, loc);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Localização da ocorrência'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _MapaSimulado(endereco: _endereco.text, cidade: _cidade.text),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _buscandoGps ? null : _usarLocalizacaoAtual,
                icon: const Icon(Icons.my_location),
                label: Text(_buscandoGps
                    ? 'Buscando...'
                    : 'Usar minha localização atual'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _endereco,
                decoration: const InputDecoration(
                  labelText: 'Endereço (rua e número)',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().length < 5) {
                    return 'Informe rua e número';
                  }
                  if (!RegExp(r'\d+').hasMatch(v)) {
                    return 'Inclua o número do endereço';
                  }
                  return null;
                },
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _cidade,
                      decoration: const InputDecoration(
                        labelText: 'Cidade',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => (v == null || v.trim().length < 2)
                          ? 'Informe a cidade'
                          : null,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: DropdownButtonFormField<String>(
                      initialValue: _uf,
                      decoration: const InputDecoration(
                        labelText: 'UF',
                        border: OutlineInputBorder(),
                      ),
                      items: ufsBrasil
                          .map((u) =>
                              DropdownMenuItem(value: u, child: Text(u)))
                          .toList(),
                      onChanged: (v) => setState(() => _uf = v ?? 'SP'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _cep,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'CEP (00000-000)',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null ||
                      !RegExp(r'^\d{5}-?\d{3}$').hasMatch(v.trim())) {
                    return 'CEP inválido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _confirmar,
                icon: const Icon(Icons.check),
                label: const Text('CONFIRMAR LOCALIZAÇÃO',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapaSimulado extends StatelessWidget {
  final String endereco;
  final String cidade;
  const _MapaSimulado({required this.endereco, required this.cidade});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [Colors.blue.shade100, Colors.green.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // grade simulando ruas
          CustomPaint(size: Size.infinite, painter: _GradePainter()),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.location_on,
                    color: Colors.redAccent, size: 48),
                const SizedBox(height: 4),
                Text(
                  endereco.isEmpty ? 'Endereço não informado' : endereco,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                if (cidade.isNotEmpty)
                  Text(cidade,
                      style: const TextStyle(color: Colors.black54)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GradePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 24) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (double y = 0; y < size.height; y += 24) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
