import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/tipo_ocorrencia.dart';
import '../models/localizacao.dart';
import '../services/auth_service.dart';
import '../services/denuncia_service.dart';

class NovaDenunciaScreen extends StatefulWidget {
  const NovaDenunciaScreen({super.key});

  @override
  State<NovaDenunciaScreen> createState() => _NovaDenunciaScreenState();
}

class _NovaDenunciaScreenState extends State<NovaDenunciaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descricaoController = TextEditingController();
  TipoOcorrencia _tipoSelecionado = TipoOcorrencia.abandono;
  bool _isLoading = false;
  bool _fotoAnexada = false;

  @override
  void dispose() {
    _descricaoController.dispose();
    super.dispose();
  }

  Future<void> _criarDenuncia() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final auth = context.read<AuthService>();
      final denunciaService = context.read<DenunciaService>();

      await denunciaService.criarDenuncia(
        descricao: _descricaoController.text.trim(),
        tipoOcorrencia: _tipoSelecionado,
        usuarioId: auth.usuarioLogado!.id,
        nomeUsuario: auth.usuarioLogado!.nome,
        localizacao: Localizacao.simulada(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Denúncia registrada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: \${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nova Denúncia')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Tipo de ocorrência
                const Text(
                  'Tipo de Ocorrência',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<TipoOcorrencia>(
                  value: _tipoSelecionado,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: TipoOcorrencia.values.map((tipo) {
                    return DropdownMenuItem(
                      value: tipo,
                      child: Text(tipo.descricao),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _tipoSelecionado = value);
                  },
                ),
                const SizedBox(height: 20),
                // Descrição
                const Text(
                  'Descrição',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descricaoController,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    hintText: 'Descreva a situação com o máximo de detalhes...',
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Informe a descrição';
                    if (v.length < 10) return 'Descrição muito curta';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                // Foto (simulada)
                const Text(
                  'Foto',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => setState(() => _fotoAnexada = !_fotoAnexada),
                  child: Container(
                    height: 150,
                    decoration: BoxDecoration(
                      color: _fotoAnexada
                          ? Colors.green.shade50
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _fotoAnexada ? Colors.green : Colors.grey.shade300,
                        width: 2,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _fotoAnexada ? Icons.check_circle : Icons.camera_alt_outlined,
                            size: 40,
                            color: _fotoAnexada ? Colors.green : Colors.grey,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _fotoAnexada
                                ? 'Foto anexada (simulada)'
                                : 'Toque para anexar foto',
                            style: TextStyle(
                              color: _fotoAnexada ? Colors.green : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Localização (simulada)
                const Text(
                  'Localização',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.blue.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              Localizacao.simulada().endereco,
                              style: TextStyle(color: Colors.blue.shade900),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Localização simulada',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue.shade400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isLoading ? null : _criarDenuncia,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Registrar Denúncia',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
