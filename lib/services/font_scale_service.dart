import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kFontScaleKey = 'pref_font_scale';

/// Controla o fator de escala de fonte definido pelo usuário (acessibilidade),
/// permitindo aumentar/diminuir o texto do app em incrementos fixos,
/// de forma independente da configuração de fonte do sistema operacional.
///
/// O valor é persistido localmente para que a preferência do usuário
/// seja mantida entre sessões do app.
class FontScaleService extends ChangeNotifier {
  FontScaleService() {
    _restaurarPreferencia();
  }

  static const double min = 0.85;
  static const double max = 1.45;
  static const double step = 0.15;
  static const double padrao = 1.0;

  double _scale = padrao;

  double get scale => _scale;

  /// Nível atual em relação ao padrão, útil para exibir feedback (ex.: "A").
  int get nivel => ((_scale - padrao) / step).round();

  bool get podeDiminuir => _scale > min + 0.001;
  bool get podeAumentar => _scale < max - 0.001;
  bool get noPadrao => (_scale - padrao).abs() < 0.001;

  Future<void> _restaurarPreferencia() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final salvo = prefs.getDouble(_kFontScaleKey);
      if (salvo != null) {
        _scale = salvo.clamp(min, max);
        notifyListeners();
      }
    } catch (_) {
      // Se a leitura da preferência falhar, mantém o tamanho padrão.
    }
  }

  Future<void> aumentar() => _alterarPara(_scale + step);

  Future<void> diminuir() => _alterarPara(_scale - step);

  Future<void> redefinir() => _alterarPara(padrao);

  Future<void> _alterarPara(double novoValor) async {
    final novaEscala = novoValor.clamp(min, max);
    if ((novaEscala - _scale).abs() < 0.001) return;

    _scale = novaEscala;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_kFontScaleKey, _scale);
    } catch (_) {

    }
  }
}
