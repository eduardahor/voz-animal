import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../models/localizacao.dart';
import '../../services/localizacao_service.dart';
import '../shared/font_size_controls.dart';


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
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _cep;
  late final TextEditingController _rua;
  late final TextEditingController _numero;
  late final TextEditingController _bairro;
  late final TextEditingController _cidade;
  final _numeroFocus = FocusNode();
  String _uf = 'SP';

  bool _buscandoGps = false;
  double? _latGps;
  double? _lonGps;
  double? _precisaoGps;

  _CepStatus _cepStatus = _CepStatus.ocioso;
  Timer? _debounce;

  bool get _gpsAtivo => _latGps != null;

  @override
  void initState() {
    super.initState();
    final ini = widget.inicial;
    _cep        = TextEditingController(text: ini?.cep ?? '');
    _rua        = TextEditingController(text: ini?.rua ?? '');
    _numero     = TextEditingController(text: ini?.numero ?? '');
    _bairro     = TextEditingController(text: ini?.bairro ?? '');
    _cidade     = TextEditingController(text: ini?.cidade ?? '');
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
    _numeroFocus.dispose();
    super.dispose();
  }


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

      case GpsFailure(:final mensagem):
        if (!mounted) return;
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
    rua:        _rua.text.trim(),
    numero:     _numero.text.trim(),
    bairro:     _bairro.text.trim(),
    cidade:     _cidade.text.trim(),
    estado:     _uf,
    cep:        _cep.text.trim(),
    latitude:   _latGps,
    longitude:  _lonGps,
    precisaoMetros: _precisaoGps,
  );


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Localização da ocorrência'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: const [FontSizeControls()],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _GpsCard(
                ativo: _gpsAtivo,
                buscando: _buscandoGps,
                latitude: _latGps,
                longitude: _lonGps,
                precisaoMetros: _precisaoGps,
                enderecoTexto: _locAtual().endereco,
                cidadeUf: _cidade.text.isNotEmpty
                    ? '${_cidade.text}/$_uf'
                    : '',
                onUsarGps: _usarGps,
                onTrocar: _limparGps,
              ),
              const SizedBox(height: 20),

              if (!_gpsAtivo) ...[
                // CEP
                TextFormField(
                  controller: _cep,
                  keyboardType: TextInputType.number,
                  inputFormatters: [_CepInputFormatter()],
                  decoration: InputDecoration(
                    labelText: 'CEP (opcional, autopreenche o endereço)',
                    hintText: '00000-000',
                    prefixIcon: const Icon(Icons.markunread_mailbox_outlined),
                    suffixIcon: _buildCepSuffixIcon(),
                    border: const OutlineInputBorder(),
                  ),
                ),
                if (_cepStatus == _CepStatus.naoEncontrado ||
                    _cepStatus == _CepStatus.semInternet)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 4),
                    child: Text(
                      'CEP não encontrado — preencha abaixo manualmente.',
                      style: TextStyle(fontSize: 12, color: Colors.orange.shade800),
                    ),
                  ),
                const SizedBox(height: 12),

                // Rua + Número
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _rua,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Rua / Avenida *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => (v == null || v.trim().length < 3)
                            ? 'Informe a rua'
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: TextFormField(
                        controller: _numero,
                        focusNode: _numeroFocus,
                        decoration: const InputDecoration(
                          labelText: 'Nº',
                          hintText: 'S/N',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Bairro
                TextFormField(
                  controller: _bairro,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Bairro (opcional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),

                // Cidade + UF
                // Cidade + UF
                Row(children: [
                  Expanded(
                    flex: 5, // Aumentei um pouquinho a proporção para 5:2 para ficar mais seguro
                    child: TextFormField(
                      controller: _cidade,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Cidade *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => (v == null || v.trim().length < 2)
                          ? 'Informe a cidade'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2, // Dei um pixel a mais de respiro para a UF
                    child: DropdownButtonFormField<String>(
                      isExpanded: true, // <-- A MÁGICA QUE TIRA A LINHA VERMELHA FICA AQUI
                      initialValue: _uf,
                      onChanged: (v) => setState(() => _uf = v ?? 'SP'),
                      decoration: const InputDecoration(
                        labelText: 'UF',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 8, vertical: 14), // Diminuí 2px do padding
                      ),
                      items: ufsBrasil
                          .map((u) =>
                          DropdownMenuItem(value: u, child: Text(u)))
                          .toList(),
                    ),
                  ),
                ]),
              ],

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
}


class _GpsCard extends StatelessWidget {
  final bool ativo;
  final bool buscando;
  final double? latitude;
  final double? longitude;
  final double? precisaoMetros;
  final String enderecoTexto;
  final String cidadeUf;
  final VoidCallback onUsarGps;
  final VoidCallback onTrocar;

  const _GpsCard({
    required this.ativo,
    required this.buscando,
    required this.latitude,
    required this.longitude,
    required this.precisaoMetros,
    required this.enderecoTexto,
    required this.cidadeUf,
    required this.onUsarGps,
    required this.onTrocar,
  });

  @override
  Widget build(BuildContext context) {
    if (!ativo) {
      return OutlinedButton.icon(
        onPressed: buscando ? null : onUsarGps,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.blue.shade700,
          side: BorderSide(color: Colors.blue.shade700),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        icon: buscando
            ? const SizedBox(
                width: 18, height: 18,
                child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.gps_fixed),
        label: Text(buscando
            ? 'Obtendo localização exata...'
            : 'Usar minha localização atual (GPS)'),
      );
    }

    final loc = Localizacao(
      rua: '', cidade: '', estado: 'SP',
      latitude: latitude, longitude: longitude,
      precisaoMetros: precisaoMetros,
    );
    final cor = Color(loc.precisaoCor);

    final somenteCoordenadas = enderecoTexto.startsWith('Lat:') ||
        enderecoTexto.startsWith('GPS (') ||
        enderecoTexto.isEmpty;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.08),
        border: Border.all(color: cor.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.gps_fixed, color: cor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(loc.precisaoLabel,
                    style: TextStyle(fontWeight: FontWeight.bold, color: cor, fontSize: 12)),
                const SizedBox(height: 4),
                if (!somenteCoordenadas) ...[
                  Text(enderecoTexto,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600,
                          color: Colors.black87)),
                  if (cidadeUf.isNotEmpty)
                    Text(cidadeUf,
                        style: const TextStyle(fontSize: 12, color: Colors.black54)),
                ] else
                  Text(
                    'Não foi possível identificar o endereço — '
                    'apenas as coordenadas foram capturadas.',
                    style: TextStyle(fontSize: 12, color: Colors.orange.shade800),
                  ),
                const SizedBox(height: 4),
                Text(
                  '${latitude!.toStringAsFixed(5)}, ${longitude!.toStringAsFixed(5)}',
                  style: const TextStyle(fontSize: 11, color: Colors.black45),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onTrocar,
            child: const Text('Trocar'),
          ),
        ],
      ),
    );
  }
}
