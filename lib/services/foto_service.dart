import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

/* Serviço de captura/seleção de foto.
Em web ou desktop sem suporte, retorna o caminho do placeholder. */
class FotoService {
  static const String placeholderAsset = 'assets/placeholder_denuncia.png';

  final ImagePicker _picker = ImagePicker();

  Future<String?> capturarOuSelecionar({bool camera = false}) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: camera ? ImageSource.camera : ImageSource.gallery,
        imageQuality: 75,
      );
      if (file == null) return null;
      return file.path;
    } catch (e) {
      debugPrint('FotoService modo simulado: $e');
      return placeholderAsset;
    }
  }

  static bool isPlaceholder(String? path) =>
      path != null && path == placeholderAsset;
}
