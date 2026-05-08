import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Copia uma foto/ficheiro escolhido para pasta estável da app (sobrevive a limpezas de cache temporário).
Future<String> persistChecklistItemEvidence({
  required XFile file,
  required String inspecaoLocalId,
}) async {
  final root = await getApplicationDocumentsDirectory();
  final folder = Directory(
    p.join(root.path, 'checklist_item_evidence', inspecaoLocalId),
  );
  await folder.create(recursive: true);

  final ext = p.extension(file.path).toLowerCase();
  final base =
      p.basenameWithoutExtension(file.path).replaceAll(RegExp(r'[^\w.\-]'), '_');
  final name =
      '${DateTime.now().millisecondsSinceEpoch}_${base.isEmpty ? 'file' : base}$ext';
  final destPath = p.join(folder.path, name);

  final src = File(file.path);
  if (!await src.exists()) {
    throw Exception('Ficheiro de origem não encontrado: ${file.path}');
  }
  await src.copy(destPath);
  return destPath;
}

/// Indica se o caminho parece imagem (tipo MIME «FOTO» vs «DOCUMENTO» na API).
String tipoAnexoInspecaoParaCaminhoLocal(String path) {
  final lower = path.toLowerCase();
  const imgs = ['.jpg', '.jpeg', '.png', '.webp', '.gif', '.heic', '.bmp'];
  for (final e in imgs) {
    if (lower.endsWith(e)) return 'FOTO';
  }
  return 'DOCUMENTO';
}
