import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:inspecao/models/inspection.dart';
import 'package:inspecao/models/inspector.dart';
import 'package:inspecao/models/user.dart';
import 'package:inspecao/models/evidence.dart';
import 'package:inspecao/models/notification.dart';
import 'package:inspecao/models/action_plan.dart';
import 'package:inspecao/models/establishment.dart';
import 'package:inspecao/services/auth_service.dart';
import 'package:inspecao/services/api_service.dart';
import 'package:inspecao/services/database_service.dart';
import 'package:inspecao/database/database.dart' as db;
import 'package:inspecao/config/app_config.dart';
import 'package:inspecao/exceptions/forced_logout_exception.dart';

class DataService {
  static const String _inspectionsKey = 'inspections';
  static const String _inspectorsKey = 'inspectors';
  static const String _currentUserKey = 'current_user';
  static const String _evidencesKey = 'evidences';
  static const String _notificationsKey = 'notifications';
  static const String _actionPlansKey = 'action_plans';

  // Singleton
  static final DataService _instance = DataService._internal();
  factory DataService() => _instance;
  DataService._internal();

  // Serviço de banco de dados local
  final DatabaseService _dbService = DatabaseService();
  bool _dbInitialized = false;

  /// Inicializa o banco de dados local
  Future<void> _ensureDbInitialized() async {
    if (!_dbInitialized) {
      await _dbService.initialize();
      _dbInitialized = true;
    }
  }

  /// Trata erros HTTP e força logout em caso de 403
  Future<void> _handleHttpError(DioException e) async {
    if (e.response?.statusCode == 403 || e.response?.statusCode == 401) {
      // Forçar logout em caso de acesso negado
      final apiService = ApiService();
      final prefs = await SharedPreferences.getInstance();
      final authService = AuthService(apiService, prefs);
      await authService.logout();
      throw ForcedLogoutException('Sessão expirada. Faça login novamente.');
    }
  }

  // Métodos de Inspeções - Estratégia OFFLINE-FIRST
  // 1. Busca do banco local primeiro (sempre disponível)
  // 2. Sincroniza com API em background (quando online)
  // 3. Atualiza banco local com dados do servidor
  Future<List<Inspection>> getInspections() async {
    await _ensureDbInitialized();
    
    // PASSO 1: Buscar do banco local primeiro (offline-first)
    List<Inspection> localInspections = [];
    try {
      localInspections = await _dbService.getInspections();
    } catch (e) {
      print('Erro ao buscar inspeções do banco local: $e');
    }
    
    // PASSO 2: Tentar sincronizar com API (se online)
    try {
      final apiService = ApiService();
      if (apiService.baseUrl == null) {
        apiService.initialize(baseUrl: AppConfig.apiBaseUrl);
      }
      
      // Adicionar token de autenticação se disponível
      final authService = AuthService(apiService, await SharedPreferences.getInstance());
      final token = await authService.getAccessToken();
      if (token != null) {
        apiService.setAuthToken(token);
      }
      
      // Buscar inspeções da API (mesmo critério que /minhas — ver MobileInspecaoController)
      final data = await apiService.getInspecoesAtivas();

      if (data.isNotEmpty) {
        // Converter resposta da API para formato do modelo
        final apiInspections = data.map((json) {
        return Inspection.fromJson(_mapApiResponseToInspection(json));
      }).toList();
      
        // PASSO 3: Salvar no banco local (espelho do servidor)
        // As inspeções já vêm com isSynced=true e serverId da API no mapeamento
        print('💾 Salvando ${apiInspections.length} inspeções no banco local...');
        await _dbService.saveInspections(apiInspections);
        print('✅ ${apiInspections.length} inspeções salvas no banco local');
        
        // Retornar dados atualizados do banco local
        return await _dbService.getInspections();
      }

      // Lista vazia com sucesso: alinhar SQLite ao servidor (senão ficam linhas de outro utilizador)
      final removed = await _dbService.softDeleteServerMirroredInspections();
      print(
          '📭 GET /api/v1/mobile/inspecoes/ativas retornou []; espelho limpo ($removed removidas).');
      final refreshed = await _dbService.getInspections();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _inspectionsKey,
        json.encode(refreshed.map((i) => i.toJson()).toList()),
      );
      return refreshed;
    } on DioException catch (e) {
      // Se erro de rede, retornar dados locais (modo offline)
      print('Erro ao sincronizar com API: ${e.message} - usando dados locais');
      if (localInspections.isNotEmpty) {
        return localInspections;
      }
      // Se não houver dados locais e for erro de autenticação, tratar
      await _handleHttpError(e);
      throw Exception('Erro ao buscar inspeções: ${e.message}');
    } catch (e) {
      // Outros erros: retornar dados locais se disponíveis
      print('Erro ao sincronizar: $e - usando dados locais');
      if (localInspections.isNotEmpty) {
        return localInspections;
      }
      throw Exception('Erro ao buscar inspeções: $e');
    }
  }
  
  // Mapear resposta da API para formato do modelo
  Map<String, dynamic> _mapApiResponseToInspection(Map<String, dynamic> apiData) {
    // O backend retorna campos em camelCase (Jackson serializa assim)
    // Mapear campos do backend para o modelo local
    final numeroInspecao = apiData['numeroInspecao']?.toString() ?? '';
    final estabelecimento = apiData['estabelecimento'] as Map<String, dynamic>?;
    final estabelecimentoNome = estabelecimento?['nome']?.toString() ?? '';
    
    // Criar título baseado no número da inspeção e nome do estabelecimento
    final titulo = estabelecimentoNome.isNotEmpty 
        ? 'Inspeção $numeroInspecao - $estabelecimentoNome'
        : 'Inspeção $numeroInspecao';
    
    // Converter dataInspecao (LocalDate) para DateTime
    DateTime? dataAgendada;
    if (apiData['dataInspecao'] != null) {
      if (apiData['dataInspecao'] is String) {
        dataAgendada = DateTime.tryParse(apiData['dataInspecao']);
      } else if (apiData['dataInspecao'] is Map) {
        // Formato LocalDate do Java: {"year": 2024, "month": 1, "day": 15}
        final dateMap = apiData['dataInspecao'] as Map<String, dynamic>;
        final year = dateMap['year'] as int? ?? DateTime.now().year;
        final month = dateMap['month'] as int? ?? DateTime.now().month;
        final day = dateMap['day'] as int? ?? DateTime.now().day;
        dataAgendada = DateTime(year, month, day);
      }
    }
    dataAgendada ??= DateTime.now();
    
    // Converter timestamps
    DateTime? createdAt;
    if (apiData['criadoEm'] != null) {
      if (apiData['criadoEm'] is String) {
        createdAt = DateTime.tryParse(apiData['criadoEm']);
      }
    }
    createdAt ??= DateTime.now();
    
    DateTime? updatedAt;
    if (apiData['atualizadoEm'] != null) {
      if (apiData['atualizadoEm'] is String) {
        updatedAt = DateTime.tryParse(apiData['atualizadoEm']);
      }
    }
    updatedAt ??= DateTime.now();
    
    // Converter horaInicio e horaFim (LocalTime) para DateTime se necessário
    DateTime? dataInicio;
    if (apiData['horaInicio'] != null) {
      if (apiData['horaInicio'] is String) {
        final timeStr = apiData['horaInicio'] as String;
        final timeParts = timeStr.split(':');
        if (timeParts.length >= 2) {
          final hour = int.tryParse(timeParts[0]) ?? 0;
          final minute = int.tryParse(timeParts[1]) ?? 0;
          dataInicio = DateTime(dataAgendada.year, dataAgendada.month, dataAgendada.day, hour, minute);
        }
      }
    }
    
    DateTime? dataConclusao;
    if (apiData['horaFim'] != null) {
      if (apiData['horaFim'] is String) {
        final timeStr = apiData['horaFim'] as String;
        final timeParts = timeStr.split(':');
        if (timeParts.length >= 2) {
          final hour = int.tryParse(timeParts[0]) ?? 0;
          final minute = int.tryParse(timeParts[1]) ?? 0;
          dataConclusao = DateTime(dataAgendada.year, dataAgendada.month, dataAgendada.day, hour, minute);
        }
      }
    }
    
    // Obter checklist para tipo (se disponível)
    final checklist = apiData['checklist'] as Map<String, dynamic>?;
    final tipoNome = checklist?['nome']?.toString().toLowerCase() ?? 'estrutural';
    InspectionType tipo = InspectionType.estrutural;
    try {
      tipo = InspectionType.values.firstWhere(
        (t) => t.name == tipoNome || tipoNome.contains(t.name),
        orElse: () => InspectionType.estrutural,
      );
    } catch (e) {
      tipo = InspectionType.estrutural;
    }
    
    // Garantir que descricao não seja vazia (campo obrigatório no banco)
    final descricaoRaw = apiData['observacoesGerais']?.toString();
    final descricao = descricaoRaw != null ? descricaoRaw.trim() : '';
    final descricaoFinal = descricao.isEmpty ? 'Inspeção sem descrição' : descricao;
    
    return {
      'id': apiData['id']?.toString() ?? '',
      'titulo': titulo,
      'descricao': descricaoFinal,
      'tipo': tipo.name,
      'status': apiData['status']?.toString() ?? 'RASCUNHO',
      'dataAgendada': dataAgendada.toIso8601String(),
      'endereco': apiData['enderecoCompleto']?.toString() ?? '',
      'latitude': (apiData['latitude'] as num?)?.toDouble() ?? 0.0,
      'longitude': (apiData['longitude'] as num?)?.toDouble() ?? 0.0,
      'equipe': [], // Equipe não vem na resposta (lazy loading)
      'itens': [], // Itens não vem na resposta (lazy loading)
      'dataInicio': dataInicio?.toIso8601String(),
      'dataConclusao': dataConclusao?.toIso8601String(),
      'observacoes': apiData['observacoesGerais']?.toString(),
      'fotos': [], // Fotos vêm de anexos separados
      'establishmentId': apiData['estabelecimentoId']?.toString(),
      'inspectorId': apiData['inspetorKeycloakId']?.toString(),
      'checklistId': apiData['checklistId']?.toString(),
      'equipeId': apiData['equipeId']?.toString(),
      'isTemplate': false,
      'isSynced': apiData['sincronizado'] as bool? ?? true,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'serverId': apiData['id']?.toString(),
    };
  }

  Future<void> saveInspections(List<Inspection> inspections) async {
    await _ensureDbInitialized();
    
    // Salvar no banco local (fonte de verdade)
    await _dbService.saveInspections(inspections);
    
    // Manter compatibilidade com SharedPreferences (legado)
    final prefs = await SharedPreferences.getInstance();
    final String inspectionsJson = json.encode(
      inspections.map((inspection) => inspection.toJson()).toList(),
    );
    await prefs.setString(_inspectionsKey, inspectionsJson);
  }

  Future<void> addInspection(Inspection inspection) async {
    await _ensureDbInitialized();
    
    // Salvar no banco local primeiro (offline-first)
    await _dbService.saveInspection(inspection);
    
    // Já criada no servidor (ex.: fluxo online em create_inspection_screen)
    if (inspection.isSynced && inspection.serverId != null && inspection.serverId!.isNotEmpty) {
      return;
    }
    
    // Tentar sincronizar com servidor em background (se online)
    _syncInspectionToServer(inspection).catchError((e) {
      print('Erro ao sincronizar inspeção com servidor: $e');
      // Continuar mesmo se falhar - dados estão salvos localmente
    });
  }

  /// Sincroniza inspeção com servidor (background)
  Future<void> _syncInspectionToServer(Inspection inspection) async {
    try {
      final apiService = ApiService();
      if (apiService.baseUrl == null) {
        apiService.initialize(baseUrl: AppConfig.apiBaseUrl);
      }
      
      final authService = AuthService(apiService, await SharedPreferences.getInstance());
      final token = await authService.getAccessToken();
      if (token != null) {
        apiService.setAuthToken(token);
      }
      
      // Se já tem serverId, não precisa criar novamente
      if (inspection.serverId != null) {
        print('Inspeção ${inspection.id} já foi sincronizada (serverId: ${inspection.serverId})');
        await _dbService.markInspectionAsSynced(inspection.id, inspection.serverId);
        return;
      }
      
      // Converter Inspection para formato do backend
      final requestData = _inspectionToCreateRequest(inspection);
      
      // Criar inspeção via endpoint mobile
      final response = await apiService.createInspectionMobile(requestData);
      
      // Extrair ID do servidor da resposta
      final serverId = response['id']?.toString();
      
      if (serverId != null) {
        // Marcar como sincronizada
        await _dbService.markInspectionAsSynced(inspection.id, serverId);
        print('Inspeção ${inspection.id} criada no servidor com ID: $serverId');
      } else {
        print('Aviso: Resposta do servidor não contém ID da inspeção');
      }
    } catch (e) {
      print('Erro ao sincronizar inspeção: $e');
      // Não relançar erro - inspeção está salva localmente e pode ser sincronizada depois
    }
  }

  /// Converte Inspection (modelo) para CriarInspecaoRequest (formato backend)
  Map<String, dynamic> _inspectionToCreateRequest(Inspection inspection) {
    // Validar campos obrigatórios
    if (inspection.establishmentId == null || inspection.establishmentId!.isEmpty) {
      throw Exception('establishmentId é obrigatório para criar inspeção');
    }
    
    if (inspection.checklistId == null || inspection.checklistId!.isEmpty) {
      throw Exception('checklistId é obrigatório para criar inspeção. Selecione um checklist na tela de criação.');
    }
    
    if (inspection.equipeId == null || inspection.equipeId!.isEmpty) {
      throw Exception('equipeId é obrigatório para criar inspeção. Selecione uma equipe na tela de criação.');
    }
    
    // Extrair data e hora da dataAgendada
    final dataAgendada = inspection.dataAgendada;
    final dataInspecao = '${dataAgendada.year}-${dataAgendada.month.toString().padLeft(2, '0')}-${dataAgendada.day.toString().padLeft(2, '0')}';
    final horaInicio = inspection.dataInicio != null
        ? '${inspection.dataInicio!.hour.toString().padLeft(2, '0')}:${inspection.dataInicio!.minute.toString().padLeft(2, '0')}'
        : null;
    
    // Usar valores reais do modelo
    final request = <String, dynamic>{
      'checklistId': inspection.checklistId!,
      'estabelecimentoId': inspection.establishmentId!,
      'equipeId': inspection.equipeId!,
      'dataInspecao': dataInspecao,
      if (horaInicio != null) 'horaInicio': horaInicio,
      if (inspection.latitude != 0) 'latitude': inspection.latitude,
      if (inspection.longitude != 0) 'longitude': inspection.longitude,
      if (inspection.inspectorId != null && inspection.inspectorId!.isNotEmpty) 
        'inspetorId': inspection.inspectorId,
      if (inspection.endereco.isNotEmpty) 'enderecoCompleto': inspection.endereco,
    };
    
    return request;
  }

  Future<void> updateInspection(Inspection inspection) async {
    await _ensureDbInitialized();
    
    // Atualizar no banco local primeiro (offline-first)
    await _dbService.updateInspection(inspection);
    
    // Tentar sincronizar com servidor em background (se online)
    _syncInspectionUpdateToServer(inspection).catchError((e) {
      print('Erro ao sincronizar atualização com servidor: $e');
      // Continuar mesmo se falhar - dados estão salvos localmente
    });
  }

  /// Sincroniza atualização de inspeção com servidor (background)
  Future<void> _syncInspectionUpdateToServer(Inspection inspection) async {
    try {
      // Se não tem serverId, não foi criada no servidor ainda - criar primeiro
      if (inspection.serverId == null) {
        await _syncInspectionToServer(inspection);
        return;
      }
      
      final apiService = ApiService();
      if (apiService.baseUrl == null) {
        apiService.initialize(baseUrl: AppConfig.apiBaseUrl);
      }
      
      final authService = AuthService(apiService, await SharedPreferences.getInstance());
      final token = await authService.getAccessToken();
      if (token != null) {
        apiService.setAuthToken(token);
      }
      
      // Converter Inspection para formato de atualização do backend
      final requestData = _inspectionToUpdateRequest(inspection);
      
      // Atualizar inspeção via endpoint mobile
      await apiService.updateInspectionMobile(inspection.serverId!, requestData);
      
      // Marcar como sincronizada
      await _dbService.markInspectionAsSynced(inspection.id, inspection.serverId);
      print('Inspeção ${inspection.id} atualizada no servidor com sucesso');
    } catch (e) {
      print('Erro ao sincronizar atualização: $e');
      // Não relançar erro - dados estão salvos localmente e podem ser sincronizados depois
    }
  }

  /// Converte Inspection (modelo) para AtualizarInspecaoRequest (formato backend)
  Map<String, dynamic> _inspectionToUpdateRequest(Inspection inspection) {
    // Extrair data e hora da dataAgendada
    final dataAgendada = inspection.dataAgendada;
    final dataInspecao = '${dataAgendada.year}-${dataAgendada.month.toString().padLeft(2, '0')}-${dataAgendada.day.toString().padLeft(2, '0')}';
    
    final horaInicio = inspection.dataInicio != null
        ? '${inspection.dataInicio!.hour.toString().padLeft(2, '0')}:${inspection.dataInicio!.minute.toString().padLeft(2, '0')}'
        : null;
    
    final horaFim = inspection.dataConclusao != null
        ? '${inspection.dataConclusao!.hour.toString().padLeft(2, '0')}:${inspection.dataConclusao!.minute.toString().padLeft(2, '0')}'
        : null;
    
    final request = <String, dynamic>{
      'dataInspecao': dataInspecao,
      if (horaInicio != null) 'horaInicio': horaInicio,
      if (horaFim != null) 'horaFim': horaFim,
      if (inspection.observacoes != null && inspection.observacoes!.isNotEmpty)
        'observacoesGerais': inspection.observacoes,
      if (inspection.latitude != 0) 'latitude': inspection.latitude,
      if (inspection.longitude != 0) 'longitude': inspection.longitude,
    };
    
    return request;
  }

  // Métodos de Inspetores - Usa API real
  Future<List<Inspector>> getInspectors() async {
    try {
      final apiService = ApiService();
      if (apiService.baseUrl == null) {
        apiService.initialize(baseUrl: AppConfig.apiBaseUrl);
      }
      
      // Buscar inspetores da API (endpoint pode variar)
      final dio = Dio(BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ));
      
      // Adicionar token de autenticação se disponível
      final authService = AuthService(apiService, await SharedPreferences.getInstance());
      final token = await authService.getAccessToken();
      if (token != null) {
        dio.options.headers['Authorization'] = 'Bearer $token';
      }
      
      final response = await dio.get('/api/v1/inspetores');
      
      // Tratar diferentes formatos de resposta da API
      List<dynamic> data;
      if (response.data is List) {
        data = response.data as List<dynamic>;
      } else if (response.data is Map) {
        final responseMap = response.data as Map<String, dynamic>;
        if (responseMap.containsKey('content')) {
          data = responseMap['content'] as List<dynamic>? ?? [];
        } else if (responseMap.containsKey('data')) {
          data = responseMap['data'] as List<dynamic>? ?? [];
        } else {
          return [];
        }
      } else {
        return [];
      }
      
      if (data.isEmpty) {
        return [];
      }
      
      return data.map((json) => Inspector.fromJson(json)).toList();
    } on DioException catch (e) {
      await _handleHttpError(e);
      throw Exception('Erro ao buscar inspetores: ${e.message}');
    } catch (e) {
      // Sem fallback - lançar erro para tratamento adequado
      throw Exception('Erro ao buscar inspetores: $e');
    }
  }

  Future<void> saveInspectors(List<Inspector> inspectors) async {
    final prefs = await SharedPreferences.getInstance();
    final String inspectorsJson = json.encode(
      inspectors.map((inspector) => inspector.toJson()).toList(),
    );
    await prefs.setString(_inspectorsKey, inspectorsJson);
  }

  // Métodos de Usuário
  Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final String? userJson = prefs.getString(_currentUserKey);
    
    if (userJson == null) return null;
    
    return User.fromJson(json.decode(userJson));
  }

  Future<void> setCurrentUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentUserKey, json.encode(user.toJson()));
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserKey);
  }


  /// Busca inspeções pendentes de sincronização (modo offline)
  Future<List<Inspection>> getPendingSyncInspections() async {
    await _ensureDbInitialized();
    return await _dbService.getPendingInspections();
  }

  /// Sincroniza inspeções pendentes com o servidor
  Future<void> syncPendingInspections() async {
    await _ensureDbInitialized();
    
    final pendingInspections = await _dbService.getPendingInspections();
    if (pendingInspections.isEmpty) {
      print('Nenhuma inspeção pendente de sincronização');
      return; // Nada para sincronizar
    }
    
    print('Iniciando sincronização de ${pendingInspections.length} inspeções pendentes...');
    
    try {
      final apiService = ApiService();
      if (apiService.baseUrl == null) {
        apiService.initialize(baseUrl: AppConfig.apiBaseUrl);
      }
      
      final authService = AuthService(apiService, await SharedPreferences.getInstance());
      final token = await authService.getAccessToken();
      if (token != null) {
        apiService.setAuthToken(token);
      }
      
      int successCount = 0;
      int errorCount = 0;
      
      // Sincronizar cada inspeção pendente
      for (final inspection in pendingInspections) {
        try {
          // Se não tem serverId, criar no servidor
          if (inspection.serverId == null || inspection.serverId!.isEmpty) {
            // Validar campos obrigatórios antes de criar
            if (inspection.establishmentId == null || inspection.establishmentId!.isEmpty) {
              print('⚠️ Inspeção ${inspection.id} não pode ser sincronizada: establishmentId ausente');
              errorCount++;
              continue;
            }
            
            if (inspection.checklistId == null || inspection.checklistId!.isEmpty) {
              print('⚠️ Inspeção ${inspection.id} não pode ser sincronizada: checklistId ausente');
              errorCount++;
              continue;
            }
            
            if (inspection.equipeId == null || inspection.equipeId!.isEmpty) {
              print('⚠️ Inspeção ${inspection.id} não pode ser sincronizada: equipeId ausente');
              errorCount++;
              continue;
            }
            
            // Converter para formato do backend e criar
            final requestData = _inspectionToCreateRequest(inspection);
            final response = await apiService.createInspectionMobile(requestData);
            
            // Extrair ID do servidor
            final serverId = response['id']?.toString();
            if (serverId != null) {
              await _dbService.markInspectionAsSynced(inspection.id, serverId);
              successCount++;
              print('✅ Inspeção ${inspection.id} criada no servidor com ID: $serverId');
            } else {
              print('⚠️ Inspeção ${inspection.id}: resposta do servidor não contém ID');
              errorCount++;
            }
          } else {
            // Se tem serverId, atualizar no servidor
            final requestData = _inspectionToUpdateRequest(inspection);
            await apiService.updateInspectionMobile(inspection.serverId!, requestData);
            
            // Marcar como sincronizada
            await _dbService.markInspectionAsSynced(inspection.id, inspection.serverId);
            successCount++;
            print('✅ Inspeção ${inspection.id} atualizada no servidor');
          }
        } catch (e) {
          errorCount++;
          print('❌ Erro ao sincronizar inspeção ${inspection.id}: $e');
          // Continuar com próxima inspeção mesmo se uma falhar
        }
      }
      
      print('📊 Sincronização concluída: $successCount sucesso(s), $errorCount erro(s)');
      
    } catch (e) {
      print('❌ Erro geral ao sincronizar inspeções pendentes: $e');
      // Não lançar erro - sincronização pode ser tentada depois
    }
  }

  // Método de login via API backend
  Future<User?> login(String email, String password) async {
    try {
      // Obter instâncias dos serviços
      final prefs = await SharedPreferences.getInstance();
      final apiService = ApiService();
      
      // Inicializar API service se necessário
      if (apiService.baseUrl == null) {
        apiService.initialize(baseUrl: AppConfig.apiBaseUrl);
      }
      
      final authService = AuthService(apiService, prefs);
      final user = await authService.login(email, password);
      await setCurrentUser(user);
      return user;
    } catch (e) {
      rethrow;
    }
  }

  // Método para obter inspeções filtradas por role do usuário - OFFLINE-FIRST
  /// Lista inspeções visíveis para o utilizador (equipa / supervisor / inspetor designado).
  /// O filtro é aplicado no servidor em `/api/v1/mobile/inspecoes/ativas` — não filtrar aqui por
  /// `inspectorId` (o perfil usa UUID da BD; a API usa inspetorKeycloakId / equipas).
  Future<List<Inspection>> getInspectionsForUser(User user) async {
    await _ensureDbInitialized();
    
    // PASSO 1: Buscar do banco local primeiro (offline-first)
    List<Inspection> localInspections = [];
    try {
      localInspections = await _dbService.getInspections();
    } catch (e) {
      print('Erro ao buscar inspeções do banco local: $e');
    }
    
    // PASSO 2: Tentar sincronizar com API (se online)
    try {
      final apiService = ApiService();
      if (apiService.baseUrl == null) {
        apiService.initialize(baseUrl: AppConfig.apiBaseUrl);
      }
      
      final authService = AuthService(apiService, await SharedPreferences.getInstance());
      final token = await authService.getAccessToken();
      if (token != null) {
        apiService.setAuthToken(token);
      }
      
      // Mesmo critério para todos os perfis mobile (equivalente a /minhas)
      final data = await apiService.getInspecoesAtivas();

      if (data.isNotEmpty) {
        // Converter resposta da API
        final apiInspections = data.map((json) {
        return Inspection.fromJson(_mapApiResponseToInspection(json));
      }).toList();
        
        // PASSO 3: Salvar no banco local (espelho do servidor)
        await _dbService.saveInspections(apiInspections);
        
        // PASSO 4: Marcar como sincronizado
        for (final inspection in apiInspections) {
          await _dbService.markInspectionAsSynced(inspection.id, inspection.serverId);
        }
        
        return await _dbService.getInspections();
      }

      final removed = await _dbService.softDeleteServerMirroredInspections();
      print(
          '📭 GET /api/v1/mobile/inspecoes/ativas retornou []; espelho limpo ($removed removidas).');
      final refreshed = await _dbService.getInspections();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _inspectionsKey,
        json.encode(refreshed.map((i) => i.toJson()).toList()),
      );
      return refreshed;
    } on DioException catch (e) {
      // Se erro de rede, retornar dados locais (modo offline)
      print('Erro ao sincronizar com API: ${e.message} - usando dados locais');
      if (localInspections.isNotEmpty) {
        return localInspections;
      }
      // Se não houver dados locais e for erro de autenticação, tratar
      await _handleHttpError(e);
      throw Exception('Erro ao buscar inspeções: ${e.message}');
    } catch (e) {
      // Outros erros: retornar dados locais se disponíveis
      print('Erro ao sincronizar: $e - usando dados locais');
      if (localInspections.isNotEmpty) {
        return localInspections;
      }
      throw Exception('Erro ao buscar inspeções: $e');
    }
  }

  // Método para verificar se usuário pode criar inspeção
  bool canUserCreateInspection(User user) {
    return user.role == UserRole.supervisor || user.role == UserRole.gestor || user.role == UserRole.diretor;
  }

  // Método para verificar se usuário pode editar inspeção específica
  bool canUserEditInspection(User user, Inspection inspection) {
    if (user.role == UserRole.supervisor || user.role == UserRole.gestor || user.role == UserRole.diretor) return true;
    if (user.role == UserRole.supervisor) return true;
    
    // Inspetor só pode editar se estiver na equipe
    if (user.role == UserRole.inspetor) {
      return inspection.equipe.any((inspector) => inspector.email == user.email);
    }
    
    return false;
  }

  // Métodos de Evidências
  Future<List<Evidence>> getEvidences() async {
    final prefs = await SharedPreferences.getInstance();
    final String? evidencesJson = prefs.getString(_evidencesKey);
    
    if (evidencesJson == null) {
      return [];
    }
    
    final List<dynamic> evidencesList = json.decode(evidencesJson);
    return evidencesList.map((json) => Evidence.fromJson(json)).toList();
  }

  Future<List<Evidence>> getEvidencesByInspection(String inspectionId) async {
    final evidences = await getEvidences();
    return evidences.where((e) => e.inspectionId == inspectionId).toList();
  }

  Future<void> addEvidence(Evidence evidence) async {
    final evidences = await getEvidences();
    evidences.add(evidence);
    await _saveEvidences(evidences);
  }

  Future<void> deleteEvidence(String evidenceId) async {
    final evidences = await getEvidences();
    evidences.removeWhere((e) => e.id == evidenceId);
    await _saveEvidences(evidences);
  }

  Future<void> _saveEvidences(List<Evidence> evidences) async {
    final prefs = await SharedPreferences.getInstance();
    final String evidencesJson = json.encode(
      evidences.map((evidence) => evidence.toJson()).toList(),
    );
    await prefs.setString(_evidencesKey, evidencesJson);
  }

  // Métodos de Notificações - Usa API real
  Future<List<AppNotification>> getNotifications() async {
    try {
      final apiService = ApiService();
      if (apiService.baseUrl == null) {
        apiService.initialize(baseUrl: AppConfig.apiBaseUrl);
      }
      
      final dio = Dio(BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ));
      
      final authService = AuthService(apiService, await SharedPreferences.getInstance());
      final token = await authService.getAccessToken();
      if (token != null) {
        dio.options.headers['Authorization'] = 'Bearer $token';
      }
      
      final response = await dio.get('/api/v1/notificacoes');
      
      // Tratar diferentes formatos de resposta da API
      List<dynamic> data;
      if (response.data is List) {
        data = response.data as List<dynamic>;
      } else if (response.data is Map) {
        final responseMap = response.data as Map<String, dynamic>;
        if (responseMap.containsKey('content')) {
          data = responseMap['content'] as List<dynamic>? ?? [];
        } else if (responseMap.containsKey('data')) {
          data = responseMap['data'] as List<dynamic>? ?? [];
        } else {
          return [];
        }
      } else {
        return [];
      }
      
      if (data.isEmpty) {
        return [];
      }
      
      return data.map((json) => AppNotification.fromJson(json)).toList();
    } on DioException catch (e) {
      await _handleHttpError(e);
      // Para notificações, retornar lista vazia em caso de erro
      return [];
    } catch (e) {
      // Sem fallback - retornar lista vazia se não houver notificações
      return [];
    }
  }

  Future<void> addNotification(AppNotification notification) async {
    final notifications = await getNotifications();
    notifications.insert(0, notification); // Add to beginning
    await _saveNotifications(notifications);
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    final notifications = await getNotifications();
    final index = notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      notifications[index] = notifications[index].copyWith(isRead: true);
      await _saveNotifications(notifications);
    }
  }

  Future<void> _saveNotifications(List<AppNotification> notifications) async {
    final prefs = await SharedPreferences.getInstance();
    final String notificationsJson = json.encode(
      notifications.map((notification) => notification.toJson()).toList(),
    );
    await prefs.setString(_notificationsKey, notificationsJson);
  }


  // Métodos de Plano de Ação
  Future<List<ActionPlan>> getActionPlansByInspection(String inspectionId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? actionPlansJson = prefs.getString(_actionPlansKey);
    
    if (actionPlansJson == null) {
      return [];
    }
    
    try {
      final List<dynamic> actionPlansList = json.decode(actionPlansJson);
      final allActionPlans = actionPlansList.map((json) => ActionPlan.fromJson(json)).toList();
      return allActionPlans.where((action) => action.inspectionId == inspectionId).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<ActionPlan>> getAllActionPlans() async {
    final prefs = await SharedPreferences.getInstance();
    final String? actionPlansJson = prefs.getString(_actionPlansKey);
    
    if (actionPlansJson == null) {
      return [];
    }
    
    try {
      final List<dynamic> actionPlansList = json.decode(actionPlansJson);
      return actionPlansList.map((json) => ActionPlan.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> addActionPlan(ActionPlan actionPlan) async {
    final actionPlans = await getAllActionPlans();
    actionPlans.add(actionPlan);
    await _saveActionPlans(actionPlans);
  }

  Future<void> updateActionPlan(ActionPlan actionPlan) async {
    final actionPlans = await getAllActionPlans();
    final index = actionPlans.indexWhere((a) => a.id == actionPlan.id);
    if (index != -1) {
      actionPlans[index] = actionPlan;
      await _saveActionPlans(actionPlans);
    }
  }

  Future<void> deleteActionPlan(String actionPlanId) async {
    final actionPlans = await getAllActionPlans();
    actionPlans.removeWhere((a) => a.id == actionPlanId);
    await _saveActionPlans(actionPlans);
  }

  Future<void> _saveActionPlans(List<ActionPlan> actionPlans) async {
    final prefs = await SharedPreferences.getInstance();
    final String actionPlansJson = json.encode(
      actionPlans.map((actionPlan) => actionPlan.toJson()).toList(),
    );
    await prefs.setString(_actionPlansKey, actionPlansJson);
  }

  Future<ActionPlan?> createActionPlanForNonConformity({
    required String inspectionId,
    required String inspectionItemId,
    required String itemDescription,
    required List<String> responsibles, // Mudança: Lista de responsáveis
    required DateTime dueDate, // Mudança: Prazo obrigatório
  }) async {
    final now = DateTime.now();
    final actionPlan = ActionPlan(
      id: 'action_${inspectionId}_${inspectionItemId}_${now.millisecondsSinceEpoch}',
      inspectionId: inspectionId,
      inspectionItemId: inspectionItemId,
      description: 'Corrigir não conformidade: $itemDescription',
      status: ActionStatus.pendente,
      responsibles: responsibles, // Mudança: Lista de responsáveis
      dueDate: dueDate, // Mudança: Prazo obrigatório
      createdAt: now,
      updatedAt: now,
    );

    await addActionPlan(actionPlan);
    return actionPlan;
  }

  // Métodos de Estabelecimentos - OFFLINE-FIRST
  Future<List<Establishment>> getAllEstablishments() async {
    await _ensureDbInitialized();
    
    // PASSO 1: Buscar do banco local primeiro
    List<Establishment> localEstablishments = [];
    try {
      localEstablishments = await _dbService.getEstablishments();
    } catch (e) {
      print('Erro ao buscar estabelecimentos do banco local: $e');
    }
    
    // PASSO 2: Tentar sincronizar com API (se online)
    try {
      final apiService = ApiService();
      if (apiService.baseUrl == null) {
        apiService.initialize(baseUrl: AppConfig.apiBaseUrl);
      }
      
      final dio = Dio(BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ));
      
      final authService = AuthService(apiService, await SharedPreferences.getInstance());
      final token = await authService.getAccessToken();
      if (token != null) {
        dio.options.headers['Authorization'] = 'Bearer $token';
      }
      
      // Usar endpoint mobile que retorna lista simples (sem paginação)
      // Se não estiver disponível, usar endpoint web com fallback
      Response? response;
      try {
        response = await dio.get('/api/v1/mobile/estabelecimentos');
      } on DioException catch (e) {
        // Se endpoint mobile não existir (404), usar endpoint web
        if (e.response?.statusCode == 404) {
          print('⚠️ Endpoint mobile não disponível (404), usando endpoint web');
          try {
            // Endpoint web retorna paginação, buscar primeira página com tamanho grande
            response = await dio.get('/api/v1/estabelecimentos', queryParameters: {
              'page': 0,
              'size': 1000, // Buscar muitos registros de uma vez
            });
          } catch (webError) {
            print('⚠️ Erro ao usar endpoint web: $webError');
            rethrow;
          }
        } else {
          rethrow;
        }
      }
      
      // Processar resposta (pode ser lista direta ou paginada)
      List<dynamic> data;
      if (response.data is List) {
        // Endpoint mobile retorna lista direta
        data = response.data as List<dynamic>;
      } else if (response.data is Map) {
        // Endpoint web retorna paginação
        final responseMap = response.data as Map<String, dynamic>;
        if (responseMap.containsKey('content')) {
          data = responseMap['content'] as List<dynamic>? ?? [];
        } else if (responseMap.containsKey('data')) {
          data = responseMap['data'] as List<dynamic>? ?? [];
        } else {
          print('⚠️ Resposta da API não contém dados: ${response.data.runtimeType}');
          return localEstablishments;
        }
      } else {
        print('⚠️ Resposta da API não é uma lista ou mapa: ${response.data.runtimeType}');
        return localEstablishments;
      }
      
      if (data.isNotEmpty) {
        // Mapear resposta da API para modelo Establishment
        final apiEstablishments = data.map((json) {
          return _mapApiResponseToEstablishment(json);
        }).toList();
        
        print('📥 ${apiEstablishments.length} estabelecimentos recebidos da API');
        
        // PASSO 3: Salvar no banco local
        int salvos = 0;
        for (final establishment in apiEstablishments) {
          try {
            await _dbService.saveEstablishment(establishment);
            salvos++;
          } catch (e) {
            print('⚠️ Erro ao salvar estabelecimento ${establishment.id}: $e');
          }
        }
        
        print('✅ $salvos/${apiEstablishments.length} estabelecimentos salvos no banco local');
        
        // Retornar dados atualizados
        return await _dbService.getEstablishments();
      }
    } on DioException catch (e) {
      // Se erro de rede, retornar dados locais (modo offline)
      print('Erro ao sincronizar estabelecimentos: ${e.message} - usando dados locais');
      if (localEstablishments.isNotEmpty) {
        return localEstablishments;
      }
      await _handleHttpError(e);
      throw Exception('Erro ao buscar estabelecimentos: ${e.message}');
    } catch (e) {
      // Outros erros: retornar dados locais se disponíveis
      print('Erro ao sincronizar estabelecimentos: $e - usando dados locais');
      if (localEstablishments.isNotEmpty) {
        return localEstablishments;
      }
      throw Exception('Erro ao buscar estabelecimentos: $e');
    }
    
    // Retornar dados locais (modo offline)
    return localEstablishments;
  }

  Future<Establishment?> getEstablishmentById(String id) async {
    final establishments = await getAllEstablishments();
    try {
      return establishments.firstWhere((e) => e.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<Establishment?> getEstablishmentByInspection(Inspection inspection) async {
    if (inspection.establishmentId == null) return null;
    return await getEstablishmentById(inspection.establishmentId!);
  }

  /// Sincronização inicial após login
  /// Sincroniza estabelecimentos e inspeções para garantir dados disponíveis offline
  Future<void> syncInitialData({bool showProgress = false}) async {
    try {
      print('🔄 Iniciando sincronização inicial de dados...');
      await _ensureDbInitialized();
      
      // Sincronizar estabelecimentos primeiro (necessários para criar inspeções)
      print('📥 Sincronizando estabelecimentos...');
      try {
        await getAllEstablishments();
        print('✅ Estabelecimentos sincronizados');
      } catch (e) {
        print('⚠️ Erro ao sincronizar estabelecimentos: $e');
        // Continuar mesmo se falhar
      }
      
      // Sincronizar inspeções
      print('📥 Sincronizando inspeções...');
      try {
        final user = await getCurrentUser();
        if (user != null) {
          await getInspectionsForUser(user);
          print('✅ Inspeções sincronizadas');
        }
      } catch (e) {
        print('⚠️ Erro ao sincronizar inspeções: $e');
        // Continuar mesmo se falhar
      }
      
      // Sincronizar categorias de estabelecimento (opcional, mas útil)
      print('📥 Sincronizando categorias de estabelecimento...');
      try {
        await _syncCategoriasEstabelecimento();
        print('✅ Categorias sincronizadas');
      } catch (e) {
        print('⚠️ Erro ao sincronizar categorias: $e');
        // Continuar mesmo se falhar
      }
      
      // Sincronizar equipes de inspeção
      print('📥 Sincronizando equipes...');
      try {
        await _syncEquipes();
        print('✅ Equipes sincronizadas');
      } catch (e) {
        print('⚠️ Erro ao sincronizar equipes: $e');
        // Continuar mesmo se falhar
      }
      
      // Sincronizar checklists completos (com itens)
      print('📥 Sincronizando checklists completos...');
      try {
        await _syncChecklistsCompletos();
        print('✅ Checklists completos sincronizados');
      } catch (e) {
        print('⚠️ Erro ao sincronizar checklists completos: $e');
        // Continuar mesmo se falhar
      }
      
      print('✅ Sincronização inicial concluída');
    } catch (e) {
      print('❌ Erro na sincronização inicial: $e');
      // Não lançar exceção para não bloquear o login
    }
  }

  /// Sincroniza categorias de estabelecimento do servidor
  Future<void> _syncCategoriasEstabelecimento() async {
    try {
      final apiService = ApiService();
      if (apiService.baseUrl == null) {
        apiService.initialize(baseUrl: AppConfig.apiBaseUrl);
      }
      
      final authService = AuthService(apiService, await SharedPreferences.getInstance());
      final token = await authService.getAccessToken();
      if (token != null) {
        apiService.setAuthToken(token);
      }
      
      final dio = Dio(BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ));
      
      if (token != null) {
        dio.options.headers['Authorization'] = 'Bearer $token';
      }
      
      // Buscar categorias ativas (tentar endpoint mobile primeiro, fallback para web)
      Response? response;
      try {
        response = await dio.get('/api/v1/mobile/categorias-estabelecimento/ativas');
      } on DioException catch (e) {
        // Se endpoint mobile não existir (404), usar endpoint web
        if (e.response?.statusCode == 404) {
          print('⚠️ Endpoint mobile não disponível (404), usando endpoint web');
          response = await dio.get('/api/v1/categorias-estabelecimento/ativas');
        } else {
          // Outros erros, relançar
          rethrow;
        }
      } catch (e) {
        // Outros tipos de erro, tentar endpoint web
        print('⚠️ Erro ao acessar endpoint mobile, usando endpoint web: $e');
        response = await dio.get('/api/v1/categorias-estabelecimento/ativas');
      }
      
      if (response.data is List) {
        final categorias = response.data as List<dynamic>;
        print('📥 ${categorias.length} categorias recebidas da API');
        
        // Salvar no banco local
        for (final categoriaJson in categorias) {
          try {
            final id = categoriaJson['id']?.toString() ?? '';
            final codigo = categoriaJson['codigo']?.toString() ?? '';
            final nome = categoriaJson['nome']?.toString() ?? '';
            final descricao = categoriaJson['descricao']?.toString();
            final icone = categoriaJson['icone']?.toString();
            final cor = categoriaJson['cor']?.toString();
            final ordem = categoriaJson['ordem'] as int? ?? 1;
            final ativo = categoriaJson['ativo'] as bool? ?? true;
            
            // Datas
            DateTime criadoEm = DateTime.now();
            DateTime? atualizadoEm;
            if (categoriaJson['criadoEm'] != null) {
              try {
                criadoEm = DateTime.parse(categoriaJson['criadoEm']);
              } catch (e) {
                criadoEm = DateTime.now();
              }
            }
            if (categoriaJson['atualizadoEm'] != null) {
              try {
                atualizadoEm = DateTime.parse(categoriaJson['atualizadoEm']);
              } catch (e) {
                atualizadoEm = null;
              }
            }
            
            // Criar companion para salvar
            final companion = db.CategoriasEstabelecimentoCompanion(
              id: Value(id),
              codigo: Value(codigo),
              nome: Value(nome),
              descricao: Value(descricao),
              icone: Value(icone),
              cor: Value(cor),
              ordem: Value(ordem),
              ativo: Value(ativo),
              criadoEm: Value(criadoEm),
              atualizadoEm: Value(atualizadoEm),
              isSynced: const Value(true), // Vem da API, então está sincronizado
              serverId: Value(id), // ID do servidor é o mesmo ID
            );
            
            await _dbService.saveCategoriaEstabelecimento(companion);
            print('  ✅ ${nome} (${codigo}) salva no banco local');
          } catch (e) {
            print('  ⚠️ Erro ao salvar categoria ${categoriaJson['nome']}: $e');
          }
        }
        
        print('✅ ${categorias.length} categorias salvas no banco local');
      }
    } catch (e) {
      print('⚠️ Erro ao sincronizar categorias: $e');
      // Não lançar exceção
    }
  }

  /// Sincroniza equipes de inspeção do servidor
  Future<void> _syncEquipes() async {
    try {
      final apiService = ApiService();
      if (apiService.baseUrl == null) {
        apiService.initialize(baseUrl: AppConfig.apiBaseUrl);
      }
      
      final authService = AuthService(apiService, await SharedPreferences.getInstance());
      final token = await authService.getAccessToken();
      if (token != null) {
        apiService.setAuthToken(token);
      }
      
      print('📥 Sincronizando equipes...');
      
      final equipes = await apiService.getEquipesAtivas();
      print('📥 ${equipes.length} equipes recebidas da API');
      
      for (final equipeJson in equipes) {
        try {
          final id = equipeJson['id']?.toString() ?? '';
          final codigo = equipeJson['codigo']?.toString() ?? '';
          final nome = equipeJson['nome']?.toString() ?? '';
          final descricao = equipeJson['descricao']?.toString();
          final supervisorId = equipeJson['supervisorId']?.toString();
          final supervisorNome = equipeJson['supervisorNome']?.toString();
          final ativo = equipeJson['ativo'] as bool? ?? true;
          
          // Buscar membros da equipe
          final equipeCompleta = await apiService.getEquipeCompleta(id);
          final membros = equipeCompleta['membros'] as List<dynamic>? ?? [];
          
          // Salvar equipe
          final equipeCompanion = db.EquipesCompanion(
            id: Value(id),
            codigo: Value(codigo),
            nome: Value(nome),
            descricao: Value(descricao),
            supervisorId: Value(supervisorId),
            supervisorNome: Value(supervisorNome),
            ativo: Value(ativo),
            isSynced: const Value(true),
            createdAt: Value(DateTime.now()),
            updatedAt: Value(DateTime.now()),
            serverId: Value(id),
          );
          
          await _dbService.saveEquipe(equipeCompanion);
          
          // Salvar membros
          for (final membroJson in membros) {
            final membroId = membroJson['id']?.toString() ?? '';
            final usuarioId = membroJson['usuarioId']?.toString() ?? '';
            final usuarioNome = membroJson['usuarioNome']?.toString();
            final usuarioEmail = membroJson['usuarioEmail']?.toString();
            final membroAtivo = membroJson['ativo'] as bool? ?? true;
            
            DateTime? entradaEm;
            if (membroJson['entradaEm'] != null) {
              try {
                entradaEm = DateTime.parse(membroJson['entradaEm']);
              } catch (e) {
                entradaEm = null;
              }
            }
            
            DateTime? saidaEm;
            if (membroJson['saidaEm'] != null) {
              try {
                saidaEm = DateTime.parse(membroJson['saidaEm']);
              } catch (e) {
                saidaEm = null;
              }
            }
            
            final membroCompanion = db.EquipeMembrosCompanion(
              id: Value(membroId),
              equipeId: Value(id),
              usuarioId: Value(usuarioId),
              usuarioNome: Value(usuarioNome),
              usuarioEmail: Value(usuarioEmail),
              ativo: Value(membroAtivo),
              entradaEm: Value(entradaEm),
              saidaEm: Value(saidaEm),
              isSynced: const Value(true),
              createdAt: Value(DateTime.now()),
              updatedAt: Value(DateTime.now()),
              serverId: Value(membroId),
            );
            
            await _dbService.saveEquipeMembro(membroCompanion);
          }
          
          print('  ✅ Equipe $nome ($codigo) salva com ${membros.length} membros');
        } catch (e) {
          print('  ⚠️ Erro ao salvar equipe ${equipeJson['nome']}: $e');
        }
      }
      
      print('✅ ${equipes.length} equipes sincronizadas');
    } catch (e) {
      print('⚠️ Erro ao sincronizar equipes: $e');
      // Não lançar exceção
    }
  }

  /// Sincroniza checklists completos (com seções, itens e opções) do servidor
  Future<void> _syncChecklistsCompletos() async {
    try {
      final apiService = ApiService();
      if (apiService.baseUrl == null) {
        apiService.initialize(baseUrl: AppConfig.apiBaseUrl);
      }
      
      final authService = AuthService(apiService, await SharedPreferences.getInstance());
      final token = await authService.getAccessToken();
      if (token != null) {
        apiService.setAuthToken(token);
      }
      
      print('📥 Sincronizando checklists completos...');
      
      // Buscar todos os checklists públicos
      final checklists = await apiService.getChecklistsPublicos();
      print('📥 ${checklists.length} checklists encontrados');
      
      for (final checklistJson in checklists) {
        try {
          final checklistId = checklistJson['id']?.toString() ?? '';
          
          // Buscar checklist completo com seções e itens
          final checklistCompleto = await apiService.getChecklistCompleto(checklistId);
          
          final nome = checklistCompleto['nome']?.toString() ?? '';
          final descricao = checklistCompleto['descricao']?.toString();
          final categoriaId = checklistCompleto['categoriaId']?.toString();
          final categoriaNome = checklistCompleto['categoriaNome']?.toString();
          final criadoPorId = checklistCompleto['criadoPorId']?.toString();
          final criadoPorNome = checklistCompleto['criadoPorNome']?.toString();
          final ativo = checklistCompleto['ativo'] as bool? ?? true;
          final publico = checklistCompleto['publico'] as bool? ?? false;
          
          DateTime? criadoEm;
          if (checklistCompleto['criadoEm'] != null) {
            try {
              criadoEm = DateTime.parse(checklistCompleto['criadoEm']);
            } catch (e) {
              criadoEm = DateTime.now();
            }
          } else {
            criadoEm = DateTime.now();
          }
          
          DateTime? atualizadoEm;
          if (checklistCompleto['atualizadoEm'] != null) {
            try {
              atualizadoEm = DateTime.parse(checklistCompleto['atualizadoEm']);
            } catch (e) {
              atualizadoEm = null;
            }
          }
          
          // Configurações (JSON)
          String? configuracoesJson;
          if (checklistCompleto['configuracoes'] != null) {
            configuracoesJson = jsonEncode(checklistCompleto['configuracoes']);
          }
          
          // Salvar checklist
          final checklistCompanion = db.ChecklistsCompanion(
            id: Value(checklistId),
            nome: Value(nome),
            descricao: Value(descricao),
            categoriaId: Value(categoriaId),
            categoriaNome: Value(categoriaNome),
            criadoPorId: Value(criadoPorId),
            criadoPorNome: Value(criadoPorNome),
            publico: Value(publico),
            ativo: Value(ativo),
            configuracoesJson: Value(configuracoesJson),
            criadoEm: Value(criadoEm),
            atualizadoEm: Value(atualizadoEm),
            isSynced: const Value(true),
            dataDownload: Value(DateTime.now()),
            serverId: Value(checklistId),
          );
          
          await _dbService.saveChecklist(checklistCompanion);
          
          // Salvar seções, itens e opções
          final secoes = checklistCompleto['secoes'] as List<dynamic>? ?? [];
          print('  📋 Processando ${secoes.length} seções do checklist $nome');
          int totalSecoes = 0;
          int totalItens = 0;
          int totalOpcoes = 0;
          
          for (final secaoJson in secoes) {
            final secaoTitulo = secaoJson['titulo']?.toString() ?? 'Sem título';
            final secaoId = secaoJson['id']?.toString() ?? '';
            final secaoPaiId = secaoJson['secaoPaiId']?.toString();
            final titulo = secaoJson['titulo']?.toString() ?? '';
            final secaoDescricao = secaoJson['descricao']?.toString();
            final ordem = secaoJson['ordem'] as int? ?? 1;
            final secaoAtivo = secaoJson['ativo'] as bool? ?? true;
            final ajudaSecao = secaoJson['ajudaSecao']?.toString();
            final corTextoAjuda = secaoJson['corTextoAjuda']?.toString();
            final pontuacaoMaxima = secaoJson['pontuacaoMaxima'] as int?;
            final ponderacao = secaoJson['ponderacao'] != null ? (secaoJson['ponderacao'] as num).toDouble() : null;
            final calculaScore = secaoJson['calculaScore'] as bool? ?? true;
            final tipoSecao = secaoJson['tipoSecao']?.toString();
            
            DateTime? secaoCriadoEm;
            if (secaoJson['criadoEm'] != null) {
              try {
                secaoCriadoEm = DateTime.parse(secaoJson['criadoEm']);
              } catch (e) {
                secaoCriadoEm = DateTime.now();
              }
            } else {
              secaoCriadoEm = DateTime.now();
            }
            
            DateTime? secaoAtualizadoEm;
            if (secaoJson['atualizadoEm'] != null) {
              try {
                secaoAtualizadoEm = DateTime.parse(secaoJson['atualizadoEm']);
              } catch (e) {
                secaoAtualizadoEm = null;
              }
            }
            
            // Ações e condições (JSON)
            String? acoesJson;
            if (secaoJson['acoes'] != null) {
              acoesJson = jsonEncode(secaoJson['acoes']);
            }
            
            String? condicoesVisibilidadeJson;
            if (secaoJson['condicoesVisibilidade'] != null) {
              condicoesVisibilidadeJson = jsonEncode(secaoJson['condicoesVisibilidade']);
            }
            
            // Salvar seção
            final secaoCompanion = db.SecoesChecklistCompanion(
              id: Value(secaoId),
              checklistId: Value(checklistId),
              secaoPaiId: Value(secaoPaiId),
              titulo: Value(titulo),
              descricao: Value(secaoDescricao),
              ordem: Value(ordem),
              ativo: Value(secaoAtivo),
              ajudaSecao: Value(ajudaSecao),
              corTextoAjuda: Value(corTextoAjuda),
              pontuacaoMaxima: Value(pontuacaoMaxima),
              ponderacao: Value(ponderacao),
              calculaScore: Value(calculaScore),
              tipoSecao: Value(tipoSecao),
              acoesJson: Value(acoesJson),
              condicoesVisibilidadeJson: Value(condicoesVisibilidadeJson),
              criadoEm: Value(secaoCriadoEm),
              atualizadoEm: Value(secaoAtualizadoEm),
              isSynced: const Value(true),
              serverId: Value(secaoId),
            );
            
            await _dbService.saveSecaoChecklist(secaoCompanion);
            totalSecoes++;
            
            // Salvar itens da seção
            final itens = secaoJson['itens'] as List<dynamic>? ?? [];
            print('    📝 Seção "$secaoTitulo" tem ${itens.length} itens');
            
            if (itens.isEmpty) {
              print('    ⚠️ Seção "$secaoTitulo" não tem itens. Verificando estrutura: ${secaoJson.keys}');
            }
            
            for (final itemJson in itens) {
              final itemId = itemJson['id']?.toString() ?? '';
              final rotulo = itemJson['rotulo']?.toString() ?? '';
              final itemDescricao = itemJson['descricao']?.toString();
              final ajuda = itemJson['ajuda']?.toString();
              final itemTipo = itemJson['tipo']?.toString() ?? 'TEXTO';
              final itemOrdem = itemJson['ordem'] as int? ?? 1;
              final itemObrigatorio = itemJson['obrigatorio'] as bool? ?? false;
              final itemAtivo = itemJson['ativo'] as bool? ?? true;
              
              DateTime? itemCriadoEm;
              if (itemJson['criadoEm'] != null) {
                try {
                  itemCriadoEm = DateTime.parse(itemJson['criadoEm']);
                } catch (e) {
                  itemCriadoEm = DateTime.now();
                }
              } else {
                itemCriadoEm = DateTime.now();
              }
              
              DateTime? itemAtualizadoEm;
              if (itemJson['atualizadoEm'] != null) {
                try {
                  itemAtualizadoEm = DateTime.parse(itemJson['atualizadoEm']);
                } catch (e) {
                  itemAtualizadoEm = null;
                }
              }
              
              // Configurações, ações e condições (JSON)
              String? itemConfiguracoesJson;
              if (itemJson['configuracoes'] != null) {
                itemConfiguracoesJson = jsonEncode(itemJson['configuracoes']);
              }
              
              String? itemAcoesJson;
              if (itemJson['acoes'] != null) {
                itemAcoesJson = jsonEncode(itemJson['acoes']);
              }
              
              String? itemCondicoesVisibilidadeJson;
              if (itemJson['condicoesVisibilidade'] != null) {
                itemCondicoesVisibilidadeJson = jsonEncode(itemJson['condicoesVisibilidade']);
              }
              
              // Salvar item
              final itemCompanion = db.ItensChecklistCompanion(
                id: Value(itemId),
                secaoId: Value(secaoId),
                rotulo: Value(rotulo),
                descricao: Value(itemDescricao),
                ajuda: Value(ajuda),
                tipo: Value(itemTipo),
                ordem: Value(itemOrdem),
                obrigatorio: Value(itemObrigatorio),
                ativo: Value(itemAtivo),
                configuracoesJson: Value(itemConfiguracoesJson),
                acoesJson: Value(itemAcoesJson),
                condicoesVisibilidadeJson: Value(itemCondicoesVisibilidadeJson),
                criadoEm: Value(itemCriadoEm),
                atualizadoEm: Value(itemAtualizadoEm),
                isSynced: const Value(true),
                serverId: Value(itemId),
              );
              
              await _dbService.saveItemChecklist(itemCompanion);
              totalItens++;
              
              // Salvar opções do item
              final opcoes = itemJson['opcoes'] as List<dynamic>? ?? [];
              if (opcoes.isNotEmpty) {
                print('      ✅ Item "$rotulo" tem ${opcoes.length} opções');
              }
              
              for (final opcaoJson in opcoes) {
                final opcaoId = opcaoJson['id']?.toString() ?? '';
                final opcaoTexto = opcaoJson['texto']?.toString() ?? '';
                final opcaoValor = opcaoJson['valor']?.toString();
                final opcaoOrdem = opcaoJson['ordem'] as int? ?? 1;
                final opcaoCor = opcaoJson['cor']?.toString();
                final opcaoPontuacao = opcaoJson['pontuacao'] as int?;
                final comentarioPadrao = opcaoJson['comentarioPadrao']?.toString();
                
                DateTime? opcaoCriadoEm;
                if (opcaoJson['criadoEm'] != null) {
                  try {
                    opcaoCriadoEm = DateTime.parse(opcaoJson['criadoEm']);
    } catch (e) {
                    opcaoCriadoEm = DateTime.now();
                  }
                } else {
                  opcaoCriadoEm = DateTime.now();
                }
                
                DateTime? opcaoAtualizadoEm;
                if (opcaoJson['atualizadoEm'] != null) {
                  try {
                    opcaoAtualizadoEm = DateTime.parse(opcaoJson['atualizadoEm']);
                  } catch (e) {
                    opcaoAtualizadoEm = null;
                  }
                }
                
                // Ações (JSON)
                String? opcaoAcoesJson;
                if (opcaoJson['acoes'] != null) {
                  opcaoAcoesJson = jsonEncode(opcaoJson['acoes']);
                }
                
                // Salvar opção
                final opcaoCompanion = db.OpcoesItemChecklistCompanion(
                  id: Value(opcaoId),
                  itemId: Value(itemId),
                  texto: Value(opcaoTexto),
                  valor: Value(opcaoValor),
                  ordem: Value(opcaoOrdem),
                  cor: Value(opcaoCor),
                  pontuacao: Value(opcaoPontuacao),
                  comentarioPadrao: Value(comentarioPadrao),
                  acoesJson: Value(opcaoAcoesJson),
                  criadoEm: Value(opcaoCriadoEm),
                  atualizadoEm: Value(opcaoAtualizadoEm),
                  isSynced: const Value(true),
                  serverId: Value(opcaoId),
                );
                
                await _dbService.saveOpcaoItemChecklist(opcaoCompanion);
                totalOpcoes++;
              }
            }
          }
          
          print('  ✅ Checklist $nome salvo: $totalSecoes seções, $totalItens itens, $totalOpcoes opções');
        } catch (e) {
          print('  ⚠️ Erro ao salvar checklist ${checklistJson['nome']}: $e');
        }
      }
      
      print('✅ Checklists completos sincronizados');
    } catch (e) {
      print('⚠️ Erro ao sincronizar checklists completos: $e');
      // Não lançar exceção
    }
  }



  // Métodos utilitários para EstablishmentType
  // Usar establishment.tipoText diretamente (já implementado no modelo)
  static String getEstablishmentTypeText(EstablishmentType type) {
    // Criar um Establishment temporário para usar o getter tipoText
    final temp = Establishment(
      id: '',
      nome: '',
      descricao: '',
      tipo: type,
      endereco: '',
      latitude: 0,
      longitude: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    return temp.tipoText;
  }

  // Cor padrão para todos os tipos de estabelecimento
  static Color getEstablishmentTypeColor(EstablishmentType type) {
    return Colors.blue; // Cor padrão
  }

  // Métodos utilitários para InspectionType
  // O tipo já vem da API via checklist, usar inspection.tipoText diretamente
  static String getInspectionTypeText(InspectionType type) {
    // Criar um Inspection temporário para usar o getter tipoText
    final temp = Inspection(
      id: '',
      titulo: '',
      descricao: '',
      tipo: type,
      status: InspectionStatus.rascunho,
      dataAgendada: DateTime.now(),
      endereco: '',
      latitude: 0,
      longitude: 0,
      equipe: [],
      itens: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    return temp.tipoText;
  }

  // Método para formatar título da inspeção com estabelecimento
  static String getInspectionDisplayTitle(Inspection inspection, Establishment? establishment) {
    if (establishment != null) {
      return '${inspection.titulo} - ${establishment.nome}';
    }
    return inspection.titulo;
  }

  // Métodos para checklists por categoria
  /// Busca checklists por categoria de estabelecimento
  /// categoryName pode ser o nome da categoria (ex: "Estabelecimento", "Veículo") ou o código
  Future<List<Checklist>> getChecklistsByCategory(String categoryName) async {
    try {
      print('🔍 Buscando checklists para categoria: $categoryName');
      
      // Inicializar ApiService
      final apiService = ApiService();
      if (apiService.baseUrl == null) {
        apiService.initialize(baseUrl: AppConfig.apiBaseUrl);
      }
      
      // Adicionar token de autenticação se disponível
      final authService = AuthService(apiService, await SharedPreferences.getInstance());
      final token = await authService.getAccessToken();
      if (token != null) {
        apiService.setAuthToken(token);
      }
      
      // Buscar checklists da API por categoria de estabelecimento
      final apiChecklists = await apiService.getChecklistsPorCategoriaEstabelecimento(categoryName);
      
      // Mapear resposta da API para modelo Checklist
      final checklists = apiChecklists.map((apiData) {
        return _mapApiResponseToChecklist(apiData);
      }).toList();
      
      print('✅ ${checklists.length} checklists encontrados para categoria $categoryName');
      return checklists;
    } catch (e) {
      print('❌ Erro ao buscar checklists por categoria: $e');
      // Em caso de erro, tentar buscar checklists públicos como fallback
      try {
        print('🔄 Tentando buscar checklists públicos como fallback...');
        final apiService = ApiService();
        if (apiService.baseUrl == null) {
          apiService.initialize(baseUrl: AppConfig.apiBaseUrl);
        }
        
        final authService = AuthService(apiService, await SharedPreferences.getInstance());
        final token = await authService.getAccessToken();
        if (token != null) {
          apiService.setAuthToken(token);
        }
        
        final apiChecklists = await apiService.getChecklistsPublicos();
        final checklists = apiChecklists.map((apiData) {
          return _mapApiResponseToChecklist(apiData);
        }).toList();
        print('✅ ${checklists.length} checklists públicos encontrados');
        return checklists;
      } catch (fallbackError) {
        print('❌ Erro ao buscar checklists públicos: $fallbackError');
        return [];
      }
    }
  }

  /// Busca todos os checklists públicos e ativos
  Future<List<Checklist>> getAllChecklists() async {
    try {
      print('🔍 Buscando todos os checklists públicos...');
      
      // Inicializar ApiService
      final apiService = ApiService();
      if (apiService.baseUrl == null) {
        apiService.initialize(baseUrl: AppConfig.apiBaseUrl);
      }
      
      // Adicionar token de autenticação se disponível
      final authService = AuthService(apiService, await SharedPreferences.getInstance());
      final token = await authService.getAccessToken();
      if (token != null) {
        apiService.setAuthToken(token);
      }
      
      final apiChecklists = await apiService.getChecklistsPublicos();
      
      final checklists = apiChecklists.map((apiData) {
        return _mapApiResponseToChecklist(apiData);
      }).toList();
      
      print('✅ ${checklists.length} checklists encontrados');
      return checklists;
    } catch (e) {
      print('❌ Erro ao buscar checklists: $e');
      return [];
    }
  }

  /// Mapeia resposta da API para modelo Establishment
  /// O endpoint mobile retorna EstabelecimentoDtos.Response (completo, inclui latitude/longitude)
  Establishment _mapApiResponseToEstablishment(Map<String, dynamic> apiData) {
    final id = apiData['id']?.toString() ?? '';
    final nome = apiData['nome']?.toString() ?? 'Sem nome';
    final codigo = apiData['codigo']?.toString() ?? '';
    final endereco = apiData['endereco']?.toString() ?? '';
    final cidade = apiData['cidade']?.toString() ?? '';
    final concelho = apiData['concelho']?.toString() ?? '';
    final codigoPostal = apiData['codigoPostal']?.toString() ?? '';
    
    // Montar endereço completo
    final enderecoCompleto = [
      endereco,
      if (codigoPostal.isNotEmpty) codigoPostal,
      if (cidade.isNotEmpty) cidade,
      if (concelho.isNotEmpty) concelho,
    ].where((s) => s.isNotEmpty).join(', ');
    
    // Obter tipo da categoria de estabelecimento
    final categoriaCodigo = apiData['categoriaEstabelecimentoCodigo']?.toString() ?? '';
    final categoriaNome = apiData['categoriaEstabelecimentoNome']?.toString() ?? '';
    
    // Obter tipo da API (já vem mapeado do backend)
    EstablishmentType tipo = EstablishmentType.outros;
    try {
      final tipoStr = apiData['tipo']?.toString() ?? '';
      if (tipoStr.isNotEmpty) {
        tipo = EstablishmentType.values.firstWhere(
          (t) => t.name == tipoStr,
          orElse: () => EstablishmentType.outros,
        );
      } else {
        // Fallback: tentar mapear pelo código da categoria se tipo não vier
        final categoriaLower = categoriaCodigo.toLowerCase();
        if (categoriaLower.contains('instituicao') || categoriaLower.contains('instituição')) {
          tipo = EstablishmentType.instituicao;
        } else if (categoriaLower.contains('estabelecimento')) {
          tipo = EstablishmentType.estabelecimento;
        } else if (categoriaLower.contains('veiculo') || categoriaLower.contains('veículo')) {
          tipo = EstablishmentType.veiculo;
        } else if (categoriaLower.contains('saude') || categoriaLower.contains('saúde')) {
          tipo = EstablishmentType.entidadeSaude;
        } else if (categoriaLower.contains('equipamento')) {
          tipo = EstablishmentType.equipamento;
        } else if (categoriaLower.contains('predio') || categoriaLower.contains('prédio')) {
          tipo = EstablishmentType.predio;
        } else if (categoriaLower.contains('area') || categoriaLower.contains('área')) {
          tipo = EstablishmentType.area;
        }
      }
    } catch (e) {
      print('⚠️ Erro ao mapear tipo de estabelecimento: $e');
      tipo = EstablishmentType.outros;
    }
    
    // Coordenadas (Response completo inclui latitude/longitude)
    final latitude = (apiData['latitude'] as num?)?.toDouble() ?? 0.0;
    final longitude = (apiData['longitude'] as num?)?.toDouble() ?? 0.0;
    
    // Descrição pode ser o código ou nome da categoria
    final descricao = categoriaNome.isNotEmpty ? categoriaNome : codigo;
    
    // Datas (Response completo pode incluir criadoEm/atualizadoEm)
    DateTime createdAt = DateTime.now();
    DateTime updatedAt = DateTime.now();
    if (apiData['criadoEm'] != null) {
      try {
        createdAt = DateTime.parse(apiData['criadoEm']);
      } catch (e) {
        createdAt = DateTime.now();
      }
    }
    if (apiData['atualizadoEm'] != null) {
      try {
        updatedAt = DateTime.parse(apiData['atualizadoEm']);
      } catch (e) {
        updatedAt = DateTime.now();
      }
    }
    
    // Contatos (podem vir no Response completo)
    final telefone = apiData['telefone']?.toString();
    final email = apiData['email']?.toString();
    final responsavel = apiData['responsavel']?.toString();
    final observacoes = apiData['numeroAlvara']?.toString() ?? apiData['observacoes']?.toString();
    
    return Establishment(
      id: id,
      nome: nome,
      descricao: descricao,
      tipo: tipo,
      endereco: enderecoCompleto.isNotEmpty ? enderecoCompleto : endereco,
      latitude: latitude,
      longitude: longitude,
      telefone: telefone,
      email: email,
      responsavel: responsavel,
      observacoes: observacoes,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isSynced: true, // Vem da API, então está sincronizado
      serverId: id, // ID do servidor é o mesmo ID
    );
  }

  /// Mapeia resposta da API para modelo Checklist
  Checklist _mapApiResponseToChecklist(Map<String, dynamic> apiData) {
    final id = apiData['id']?.toString() ?? '';
    final nome = apiData['nome']?.toString() ?? 'Sem nome';
    final descricao = apiData['descricao']?.toString() ?? '';
    final categoriaNome = apiData['categoriaNome']?.toString() ?? 
                         apiData['categoriaEstabelecimentoNome']?.toString() ?? 
                         'Geral';
    final ativo = apiData['ativo'] as bool? ?? false;
    final publico = apiData['publico'] as bool? ?? false;
    
    // Contar itens/seções (se disponível na resposta)
    // Por padrão, usar valores estimados se não vierem na resposta
    final questionCount = apiData['totalItens'] as int? ?? 0;
    final sections = apiData['totalSecoes'] as int? ?? 1;
    
    // Estimar tempo baseado no número de itens (1 minuto por item)
    final estimatedMinutes = questionCount > 0 ? questionCount : 15;
    final estimatedTime = '${estimatedMinutes} min';
    
    // Determinar dificuldade baseado no número de itens
    String difficulty = 'Medium';
    if (questionCount > 50) {
      difficulty = 'High';
    } else if (questionCount < 10) {
      difficulty = 'Low';
    }
    
    return Checklist(
      id: id,
      title: nome,
      description: descricao,
      category: categoriaNome,
      questionCount: questionCount,
      sections: sections,
      estimatedTime: estimatedTime,
      difficulty: difficulty,
      isActive: ativo && publico, // Apenas checklists ativos e públicos
    );
  }

}

// Modelo para checklists (usado em checklists_screen.dart)
class Checklist {
  final String id;
  final String title;
  final String description;
  final String category;
  final int questionCount;
  final int sections;
  final String estimatedTime;
  final String difficulty; // Low, Medium, High
  final bool isActive;

  Checklist({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.questionCount,
    required this.sections,
    required this.estimatedTime,
    required this.difficulty,
    required this.isActive,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'questionCount': questionCount,
      'sections': sections,
      'estimatedTime': estimatedTime,
      'difficulty': difficulty,
      'isActive': isActive,
    };
  }

  factory Checklist.fromJson(Map<String, dynamic> json) {
    return Checklist(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      category: json['category'],
      questionCount: json['questionCount'],
      sections: json['sections'],
      estimatedTime: json['estimatedTime'],
      difficulty: json['difficulty'],
      isActive: json['isActive'],
    );
  }
}

