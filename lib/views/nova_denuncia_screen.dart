import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/localizacao.dart';
import '../services/denuncia_service.dart';
import '../services/auth_service.dart';
import '../services/localizacao_service.dart';

class NovaDenunciaScreen extends StatefulWidget {
  const NovaDenunciaScreen({super.key});

  @override
  State<NovaDenunciaScreen> createState() => _NovaDenunciaScreenState();
}

class _NovaDenunciaScreenState extends State<NovaDenunciaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descricaoController = TextEditingController();
  final _localController = TextEditingController();
  String _tipoSelecionado = 'Maus-tratos';
  bool _carregandoLocal = false;

  final _tipos = [
    'Maus-tratos',
    'Abandono',
    'Tráfico de animais',
    'Caça ilegal',
    'Poluicão ambiental',
    'Desmatamento',
    'Outro',
  ];

  Future<void> _obterLocalizacao() async {
    setState(() => _carregandoLocal = true);
    final service = LocalizacaoService();
    final result = await service.obterLocalizacaoAtual();
    setState(() {
      _carregandoLocal = false;
      if (result.containsKey('endereco')) {
        _localController.text = result['endereco'];
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['erro'] ?? 'Erro ao obter localizacao')),
        );
      }
    });
  }

  void _enviar() {
    if (_formKey.currentState!.validate()) {
      final auth = Provider.of<AuthService>(context, listen: false);
      final denunciaService = Provider.of<DenunciaService>(context, listen: false);

      denunciaService.criarDenuncia(
        descricao: _descricaoController.text,
        tipo: _tipoSelecionado,
        localizacao: Localizacao(endereco: _localController.text, latitude: 0, longitude: 0),
        usuarioId: auth.usuarioLogado!.id,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Denuncia registrada com sucesso!')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nova Denuncia')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _tipoSelecionado,
                decoration: const InputDecoration(labelText: 'Tipo de Ocorrencia'),
                items: _tipos.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) => setState(() => _tipoSelecionado = v!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descricaoController,
                decoration: const InputDecoration(labelText: 'Descricao', hintText: 'Descreva o que voce observou...'),
                maxLines: 4,
                validator: (v) => v == null || v.isEmpty ? 'Informe a descricao' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _localController,
                      decoration: const InputDecoration(labelText: 'Localizacao'),
                      validator: (v) => v == null || v.isEmpty ? 'Informe a localizacao' : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _carregandoLocal ? null : _obterLocalizacao,
                    icon: _carregandoLocal
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.my_location),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _enviar,
                icon: const Icon(Icons.send),
                label: const Text('Enviar Denuncia'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
