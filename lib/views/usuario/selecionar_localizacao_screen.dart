import 'dart:async';
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

enum _CepStatus { ocioso, buscando, encontrado, naoEncontrado, semInternet }

class _SelecionarLocalizacaoScreenState
    extends State<SelecionarLocalizacaoScreen> {
  final _formKey   = GlobalKey<FormState>();
  late final TextEditingController _cep;
  late final TextEditingController _rua;
  late final TextEditingController _numero;
  late final TextEditingController _bairro;
  late final TextEditingController _cidade;
  String _uf = 'SP';

  bool _buscandoGps = false;
  double? _latGps;
  double? _lonGps;
  double? _precisaoGps;

  _CepStatus _cepStatus = _CepStatus.ocioso;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    final ini = widget.inicial;
    _cep    = TextEditingController(text: ini?.cep    ?? '');
    _rua    = TextEditingController(text: ini?.rua    ?? '');
    _numero = TextEditingController(text: ini?.numero ?? '');
    _bairro = TextEditingController(text: ini?.bairro ?? '');
    _cidade = TextEditingController(text: ini?.cidade ?? '');
    if (ini != null) {
      _uf          = ini.estado.isNotEmpty ? ini.estado : 'SP';
      _latGps      = ini.latitude;
      _lonGps      = ini.longitude;
      _precisaoGps = ini.precisaoMetros;
    }
    _cep.addListener(_onCepChanged);
  }

  @override
  void dispose() {
    _cep.removeListener(_onCepChanged);
    _debounce?.cancel();
    _cep.dispose();
    _rua.dispose();
    _numero.dispose();
    _bairro.dispose();
    _cidade.dispose();
    super.dispose();
  }

  /*
    Dispara sozinha ~500ms depois do usuário parar de digitar, assim que o
    CEP atinge 8 dígitos. Nunca bloqueia o formulário: se falhar, o usuário
    simplesmente preenche rua/bairro/cidade manualmente.
  */

  void _onCepChanged() {
    if (_gpsAtivo) return;

    final digits = _cep.text.replaceAll(RegExp(r'\D'), '');
    _debounce?.cancel();

    if (digits.length < 8) {
      if (_cepStatus != _CepStatus.ocioso) {
        setState(() => _cepStatus = _CepStatus.ocioso);
      }
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 500), () => _buscarCep(digits));
  }

  Future<void> _buscarCep(String digits) async {
    if (!mounted) return;
    setState(() => _cepStatus = _CepStatus.buscando);

    final result = await context.read<LocalizacaoService>().buscarPorCep(digits);
    if (!mounted) return;

    switch (result) {
      case CepSuccess(:final rua, :final bairro, :final cidade, :final estado):
        setState(() {
          _cepStatus = _CepStatus.encontrado;
          if (rua.isNotEmpty) _rua.text = rua;
          if (bairro.isNotEmpty) _bairro.text = bairro;
          if (cidade.isNotEmpty) _cidade.text = cidade;
          if (estado.isNotEmpty && ufsBrasil.contains(estado)) _uf = estado;
        });
        FocusScope.of(context).requestFocus(_numeroFocus);

      case CepNaoEncontrado():
        setState(() => _cepStatus = _CepStatus.naoEncontrado);

      case CepFalhaRede():
        setState(() => _cepStatus = _CepStatus.semInternet);
    }
  }

  final _numeroFocus = FocusNode();


  /*
    Quando true, os campos de texto ficam bloqueados — o GPS já garante
    a localização exata e editar texto nesse momento só geraria confusão
    sobre qual fonte (GPS ou texto) vale.
  */
  bool get _gpsAtivo => _latGps != null;

  void _limparGps() {
    setState(() {
      _latGps = null;
      _lonGps = null;
      _precisaoGps = null;
    });
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
          if (localizacao.rua.isNotEmpty) _rua.text = localizacao.rua;
          if (localizacao.numero.isNotEmpty) _numero.text = localizacao.numero;
          if (localizacao.bairro.isNotEmpty) _bairro.text = localizacao.bairro;
          if (localizacao.cidade.isNotEmpty) _cidade.text = localizacao.cidade;
          if (localizacao.estado.isNotEmpty &&
              ufsBrasil.contains(localizacao.estado)) {
            _uf = localizacao.estado;
          }
          if (localizacao.cep.isNotEmpty) _cep.text = localizacao.cep;
        });
        if (!mounted) return;
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
    final loc = _locAtual();
    if (!context.read<LocalizacaoService>().validarEndereco(loc)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe ao menos a rua e a cidade, ou use o GPS.')),
      );
      return;
    }
    Navigator.pop(context, loc);
  }

  Localizacao _locAtual() => Localizacao(
    rua:      _rua.text.trim(),
    numero:   _numero.text.trim(),
    bairro:   _bairro.text.trim(),
    cidade:   _cidade.text.trim(),
    estado:   _uf,
    cep:      _cep.text.trim(),
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
                endereco: _locAtual().endereco,
                cidade:   _cidade.text,
                latitude: _latGps,
                longitude: _lonGps,
              ),
              const SizedBox(height: 12),

              if (_gpsAtivo) ...[
                _PrecisaoIndicador(
                  latitude:     _latGps!,
                  longitude:    _lonGps!,
                  precisaoMetros: _precisaoGps,
                ),
                const SizedBox(height: 12),
              ],

              if (!_gpsAtivo) ...[
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
              ] else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    border: Border.all(color: Colors.green.shade200),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Localização GPS definida — os campos abaixo '
                          'estão bloqueados pois já não são necessários.',
                          style: TextStyle(fontSize: 12, color: Colors.green.shade800),
                        ),
                      ),
                      TextButton(
                        onPressed: _limparGps,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.green.shade800,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        child: const Text('Trocar',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),
              Row(children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    _gpsAtivo ? 'preenchimento manual (desativado)' : 'ou preencha manualmente',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ),
                const Expanded(child: Divider()),
              ]),
              const SizedBox(height: 16),

              TextFormField(
                controller: _cep,
                enabled: !_gpsAtivo,
                keyboardType: TextInputType.number,
                inputFormatters: [_CepInputFormatter()],
                decoration: InputDecoration(
                  labelText: 'CEP (opcional)',
                  hintText: '00000-000',
                  helperText: _gpsAtivo
                      ? null
                      : 'Preenche rua e bairro automaticamente',
                  prefixIcon: const Icon(Icons.markunread_mailbox_outlined),
                  suffixIcon: _buildCepSuffixIcon(),
                  border: const OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return null;
                  if (!RegExp(r'^\d{5}-\d{3}$').hasMatch(v.trim())) {
                    return 'CEP incompleto';
                  }
                  return null;
                },
              ),
              _buildCepStatusMessage(),
              const SizedBox(height: 16),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _rua,
                      enabled: !_gpsAtivo,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Rua / Avenida *',
                        prefixIcon: Icon(Icons.edit_road),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        if (_gpsAtivo) return null; // GPS já garante local
                        if (v == null || v.trim().length < 3) {
                          return 'Informe a rua';
                        }
                        return null;
                      },
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      controller: _numero,
                      enabled: !_gpsAtivo,
                      focusNode: _numeroFocus,
                      keyboardType: TextInputType.text,
                      decoration: const InputDecoration(
                        labelText: 'Nº',
                        hintText: 'S/N',
                        border: OutlineInputBorder(),
                      ),
                      // Número é sempre opcional — em ocorrências de rua
                      // (terreno baldio, praça, em frente a tal lugar) o
                      // cidadão raramente tem um número exato para informar.
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              if (!_gpsAtivo)
                Text(
                  'Sem o número exato? Descreva uma referência (ex: "em frente à padaria").',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _bairro,
                enabled: !_gpsAtivo,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Bairro *',
                  prefixIcon: Icon(Icons.holiday_village_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (_gpsAtivo) return null;
                  if (v == null || v.trim().isEmpty) {
                    return 'Informe o bairro';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              Row(children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _cidade,
                    enabled: !_gpsAtivo,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Cidade *',
                      prefixIcon: Icon(Icons.location_city),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (_gpsAtivo) return null;
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
                    onChanged: _gpsAtivo ? null : (v) => setState(() => _uf = v ?? 'SP'),
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
                  ),
                ),
              ]),
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


  Widget? _buildCepSuffixIcon() {
    switch (_cepStatus) {
      case _CepStatus.buscando:
        return const Padding(
          padding: EdgeInsets.all(12),
          child: SizedBox(
            width: 16, height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      case _CepStatus.encontrado:
        return Icon(Icons.check_circle, color: Colors.green.shade600);
      case _CepStatus.naoEncontrado:
      case _CepStatus.semInternet:
        return Icon(Icons.info_outline, color: Colors.orange.shade700);
      case _CepStatus.ocioso:
        return null;
    }
  }

  Widget _buildCepStatusMessage() {
    String? texto;
    Color? cor;

    switch (_cepStatus) {
      case _CepStatus.naoEncontrado:
        texto = 'CEP não encontrado — sem problema, preencha os campos abaixo manualmente.';
        cor = Colors.orange.shade700;
      case _CepStatus.semInternet:
        texto = 'Sem conexão para buscar o CEP — preencha os campos abaixo manualmente.';
        cor = Colors.orange.shade700;
      case _CepStatus.encontrado:
        texto = 'Endereço encontrado! Confira e complete o número se necessário.';
        cor = Colors.green.shade700;
      case _CepStatus.buscando:
      case _CepStatus.ocioso:
        return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 4),
      child: Text(texto, style: TextStyle(fontSize: 12, color: cor)),
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
      rua: '', cidade: '', estado: 'SP',
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
