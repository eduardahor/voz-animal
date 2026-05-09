import 'package:flutter_test/flutter_test.dart';
import 'package:voz_animal/main.dart';
import 'package:voz_animal/models/localizacao.dart';
import 'package:voz_animal/models/tipo_ocorrencia.dart';
import 'package:voz_animal/models/tipo_usuario.dart';
import 'package:voz_animal/services/auth_service.dart';
import 'package:voz_animal/services/denuncia_service.dart';

Localizacao _locValida() => Localizacao(
      endereco: 'Rua das Flores, 123',
      cidade: 'São Paulo',
      estado: 'SP',
      cep: '01310-100',
    );

void main() {
  group('Localizacao', () {
    test('endereço válido passa', () {
      expect(_locValida().valido(), isTrue);
    });
    test('CEP inválido falha', () {
      final l = _locValida()..cep = '123';
      expect(l.valido(), isFalse);
    });
    test('UF inválida falha', () {
      final l = _locValida()..estado = 'XX';
      expect(l.valido(), isFalse);
    });
    test('endereço sem número falha', () {
      final l = _locValida()..endereco = 'Rua sem numero';
      expect(l.valido(), isFalse);
    });
  });

  group('DenunciaService', () {
    test('rejeita criação sem localização válida', () {
      final svc = DenunciaService();
      final locInvalida = Localizacao(
          endereco: 'x', cidade: 'a', estado: 'XX', cep: '0');
      expect(
        () => svc.criar(
          usuarioId: 'u1',
          descricao: 'Descrição com mais de vinte caracteres aqui.',
          tipo: TipoOcorrencia.abandono,
          localizacao: locInvalida,
        ),
        throwsArgumentError,
      );
    });

    test('rejeita descrição curta', () {
      final svc = DenunciaService();
      expect(
        () => svc.criar(
          usuarioId: 'u1',
          descricao: 'curta',
          tipo: TipoOcorrencia.abandono,
          localizacao: _locValida(),
        ),
        throwsArgumentError,
      );
    });

    test('cria denúncia válida e atualiza estatísticas', () {
      final svc = DenunciaService();
      svc.criar(
        usuarioId: 'u1',
        descricao: 'Animal abandonado em via pública há 3 dias.',
        tipo: TipoOcorrencia.abandono,
        localizacao: _locValida(),
      );
      expect(svc.todas.length, 1);
      expect(svc.estatisticasPorStatus().values.reduce((a, b) => a + b), 1);
    });

    test('apenas órgão pode alterar status', () async {
      final auth = AuthService();
      final svc = DenunciaService();
      await auth.login(
          email: 'a@a.com', senha: '1234', tipoEsperado: TipoUsuario.cidadao);
      final d = svc.criar(
        usuarioId: auth.usuarioAtual!.id,
        descricao: 'Animal abandonado em via pública há 3 dias.',
        tipo: TipoOcorrencia.abandono,
        localizacao: _locValida(),
      );
      expect(
        () => svc.alterarStatus(
            solicitante: auth.usuarioAtual!,
            denunciaId: d.id,
            novo: d.status),
        throwsStateError,
      );
    });
  });

  testWidgets('App inicializa na tela de escolha de perfil',
      (tester) async {
    await tester.pumpWidget(const VozAnimalApp());
    await tester.pumpAndSettle();
    expect(find.text('Voz Animal'), findsOneWidget);
    expect(find.text('Sou Cidadão'), findsOneWidget);
    expect(find.text('Sou Órgão Responsável'), findsOneWidget);
  });
}
