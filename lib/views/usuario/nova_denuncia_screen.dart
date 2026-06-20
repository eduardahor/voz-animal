import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/tipo_ocorrencia.dart';
import '../../models/localizacao.dart';
import '../../services/auth_service.dart';
import '../../services/denuncia_service.dart';
import '../../services/foto_service.dart';
import '../foto_denuncia.dart';
import 'selecionar_localizacao_screen.dart';

class NovaDenunciaScreen extends StatefulWidget {
  const NovaDenunciaScreen({super.key});

  @override
  State<NovaDenunciaScreen> createState() => _NovaDenunciaScreenState();
}

class _NovaDenunciaScreenState extends State<NovaDenunciaScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _descricao = TextEditingController();
  TipoOcorrencia? _tipo;
  Localizacao?    _localizacao;
  String?         _fotoUrl;
  bool            _salvando = false;

  final _fotoService = FotoService();

  bool get _formValido =>
      _descricao.text.trim().length >= 20 &&
      _tipo != null &&
      _localizacao != null &&
      _localizacao!.valido();

  @override
  void dispose() {
    _descricao.dispose();
    super.dispose();
  }

  Future<void> _escolherFoto() async {
    final origem = await showModalBottomSheet<bool>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Tirar foto'),
              onTap: () => Navigator.pop(context, true),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Escolher da galeria'),
              onTap: () => Navigator.pop(context, false),
            ),
          ],
        ),
      ),
    );
    if (origem == null) return;
    final path = await _fotoService.capturarOuSelecionar(camera: origem);
    if (path != null) setState(() => _fotoUrl = path);
  }

  Future<void> _escolherLocal() async {
    final loc = await Navigator.push<Localizacao>(
      context,
      MaterialPageRoute(
          builder: (_) =>
              SelecionarLocalizacaoScreen(inicial: _localizacao)),
    );
    if (loc != null) setState(() => _localizacao = loc);
  }

  Future<void> _salvar() async {
    final faltando = <String>[];
    if (_descricao.text.trim().length < 20) {
      faltando.add('Descrição (mín. 20 caracteres)');
    }
    if (_tipo == null) faltando.add('Tipo de ocorrência');
    if (_localizacao == null || !_localizacao!.valido()) {
      faltando.add('Localização válida');
    }
    if (!_formKey.currentState!.validate() || faltando.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Faltam: ${faltando.join(", ")}')),
      );
      return;
    }

    setState(() => _salvando = true);
    try {
      final usuario = context.read<AuthService>().usuarioAtual!;
      await context.read<DenunciaService>().criar(
            usuarioId:   usuario.id,
            descricao:   _descricao.text,
            tipo:        _tipo!,
            localizacao: _localizacao!,
            fotoUrl:     _fotoUrl,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Denúncia registrada com sucesso!')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e')),
      );
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nova Denúncia'),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Foto da ocorrência (opcional)',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _escolherFoto,
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: _fotoUrl == null
                      ? Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade400),
                          ),
                          child: const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add_a_photo,
                                    size: 40, color: Colors.black54),
                                SizedBox(height: 8),
                                Text('Toque para adicionar foto'),
                              ],
                            ),
                          ),
                        )
                      : FotoDenuncia(path: _fotoUrl),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Tipo de ocorrência *',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<TipoOcorrencia>(
                initialValue: _tipo,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Selecione o tipo',
                ),
                items: TipoOcorrencia.values
                    .map((t) =>
                        DropdownMenuItem(value: t, child: Text(t.label)))
                    .toList(),
                onChanged: (v) => setState(() => _tipo = v),
                validator: (v) =>
                    v == null ? 'Selecione um tipo' : null,
              ),
              if (_tipo != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    border: Border.all(color: Colors.amber.shade200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline,
                          color: Colors.amber, size: 20),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_tipo!.descricao)),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),

              const Text('Descrição *',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descricao,
                maxLines: 5,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Descreva o que aconteceu, se útil, um ponto de referência do local.',
                ),
                validator: (v) => (v == null || v.trim().length < 20)
                    ? 'Mínimo de 20 caracteres'
                    : null,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 24),

              const Text('Localização *',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: Icon(
                    _localizacao?.temGps == true
                        ? Icons.gps_fixed
                        : Icons.location_on,
                    color: _localizacao == null
                        ? Colors.grey
                        : _localizacao!.temGps
                            ? Color(_localizacao!.precisaoCor)
                            : Colors.green.shade700,
                  ),
                  title: Text(_localizacao?.endereco ??
                      'Toque para definir o local'),
                  subtitle: _localizacao != null
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_localizacao!.cidade.isNotEmpty)
                              Text('${_localizacao!.cidade}/'
                                  '${_localizacao!.estado}'
                                  '${_localizacao!.cep.isNotEmpty ? " — CEP ${_localizacao!.cep}" : ""}'),
                            if (_localizacao!.temGps)
                              Text(
                                _localizacao!.precisaoLabel,
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Color(_localizacao!.precisaoCor),
                                    fontWeight: FontWeight.w600),
                              ),
                          ],
                        )
                      : null,
                  isThreeLine: _localizacao?.temGps == true,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _escolherLocal,
                ),
              ),
              const SizedBox(height: 32),

              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  disabledBackgroundColor: Colors.grey.shade400,
                ),
                onPressed: (!_formValido || _salvando) ? null : _salvar,
                icon: _salvando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                label: const Text('REGISTRAR DENÚNCIA',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
