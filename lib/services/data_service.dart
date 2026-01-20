import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:inspecao/models/inspection.dart';
import 'package:inspecao/models/inspector.dart';
import 'package:inspecao/models/user.dart';
import 'package:inspecao/models/evidence.dart';
import 'package:inspecao/models/notification.dart';
import 'package:inspecao/models/action_plan.dart';
import 'package:inspecao/models/establishment.dart';
import 'package:inspecao/models/organization.dart';
import 'package:inspecao/services/auth_service.dart';
import 'package:inspecao/services/api_service.dart';
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

  // Métodos de Inspeções - Usa API real
  // Para tela "Ver Todas Inspeções" - retorna todas as inspeções ativas
  Future<List<Inspection>> getInspections() async {
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
      
      // Usar endpoint mobile específico para inspeções ativas
      final data = await apiService.getInspecoesAtivas();
      
      if (data.isEmpty) {
        return [];
      }
      
      final inspections = data.map((json) {
        // Converter resposta da API para formato do modelo
        return Inspection.fromJson(_mapApiResponseToInspection(json));
      }).toList();
      
      // Salvar no cache local apenas para sincronização offline
      await saveInspections(inspections);
      
      return inspections;
    } on DioException catch (e) {
      await _handleHttpError(e);
      throw Exception('Erro ao buscar inspeções: ${e.message}');
    } catch (e) {
      // Sem fallback - lançar erro para tratamento adequado
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
    
    return {
      'id': apiData['id']?.toString() ?? '',
      'titulo': titulo,
      'descricao': apiData['observacoesGerais']?.toString() ?? '',
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
      'isTemplate': false,
      'isSynced': apiData['sincronizado'] as bool? ?? true,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'serverId': apiData['id']?.toString(),
    };
  }

  Future<void> saveInspections(List<Inspection> inspections) async {
    final prefs = await SharedPreferences.getInstance();
    final String inspectionsJson = json.encode(
      inspections.map((inspection) => inspection.toJson()).toList(),
    );
    await prefs.setString(_inspectionsKey, inspectionsJson);
  }

  Future<void> addInspection(Inspection inspection) async {
    final inspections = await getInspections();
    inspections.add(inspection);
    await saveInspections(inspections);
  }

  Future<void> updateInspection(Inspection inspection) async {
    final inspections = await getInspections();
    final index = inspections.indexWhere((i) => i.id == inspection.id);
    if (index != -1) {
      inspections[index] = inspection;
      await saveInspections(inspections);
    }
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

  // Método para obter inspeções filtradas por role do usuário
  // Para home screen - retorna apenas inspeções do inspetor logado (status ativos)
  Future<List<Inspection>> getInspectionsForUser(User user) async {
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
      
      // Para inspetores, usar endpoint mobile específico que retorna apenas suas inspeções ativas
      if (user.role == UserRole.inspetor) {
        final data = await apiService.getMinhasInspecoesAtivas();
        
        if (data.isEmpty) {
          return [];
        }
        
      final inspections = data.map((json) {
        return Inspection.fromJson(_mapApiResponseToInspection(json));
      }).toList();
        
        // Salvar no cache local
        await saveInspections(inspections);
        
        return inspections;
      }
      
      // Para outros roles (supervisor, gestor, diretor), usar endpoint de todas as ativas
      final data = await apiService.getInspecoesAtivas();
      
      if (data.isEmpty) {
        return [];
      }
      
      final inspections = data.map((json) {
        return Inspection.fromJson(_mapApiResponseToInspection(json));
      }).toList();
      
      // Salvar no cache local
      await saveInspections(inspections);
      
      return inspections;
    } on DioException catch (e) {
      await _handleHttpError(e);
      throw Exception('Erro ao buscar inspeções do usuário: ${e.message}');
    } catch (e) {
      // Sem fallback - lançar erro
      throw Exception('Erro ao buscar inspeções do usuário: $e');
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

  // Métodos de Estabelecimentos - Usa API real
  Future<List<Establishment>> getAllEstablishments() async {
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
      
      final response = await dio.get('/api/v1/estabelecimentos');
      
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
      
      return data.map((json) => Establishment.fromJson(json)).toList();
    } on DioException catch (e) {
      await _handleHttpError(e);
      throw Exception('Erro ao buscar estabelecimentos: ${e.message}');
    } catch (e) {
      // Sem fallback - lançar erro para tratamento adequado
      throw Exception('Erro ao buscar estabelecimentos: $e');
    }
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



  // Métodos utilitários para EstablishmentType
  static String getEstablishmentTypeText(EstablishmentType type) {
    switch (type) {
      case EstablishmentType.instituicao:
        return 'Instituição';
      case EstablishmentType.estabelecimento:
        return 'Estabelecimento';
      case EstablishmentType.veiculo:
        return 'Veículo';
      case EstablishmentType.entidadeSaude:
        return 'Entidade de Saúde';
      case EstablishmentType.equipamento:
        return 'Equipamento';
      case EstablishmentType.predio:
        return 'Prédio';
      case EstablishmentType.area:
        return 'Área';
      case EstablishmentType.outros:
        return 'Outros';
    }
  }

  static Color getEstablishmentTypeColor(EstablishmentType type) {
    switch (type) {
      case EstablishmentType.instituicao:
        return Colors.blue;
      case EstablishmentType.estabelecimento:
        return Colors.green;
      case EstablishmentType.veiculo:
        return Colors.orange;
      case EstablishmentType.entidadeSaude:
        return Colors.red;
      case EstablishmentType.equipamento:
        return Colors.purple;
      case EstablishmentType.predio:
        return Colors.brown;
      case EstablishmentType.area:
        return Colors.teal;
      case EstablishmentType.outros:
        return Colors.grey;
    }
  }

  // Métodos utilitários para InspectionType
  static String getInspectionTypeText(InspectionType type) {
    switch (type) {
      case InspectionType.estrutural:
        return 'Estrutural';
      case InspectionType.eletrica:
        return 'Elétrica';
      case InspectionType.hidraulica:
        return 'Hidráulica';
      case InspectionType.seguranca:
        return 'Segurança';
      case InspectionType.ambiental:
        return 'Ambiental';
    }
  }

  // Método para formatar título da inspeção com estabelecimento
  static String getInspectionDisplayTitle(Inspection inspection, Establishment? establishment) {
    if (establishment != null) {
      return '${inspection.titulo} - ${establishment.nome}';
    }
    return inspection.titulo;
  }

  // Métodos para templates de auditoria
  Future<List<AuditTemplate>> getAuditTemplates() async {
    // Simular carregamento de templates do servidor
    await Future.delayed(const Duration(seconds: 1));
    
    return [
      AuditTemplate(
        id: '1',
        title: 'Scaffolding Inspection Checklist',
        description: 'A comprehensive checklist for scaffolding safety inspections',
        category: 'Construction',
        questionCount: 27,
        questions: _generateScaffoldingQuestions(),
      ),
      AuditTemplate(
        id: '2',
        title: 'Construction Quality Inspection',
        description: 'Quality control checklist for construction projects',
        category: 'Construction',
        questionCount: 50,
        questions: _generateConstructionQuestions(),
      ),
      AuditTemplate(
        id: '3',
        title: 'Construction Safety Audit',
        description: 'Safety audit checklist for construction sites',
        category: 'Construction',
        questionCount: 18,
        questions: _generateSafetyQuestions(),
      ),
      AuditTemplate(
        id: '4',
        title: 'Internal OHSMS Audit (AS/NZS4801:2001)',
        description: 'Occupational Health and Safety Management System audit',
        category: 'Construction',
        questionCount: 94,
        questions: _generateSafetyQuestions(),
      ),
      AuditTemplate(
        id: '5',
        title: 'Safety Walkthrough Checklist',
        description: 'General safety walkthrough inspection checklist',
        category: 'Construction',
        questionCount: 12,
        questions: _generateSafetyQuestions(),
      ),
      AuditTemplate(
        id: '6',
        title: 'Restaurant Visit Report',
        description: 'Health and safety inspection for restaurants',
        category: 'Food & Hospitality',
        questionCount: 35,
        questions: _generateRestaurantQuestions(),
      ),
    ];
  }

  // Lista de templates do usuário (simulando armazenamento local)
  static List<AuditTemplate> _userTemplates = [];

  static void _initializeUserTemplates() {
    if (_userTemplates.isEmpty) {
      _userTemplates = [
        // Template padrão já disponível para o usuário
        AuditTemplate(
          id: 'user_1',
          title: 'Construction Safety Audit',
          description: 'Safety audit checklist for construction sites',
          category: 'Construction',
          questionCount: 18,
          questions: _generateSafetyQuestionsStatic(),
        ),
        AuditTemplate(
          id: 'user_2',
          title: 'Restaurant Visit Report',
          description: 'Health and safety inspection for restaurants',
          category: 'Food & Hospitality',
          questionCount: 35,
          questions: _generateRestaurantQuestionsStatic(),
        ),
      ];
    }
  }

  Future<void> addUserTemplate(AuditTemplate template) async {
    // Simular salvamento do template para o usuário
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Adicionar template à lista do usuário
    _userTemplates.add(template);
    
    // Aqui você salvaria o template no banco de dados local ou servidor
    print('Template ${template.title} added to user templates');
  }

  Future<List<AuditTemplate>> getUserTemplates() async {
    // Simular carregamento dos templates do usuário
    await Future.delayed(const Duration(milliseconds: 300));
    
    // Inicializar templates padrão se necessário
    _initializeUserTemplates();
    
    return List.from(_userTemplates);
  }

  // Métodos para checklists por categoria
  Future<List<Checklist>> getChecklistsByCategory(String categoryName) async {
    // Simular carregamento de checklists do servidor
    await Future.delayed(const Duration(milliseconds: 500));
    
    switch (categoryName) {
      case 'Construction':
        return [
          Checklist(
            id: '1',
            title: 'Scaffolding Inspection Checklist',
            description: 'A comprehensive checklist for scaffolding safety inspections',
            category: 'Construction',
            questionCount: 27,
            sections: 4,
            estimatedTime: '15-20 minutes',
            difficulty: 'Medium',
            isActive: true,
          ),
          Checklist(
            id: '2',
            title: 'Construction Quality Inspection',
            description: 'Quality control checklist for construction projects',
            category: 'Construction',
            questionCount: 50,
            sections: 6,
            estimatedTime: '25-30 minutes',
            difficulty: 'High',
            isActive: true,
          ),
          Checklist(
            id: '3',
            title: 'Construction Safety Audit',
            description: 'Safety audit checklist for construction sites',
            category: 'Construction',
            questionCount: 18,
            sections: 3,
            estimatedTime: '10-15 minutes',
            difficulty: 'Low',
            isActive: true,
          ),
        ];
      case 'Food & Hospitality':
        return [
          Checklist(
            id: '4',
            title: 'Food Safety & Hygiene Checklist',
            description: 'Comprehensive food safety and hygiene inspection',
            category: 'Food & Hospitality',
            questionCount: 179,
            sections: 8,
            estimatedTime: '45-60 minutes',
            difficulty: 'High',
            isActive: true,
          ),
          Checklist(
            id: '5',
            title: 'Restaurant Visit Report',
            description: 'Health and safety inspection for restaurants',
            category: 'Food & Hospitality',
            questionCount: 91,
            sections: 5,
            estimatedTime: '30-40 minutes',
            difficulty: 'Medium',
            isActive: true,
          ),
          Checklist(
            id: '6',
            title: 'Food and Beverage Audit Checklist',
            description: 'Detailed audit for food and beverage operations',
            category: 'Food & Hospitality',
            questionCount: 58,
            sections: 4,
            estimatedTime: '20-25 minutes',
            difficulty: 'Medium',
            isActive: true,
          ),
          Checklist(
            id: '7',
            title: 'Critical Figure of 8 Checklist',
            description: 'Critical safety checklist for food operations',
            category: 'Food & Hospitality',
            questionCount: 28,
            sections: 2,
            estimatedTime: '10-15 minutes',
            difficulty: 'Low',
            isActive: true,
          ),
          Checklist(
            id: '8',
            title: 'Reservations Check',
            description: 'Reservation system and process verification',
            category: 'Food & Hospitality',
            questionCount: 9,
            sections: 1,
            estimatedTime: '5-10 minutes',
            difficulty: 'Low',
            isActive: true,
          ),
        ];
      default:
        return [];
    }
  }

  static List<AuditQuestion> _generateSafetyQuestionsStatic() {
    return [
      AuditQuestion(
        id: '1',
        text: 'Are the current emergency evacuation plan & procedure displayed in appropriate positions around site?',
        type: 'choice',
        options: ['Yes', 'No', 'N/A'],
      ),
      AuditQuestion(
        id: '2',
        text: 'Are fire extinguishers marked correctly on evacuation plan?',
        type: 'choice',
        options: ['Yes', 'No', 'N/A'],
      ),
      AuditQuestion(
        id: '3',
        text: 'Are all workers wearing appropriate safety equipment?',
        type: 'choice',
        options: ['Yes', 'No', 'N/A'],
      ),
      AuditQuestion(
        id: '4',
        text: 'Are safety barriers properly installed?',
        type: 'choice',
        options: ['Yes', 'No', 'N/A'],
      ),
    ];
  }

  static List<AuditQuestion> _generateRestaurantQuestionsStatic() {
    return [
      AuditQuestion(
        id: '1',
        text: 'Is the kitchen area clean and sanitized?',
        type: 'choice',
        options: ['Yes', 'No', 'N/A'],
      ),
      AuditQuestion(
        id: '2',
        text: 'Are food storage temperatures appropriate?',
        type: 'choice',
        options: ['Yes', 'No', 'N/A'],
      ),
    ];
  }

  Future<void> createInspection(Inspection inspection) async {
    // Simular criação de inspeção
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Aqui você salvaria a inspeção no banco de dados local ou servidor
    print('Inspection ${inspection.titulo} created successfully');
  }

  List<AuditQuestion> _generateScaffoldingQuestions() {
    return [
      AuditQuestion(
        id: '1',
        text: 'General Information',
        type: 'text',
      ),
      AuditQuestion(
        id: '2',
        text: 'Project',
        type: 'text',
      ),
      AuditQuestion(
        id: '3',
        text: 'Before Using The Scaffold',
        type: 'text',
      ),
      AuditQuestion(
        id: '4',
        text: 'Comments',
        type: 'text',
      ),
    ];
  }

  List<AuditQuestion> _generateConstructionQuestions() {
    return [
      AuditQuestion(
        id: '1',
        text: 'Is the lumber the correct grade as specified on the plans?',
        type: 'choice',
        options: ['Yes', 'No', 'N/A'],
      ),
      AuditQuestion(
        id: '2',
        text: 'Are the correct trusses installed per the engineered layout?',
        type: 'choice',
        options: ['Yes', 'No', 'N/A'],
      ),
    ];
  }

  List<AuditQuestion> _generateSafetyQuestions() {
    return [
      AuditQuestion(
        id: '1',
        text: 'Are the current emergency evacuation plan & procedure displayed in appropriate positions around site?',
        type: 'choice',
        options: ['Yes', 'No', 'N/A'],
      ),
      AuditQuestion(
        id: '2',
        text: 'Are fire extinguishers marked correctly on evacuation plan?',
        type: 'choice',
        options: ['Yes', 'No', 'N/A'],
      ),
      AuditQuestion(
        id: '3',
        text: 'Are all workers wearing appropriate safety equipment?',
        type: 'choice',
        options: ['Yes', 'No', 'N/A'],
      ),
      AuditQuestion(
        id: '4',
        text: 'Are safety barriers properly installed?',
        type: 'choice',
        options: ['Yes', 'No', 'N/A'],
      ),
    ];
  }

  List<AuditQuestion> _generateRestaurantQuestions() {
    return [
      AuditQuestion(
        id: '1',
        text: 'Is the kitchen area clean and sanitized?',
        type: 'choice',
        options: ['Yes', 'No', 'N/A'],
      ),
      AuditQuestion(
        id: '2',
        text: 'Are food storage temperatures appropriate?',
        type: 'choice',
        options: ['Yes', 'No', 'N/A'],
      ),
    ];
  }

  // Métodos para organizações/empresas
  Future<List<Organization>> getOrganizations() async {
    // Simular carregamento de organizações do servidor
    await Future.delayed(const Duration(milliseconds: 500));
    
    return [
      Organization(
        id: '1',
        name: 'MSN',
        description: 'Microsoft Network',
        isActive: true,
      ),
      Organization(
        id: '2',
        name: 'Google',
        description: 'Google LLC',
        isActive: true,
      ),
      Organization(
        id: '3',
        name: 'Apple',
        description: 'Apple Inc.',
        isActive: true,
      ),
      Organization(
        id: '4',
        name: 'Amazon',
        description: 'Amazon.com Inc.',
        isActive: true,
      ),
    ];
  }

  Future<Organization?> getCurrentOrganization() async {
    final prefs = await SharedPreferences.getInstance();
    final String? orgJson = prefs.getString('current_organization');
    
    if (orgJson == null) {
      // Retornar MSN como padrão
      final organizations = await getOrganizations();
      final defaultOrg = organizations.firstWhere((org) => org.name == 'MSN');
      await setCurrentOrganization(defaultOrg);
      return defaultOrg;
    }
    
    return Organization.fromJson(json.decode(orgJson));
  }

  Future<void> setCurrentOrganization(Organization organization) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_organization', json.encode(organization.toJson()));
  }

  // Métodos para categorias dinâmicas
  Future<List<Category>> getCategories() async {
    // Simular carregamento de categorias do servidor
    await Future.delayed(const Duration(milliseconds: 300));
    
    return [
      Category(
        id: '1',
        name: 'Construction',
        displayName: 'Construction',
        color: Colors.orange.value,
        iconUrl: 'assets/images/categories/construction.png',
        isActive: true,
      ),
      Category(
        id: '2',
        name: 'Retail',
        displayName: 'Retail',
        color: Colors.blue.value,
        iconUrl: 'assets/images/categories/retail.png',
        isActive: true,
      ),
      Category(
        id: '3',
        name: 'Manufacturing',
        displayName: 'Manufacturing',
        color: Colors.purple.value,
        iconUrl: 'assets/images/categories/manufacturing.png',
        isActive: true,
      ),
      Category(
        id: '4',
        name: 'Hotels & Vacation Rentals',
        displayName: 'Hotels & Vacation Rentals',
        color: Colors.teal.value,
        iconUrl: 'assets/images/categories/hotels.png',
        isActive: true,
      ),
      Category(
        id: '5',
        name: 'Food & Hospitality',
        displayName: 'Food & Hospitality',
        color: Colors.red.value,
        iconUrl: 'assets/images/categories/food.png',
        isActive: true,
      ),
      Category(
        id: '6',
        name: 'Transport & Automotive',
        displayName: 'Transport & Automotive',
        color: Colors.green.value,
        iconUrl: 'assets/images/categories/transport.png',
        isActive: true,
      ),
      Category(
        id: '7',
        name: 'Facility & Services',
        displayName: 'Facility & Services',
        color: Colors.indigo.value,
        iconUrl: 'assets/images/categories/facility.png',
        isActive: true,
      ),
    ];
  }

  Future<Category?> getCategoryByName(String categoryName) async {
    final categories = await getCategories();
    try {
      return categories.firstWhere((category) => category.name == categoryName);
    } catch (e) {
      return null;
    }
  }
}

// Modelo para templates de auditoria
class AuditTemplate {
  final String id;
  final String title;
  final String description;
  final String category;
  final int questionCount;
  final List<AuditQuestion> questions;

  AuditTemplate({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.questionCount,
    required this.questions,
  });
}

class AuditQuestion {
  final String id;
  final String text;
  final String type; // 'choice', 'text', 'number', etc.
  final List<String>? options; // Para perguntas de escolha

  AuditQuestion({
    required this.id,
    required this.text,
    required this.type,
    this.options,
  });
}

// Modelo para categorias
class Category {
  final String id;
  final String name;
  final String displayName;
  final int color; // Color value
  final String iconUrl; // URL da imagem do ícone
  final bool isActive;

  Category({
    required this.id,
    required this.name,
    required this.displayName,
    required this.color,
    required this.iconUrl,
    required this.isActive,
  });

  Color get colorValue => Color(color);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'displayName': displayName,
      'color': color,
      'iconUrl': iconUrl,
      'isActive': isActive,
    };
  }

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      displayName: json['displayName'],
      color: json['color'],
      iconUrl: json['iconUrl'],
      isActive: json['isActive'],
    );
  }
}

// Modelo para checklists
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

