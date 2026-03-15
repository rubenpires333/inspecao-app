import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Logger global que escreve simultaneamente para:
///  - console (debugPrint)
///  - ficheiro em <DocumentsDir>/logs/inspecao_app_YYYY-MM-DD.log
///
/// Caminho real no dispositivo/emulador:
///   Android: /data/data/com.example.inspecao/files/logs/inspecao_app_YYYY-MM-DD.log
///   Windows: C:\Users\User\AppData\Roaming\com.example.inspecao\logs\...
///
/// Para aceder aos logs no PC Windows (via repositório ligado ao projeto):
///   c:\xampp\htdocs\SIGIV\inspecao-app\inspecao\logs\
///   → O AppLogger tenta escrever aqui quando corre em Windows (modo desktop).
class AppLogger {
  AppLogger._();

  static IOSink? _sink;
  static File? _file;
  static bool _initializing = false;
  static bool _initialized = false;

  // ── Caminho do log no desktop Windows (pasta do projecto) ─────────────────
  static const String _windowsLogDir =
      r'c:\xampp\htdocs\SIGIV\inspecao-app\inspecao\logs';

  // ── Inicialização lazy ────────────────────────────────────────────────────

  static Future<void> _init() async {
    if (_initialized || _initializing) return;
    _initializing = true;
    try {
      Directory logDir;

      if (!kIsWeb && Platform.isWindows) {
        // Desktop Windows: usar directamente a pasta do projecto
        logDir = Directory(_windowsLogDir);
      } else if (!kIsWeb) {
        // Android / iOS: usar documentos do app
        final docs = await getApplicationDocumentsDirectory();
        logDir = Directory('${docs.path}/logs');
      } else {
        // Web: sem acesso a ficheiros
        _initialized = true;
        _initializing = false;
        return;
      }

      if (!logDir.existsSync()) {
        logDir.createSync(recursive: true);
      }

      final today = _dateStamp();
      _file = File('${logDir.path}/inspecao_app_$today.log');
      _sink = _file!.openWrite(mode: FileMode.append);

      _initialized = true;
      _initializing = false;

      // Primeira linha do ficheiro
      _writeLine('══════════════════════════════════════════════════════');
      _writeLine('  InspecaoApp  –  sessão iniciada em ${DateTime.now().toIso8601String()}');
      _writeLine('  Ficheiro: ${_file!.path}');
      _writeLine('══════════════════════════════════════════════════════');
    } catch (e) {
      _initializing = false;
      debugPrint('⚠️ AppLogger._init falhou: $e');
    }
  }

  // ── API pública ───────────────────────────────────────────────────────────

  /// Regista uma mensagem no console e no ficheiro de log.
  static void log(String message) {
    final line = '[${_timeStamp()}] $message';
    debugPrint(line);
    _writeAsync(line);
  }

  /// Regista um erro com stack trace opcional.
  static void error(String message, [Object? error, StackTrace? stack]) {
    log('❌ $message${error != null ? ' | error=$error' : ''}');
    if (stack != null) {
      log('   StackTrace:\n$stack');
    }
  }

  /// Fecha o sink (chamar no final da sessão, se necessário).
  static Future<void> close() async {
    await _sink?.flush();
    await _sink?.close();
    _sink = null;
    _initialized = false;
  }

  // ── Helpers internos ─────────────────────────────────────────────────────

  static void _writeAsync(String line) {
    if (!_initialized) {
      // Inicializar em background e retentar
      _init().then((_) => _writeLine(line));
    } else {
      _writeLine(line);
    }
  }

  static void _writeLine(String line) {
    try {
      _sink?.writeln(line);
    } catch (_) {
      // Silencioso – não queremos que erros de log rebentem a app
    }
  }

  static String _dateStamp() {
    final n = DateTime.now();
    return '${n.year.toString().padLeft(4, '0')}-'
        '${n.month.toString().padLeft(2, '0')}-'
        '${n.day.toString().padLeft(2, '0')}';
  }

  static String _timeStamp() {
    final n = DateTime.now();
    return '${n.hour.toString().padLeft(2, '0')}:'
        '${n.minute.toString().padLeft(2, '0')}:'
        '${n.second.toString().padLeft(2, '0')}.'
        '${n.millisecond.toString().padLeft(3, '0')}';
  }
}