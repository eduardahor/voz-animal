import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../models/localizacao.dart';
import '../../services/localizacao_service.dart';


class _CepInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue old, TextEditingValue nv) {
    final digits = nv.text.replaceAll(RegExp(r'\D'), '');
    final buf = StringBuffer();
    for (var i = 0; i < digits.length && i < 8; i++) {
      if (i == 5) buf.write('-');
      buf.write(digits[i]);
    }
    final text = buf.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}


class SelecionarLocalizacaoScreen extends StatefulWidget {
  final Localizacao? inicial;
  const SelecionarLocalizacaoScreen({super.key, this.inicial});

  @override
  State<SelecionarLocalizacaoScreen> createState() =>
      _SelecionarLocalizacaoScreenState();
}

class _SelecionarLocalizacaoScreenState
    extends State<SelecionarLocalizacaoScreen> {
  final _formKey  = GlobalKey<FormState>();
  late final TextEditingController _endereco;
  late final TextEditingController _cidade;
  late final TextEditingController _cep;
  String _uf = 'SP';

  bool _buscandoGps = false;
  double? _latGps;
  double? _lonGps;
  double? _precisaoGps;   // metros

  @override
  void initState() {
    super.initState();
    final ini = widget.inicial;
    _endereco = TextEditingController(text: ini?.endereco ?? '');
    _cidade   = TextEditingController(text: ini?.cidade   ?? '');
    _cep      = TextEditingController(text: ini?.cep      ?? '');
    if (ini != null) {
      _uf         = ini.estado.isNotEmpty ? ini.estado : 'SP';
      _latGps     = ini.latitude;
      _lonGps     = ini.longitude;
      _precisaoGps = ini.precisaoMetros;
    }
  }

  @override
  void dispose() {
    _endereco.dispose();
    _cidade.dispose();
    _cep.dispose();
    super.dispose();
  }


  Future<void> _usarGps() async {
    setState(() => _buscandoGps = true);
    final result = await context.read<LocalizacaoService>().obterLocalizacaoAtual();
    if (!mounted) return;
    setState(() => _buscandoGps = false);

    switch (result) {
      case GpsSuccess(:final localizacao):
        setState(() {
          _latGps      = localizacao.latitude;
          _lonGps      = localizacao.longitude;
          _precisaoGps = localizacao.precisaoMetros;
          // Preenche campos apenas se o reverse geocoding retornou dados
          if (localizacao.endereco.isNotEmpty) {
            _endereco.text = localizacao.endereco;
          }
          if (localizacao.cidade.isNotEmpty) _cidade.text = localizacao.cidade;
          if (localizacao.estado.isNotEmpty &&
              ufsBrasil.contains(localizacao.estado)) {
            _uf = localizacao.estado;
          }
          if (localizacao.cep.isNotEmpty) _cep.text = localizacao.cep;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              const Icon(Icons.gps_fixed, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text('GPS obtido! Precisão: '
                  '±${_precisaoGps!.toStringAsFixed(0)} m'),
            ]),
            backgroundColor: Color(_locAtual().precisaoCor),
            behavior: SnackBarBehavior.floating,
          ),
        );

      case GpsFailure(:final mensagem):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mensagem),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Configurações',
              textColor: Colors.white,
              onPressed: () => Geolocator.openLocationSettings(),
            ),
          ),
        );
    }
  }


  void _confirmar() {
    if (!_formKey.currentState!.validate()) return;
    final loc = Localizacao(
      endereco: _endereco.text.trim(),
      cidade:   _cidade.text.trim(),
      estado:   _uf,
      cep:      _cep.text.trim(),
      latitude: _latGps,
      longitude: _lonGps,
      precisaoMetros: _precisaoGps,
    );
    if (!context.read<LocalizacaoService>().validarEndereco(loc)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Endereço inválido. Revise os campos.')),
      );
      return;
    }
    Navigator.pop(context, loc);
  }

  Localizacao _locAtual() => Localizacao(
    endereco: _endereco.text,
    cidade:   _cidade.text,
    estado:   _uf,
    cep:      _cep.text,
    latitude: _latGps,
    longitude: _lonGps,
    precisaoMetros: _precisaoGps,
  );


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
              _MapaVisual(
                endereco: _endereco.text,
                cidade:   _cidade.text,
                latitude: _latGps,
                longitude: _lonGps,
              ),
              const SizedBox(height: 12),

              if (_latGps != null) ...[
                _PrecisaoIndicador(
                  latitude:     _latGps!,
                  longitude:    _lonGps!,
                  precisaoMetros: _precisaoGps,
                ),
                const SizedBox(height: 12),
              ],

              OutlinedButton.icon(
                onPressed: _buscandoGps ? null : _usarGps,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue.shade700,
                  side: BorderSide(color: Colors.blue.shade700),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: _buscandoGps
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.gps_fixed),
                label: Text(_buscandoGps
                    ? 'Obtendo localização...'
                    : 'Usar minha localização atual (GPS)'),
              ),
              const SizedBox(height: 4),
              const Text(
                'O GPS marca o local exato da ocorrência com alta precisão.',
                style: TextStyle(fontSize: 12, color: Colors.black45),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _endereco,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Endereço (rua e número) *',
                  prefixIcon: Icon(Icons.edit_road),
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().length < 5) {
                    return 'Informe o endereço';
                  }
                  // Número obrigatório apenas para endereço manual
                  if (_latGps == null && !RegExp(r'\d+').hasMatch(v)) {
                    return 'Inclua o número do endereço';
                  }
                  return null;
                },
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _cidade,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Cidade *',
                      prefixIcon: Icon(Icons.location_city),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (_latGps != null) return null;
                      return (v == null || v.trim().length < 2)
                          ? 'Informe a cidade'
                          : null;
                    },
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
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 10, vertical: 14),
                    ),
                    items: ufsBrasil
                        .map((u) =>
                            DropdownMenuItem(value: u, child: Text(u)))
                        .toList(),
                    onChanged: (v) => setState(() => _uf = v ?? 'SP'),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              TextFormField(
                controller: _cep,
                keyboardType: TextInputType.number,
                inputFormatters: [_CepInputFormatter()],
                decoration: const InputDecoration(
                  labelText: 'CEP',
                  hintText: '00000-000',
                  prefixIcon: Icon(Icons.markunread_mailbox_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (_latGps != null && (v == null || v.isEmpty)) {
                    return null;
                  }
                  if (v == null || v.isEmpty) return null;
                  if (!RegExp(r'^\d{5}-\d{3}$').hasMatch(v.trim())) {
                    return 'CEP inválido (formato: 00000-000)';
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


class _PrecisaoIndicador extends StatelessWidget {
  final double latitude;
  final double longitude;
  final double? precisaoMetros;

  const _PrecisaoIndicador({
    required this.latitude,
    required this.longitude,
    this.precisaoMetros,
  });

  @override
  Widget build(BuildContext context) {
    final loc = Localizacao(
      endereco: '', cidade: '', estado: 'SP', cep: '',
      latitude: latitude, longitude: longitude,
      precisaoMetros: precisaoMetros,
    );
    final cor = Color(loc.precisaoCor);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.1),
        border: Border.all(color: cor.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.gps_fixed, color: cor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Localização GPS capturada',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: cor,
                        fontSize: 13)),
                const SizedBox(height: 2),
                Text(
                  '${latitude.toStringAsFixed(6)}, '
                  '${longitude.toStringAsFixed(6)}',
                  style: const TextStyle(
                      fontSize: 11, color: Colors.black54,
                      fontFamily: 'monospace'),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: cor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              loc.precisaoLabel,
              style: TextStyle(
                  color: cor, fontWeight: FontWeight.bold, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}


class _MapaVisual extends StatelessWidget {
  final String endereco;
  final String cidade;
  final double? latitude;
  final double? longitude;

  const _MapaVisual({
    required this.endereco,
    required this.cidade,
    this.latitude,
    this.longitude,
  });

  @override
  Widget build(BuildContext context) {
    final temGps = latitude != null && longitude != null;
    return Container(
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: temGps
              ? [Colors.blue.shade200, Colors.green.shade200]
              : [Colors.blue.shade100, Colors.green.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          CustomPaint(size: Size.infinite, painter: _GradePainter()),
          if (temGps)
            Positioned(
              top: 8, right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade700,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.satellite_alt, color: Colors.white, size: 12),
                    SizedBox(width: 4),
                    Text('GPS', style: TextStyle(
                        color: Colors.white, fontSize: 11,
                        fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.location_on,
                    color: temGps ? Colors.green.shade800 : Colors.redAccent,
                    size: 48),
                const SizedBox(height: 4),
                Text(
                  endereco.isEmpty ? 'Endereço não informado' : endereco,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (cidade.isNotEmpty)
                  Text(cidade,
                      style: const TextStyle(color: Colors.black54)),
                if (temGps)
                  Text(
                    '${latitude!.toStringAsFixed(4)}, '
                    '${longitude!.toStringAsFixed(4)}',
                    style: const TextStyle(
                        fontSize: 10, color: Colors.black45,
                        fontFamily: 'monospace'),
                  ),
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
  bool shouldRepaint(covariant CustomPainter old) => false;
}