import 'dart:convert';

import 'package:inspecao/config/app_config.dart';
import 'package:inspecao/services/api_service.dart';
import 'package:inspecao/services/auth_service.dart';
import 'package:inspecao/services/connectivity_service.dart';
import 'package:inspecao/services/data_service.dart';
import 'package:inspecao/services/database_service.dart';
import 'package:inspecao/services/inspecao_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Orquestra sincronização após trabalho offline (inspeções + fila de respostas).
class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final DatabaseService _db = DatabaseService();

  Future<void> flushPendingRespostaQueue() async {
    final net = ConnectivityService();
    if (!net.isConnected) return;

    await _db.initialize();
    final ops = await _db.getPendingRespostaOpsList();
    if (ops.isEmpty) return;

    final apiService = ApiService();
    if (apiService.baseUrl == null) {
      apiService.initialize(baseUrl: AppConfig.apiBaseUrl);
    }
    final prefs = await SharedPreferences.getInstance();
    final auth = AuthService(apiService, prefs);
    final token = await auth.getAccessToken();
    if (token != null) apiService.setAuthToken(token);

    final inspecao = InspecaoService();

    for (final op in ops) {
      try {
        final localInsp = await _db.getInspectionById(op.inspecaoLocalId);
        if (localInsp == null) {
          await _db.deletePendingRespostaOpById(op.id);
          continue;
        }
        final sid = localInsp.serverId?.trim();
        if (sid == null || sid.isEmpty) {
          continue;
        }

        final payload =
            jsonDecode(op.payloadJson) as Map<String, dynamic>;
        final r = await inspecao.salvarResposta(sid, payload);

        if (op.salvarPlanoAcao && r.id.isNotEmpty) {
          Map<String, dynamic>? extras;
          final raw = op.planoExtrasJson;
          if (raw != null && raw.isNotEmpty) {
            extras = jsonDecode(raw) as Map<String, dynamic>;
          }
          await inspecao.completarPlanoAcaoParaRespostaSync(
            respostaId: r.id,
            observacoes: extras?['observacoesPlanoAcao']?.toString() ?? '',
            evidenciasPaths: (extras?['evidenciasPlanoAcao'] as List?)
                    ?.cast<String>() ??
                [],
            anexosServidorRemovidosIds:
                (extras?['anexosPlanoServidorRemovidosIds'] as List?)
                        ?.cast<String>() ??
                    [],
          );
        }

        await _db.deletePendingRespostaOpById(op.id);
      } catch (e) {
        print('⚠️ [SyncService] fila resposta op ${op.id}: $e');
      }
    }
  }

  Future<PendingSyncOverview> runFullPendingSync({
    PendingInspectionConflictPolicy inspectionConflicts =
        PendingInspectionConflictPolicy.uploadLocal,
  }) async {
    await _db.initialize();
    if (!ConnectivityService().isConnected) {
      return loadPendingOverview();
    }
    try {
      await DataService().syncPendingInspections(onConflict: inspectionConflicts);
    } catch (e) {
      print('⚠️ [SyncService] syncPendingInspections: $e');
    }
    try {
      await flushPendingRespostaQueue();
    } catch (e) {
      print('⚠️ [SyncService] flushPendingRespostaQueue: $e');
    }
    return loadPendingOverview();
  }

  Future<PendingSyncOverview> loadPendingOverview() async {
    await _db.initialize();
    final inspections = await DataService().getPendingSyncInspections();
    final queue = await _db.countPendingRespostaOps();
    return PendingSyncOverview(
      pendingInspections: inspections.length,
      queuedRespostas: queue,
      inspectionTitles: inspections.map((e) => e.titulo).toList(),
    );
  }
}

class PendingSyncOverview {
  final int pendingInspections;
  final int queuedRespostas;
  final List<String> inspectionTitles;

  PendingSyncOverview({
    required this.pendingInspections,
    required this.queuedRespostas,
    required this.inspectionTitles,
  });

  int get totalItems => pendingInspections + queuedRespostas;
}
