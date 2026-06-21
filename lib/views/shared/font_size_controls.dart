import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:provider/provider.dart';
import '../../services/font_scale_service.dart';

/// Par de botões "T-" / "T+" para ajuste de tamanho de fonte, pensado para
/// ser usado dentro do `actions` de um [AppBar].
///
/// Lê a cor do [IconTheme] ambiente para herdar automaticamente o
/// `foregroundColor` definido em cada AppBar (garantindo contraste correto
/// em qualquer tela), e mantém o próprio rótulo com tamanho fixo
/// (`TextScaler.noScaling`) para não distorcer o layout do cabeçalho
/// conforme a fonte do app aumenta.
class FontSizeControls extends StatelessWidget {
  const FontSizeControls({super.key});

  @override
  Widget build(BuildContext context) {
    final fontScale = context.watch<FontScaleService>();
    final corBase = IconTheme.of(context).color ?? Colors.white;

    return Semantics(
      container: true,
      label: 'Ajuste de tamanho da fonte',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _BotaoFonte(
            label: 'T−',
            tooltip: 'Diminuir tamanho da fonte',
            cor: corBase,
            onPressed: fontScale.podeDiminuir
                ? () {
              fontScale.diminuir();
              SemanticsService.sendAnnouncement(
                View.of(context),
                'Fonte diminuída',
                Directionality.of(context),
              );
            }
                : null,
          ),
          _BotaoFonte(
            label: 'T+',
            tooltip: 'Aumentar tamanho da fonte',
            cor: corBase,
            onPressed: fontScale.podeAumentar
                ? () {
              fontScale.aumentar();
              SemanticsService.sendAnnouncement(
                View.of(context),
                'Fonte aumentada',
                Directionality.of(context),
              );
            }
                : null,
          ),
        ],
      ),
    );
  }
}

class _BotaoFonte extends StatelessWidget {
  final String label;
  final String tooltip;
  final Color cor;
  final VoidCallback? onPressed;

  const _BotaoFonte({
    required this.label,
    required this.tooltip,
    required this.cor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final habilitado = onPressed != null;

    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        enabled: habilitado,
        label: tooltip,
        child: InkResponse(
          onTap: onPressed,
          radius: 24,
          containedInkWell: true,
          child: Container(
            constraints: const BoxConstraints(minWidth: 40, minHeight: 48),
            alignment: Alignment.center,
            child: MediaQuery(
              // Mantém o rótulo do botão num tamanho estável, independente
              // do fator de escala que ele próprio controla.
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.noScaling),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: cor.withValues(alpha: habilitado ? 1.0 : 0.4),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
