import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/denuncia.dart';
import '../../models/tipo_ocorrencia.dart';
import '../../services/auth_service.dart';
import '../../services/denuncia_service.dart';
import '../foto_denuncia.dart';
import '../shared/badges.dart';
import '../usuario/perfil_screen.dart';
import 'detalhe_denuncia_orgao_screen.dart';
import 'relatorios_screen.dart';

class HomeOrgaoScreen extends StatefulWidget {
  const HomeOrgaoScreen({super.key});

  @override
  State<HomeOrgaoScreen> createState() => _HomeOrgaoScreenState();
}

class _HomeOrgaoScreenState extends State<HomeOrgaoScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DenunciaService>().resetarExpiradas();
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final svc = context.read<DenunciaService>();
    final orgaoId = auth.usuarioAtual!.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Painel do Órgão'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Relatórios',
            icon: const Icon(Icons.assessment),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const RelatoriosScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            tooltip: 'Meu Perfil',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const PerfilScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: auth.logout,
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.inbox_outlined), text: 'Abertas'),
            Tab(icon: Icon(Icons.task_alt), text: 'Minhas'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          // Aba 1 — denúncias abertas (pool compartilhado)
          _ListaDenuncias(
            stream: svc.abertas(),
            orgaoId: orgaoId,
            orgaoNome: auth.usuarioAtual!.nome,
            emptyMsg: 'Nenhuma denúncia aberta no momento.',
          ),

          // Aba 2 — denúncias assumidas por este órgão
          _ListaDenuncias(
            stream: svc.doOrgao(orgaoId),
            orgaoId: orgaoId,
            orgaoNome: auth.usuarioAtual!.nome,
            emptyMsg: 'Você ainda não assumiu nenhuma denúncia.',
          ),
        ],
      ),
    );
  }
}


class _ListaDenuncias extends StatelessWidget {
  final Stream<List<Denuncia>> stream;
  final String orgaoId;
  final String orgaoNome;
  final String emptyMsg;

  const _ListaDenuncias({
    required this.stream,
    required this.orgaoId,
    required this.orgaoNome,
    required this.emptyMsg,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Denuncia>>(
      stream: stream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('Erro: ${snap.error}'));
        }
        final lista = snap.data ?? [];
        if (lista.isEmpty) {
          return Center(
            child: Text(emptyMsg,
                style: const TextStyle(color: Colors.black54)),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(8),
          itemCount: lista.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) => _CardDenuncia(
            denuncia: lista[i],
            orgaoId: orgaoId,
            orgaoNome: orgaoNome,
          ),
        );
      },
    );
  }
}


class _CardDenuncia extends StatelessWidget {
  final Denuncia denuncia;
  final String orgaoId;
  final String orgaoNome;

  const _CardDenuncia({
    required this.denuncia,
    required this.orgaoId,
    required this.orgaoNome,
  });

  @override
  Widget build(BuildContext context) {
    final d = denuncia;
    final bloqueado = d.orgaoEstaBloqueado(orgaoId);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetalheDenunciaOrgaoScreen(
              denuncia: d,
              orgaoId: orgaoId,
              orgaoNome: orgaoNome,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FotoDenuncia(path: d.fotoUrl, width: 60, height: 60),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(d.tipo.label,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(d.descricao,
                        maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.black54,
                            fontSize: 13)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      children: [
                        StatusBadge(d.status),
                        UrgenciaBadge(d.urgencia),
                        if (bloqueado)
                          const Chip(
                            label: Text('Bloqueado',
                                style: TextStyle(fontSize: 11)),
                            backgroundColor: Color(0xFFFFE0E0),
                            visualDensity: VisualDensity.compact,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.black38),
            ],
          ),
        ),
      ),
    );
  }
}
