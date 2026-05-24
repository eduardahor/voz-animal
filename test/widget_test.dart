import 'package:flutter_test/flutter_test.dart';
import 'package:voz_animal/models/localizacao.dart';
import 'package:voz_animal/models/status_denuncia.dart';


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


  group('StatusDenuncia', () {
    test('serialização e desserialização são inversas', () {
      for (final s in StatusDenuncia.values) {
        expect(
          StatusDenunciaX.fromFirestore(s.firestoreValue),
          equals(s),
        );
      }
    });

    test('transições válidas de emAnalise', () {
      expect(
        StatusDenuncia.emAnalise.transicoesPermitidas,
        containsAll([StatusDenuncia.emAndamento, StatusDenuncia.recusada]),
      );
    });

    test('transições válidas de emAndamento', () {
      expect(
        StatusDenuncia.emAndamento.transicoesPermitidas,
        containsAll([StatusDenuncia.resolvida, StatusDenuncia.recusada]),
      );
    });

    test('aberta não permite transição direta por órgão', () {
      expect(StatusDenuncia.aberta.transicoesPermitidas, isEmpty);
    });

    test('podeTansicionarPara retorna false para transição inválida', () {
      expect(
        StatusDenuncia.aberta.podeTansicionarPara(StatusDenuncia.resolvida),
        isFalse,
      );
    });
  });


  group('Localizacao serialização', () {
    test('toMap e fromMap são inversos', () {
      final original = _locValida();
      final restaurado = Localizacao.fromMap(original.toMap());
      expect(restaurado.endereco, equals(original.endereco));
      expect(restaurado.cidade,   equals(original.cidade));
      expect(restaurado.estado,   equals(original.estado));
      expect(restaurado.cep,      equals(original.cep));
    });
  });

  // Nota: testes de DenunciaService/Repository e widget tests de integração
  // com Firebase usar FakeFirebaseFirestore (package fake_cloud_firestore)
  // ou mocks. Esses testes foram separados para não exigir Firebase inicializado.
}
