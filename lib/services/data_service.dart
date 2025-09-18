import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:inspecao/models/inspection.dart';
import 'package:inspecao/models/inspector.dart';
import 'package:inspecao/models/user.dart';
import 'package:inspecao/models/inspection_item.dart';
import 'package:inspecao/models/evidence.dart';
import 'package:inspecao/models/notification.dart';
import 'package:inspecao/models/action_plan.dart';
import 'package:inspecao/models/establishment.dart';
import 'package:inspecao/models/organization.dart';

class DataService {
  static const String _inspectionsKey = 'inspections';
  static const String _inspectorsKey = 'inspectors';
  static const String _currentUserKey = 'current_user';
  static const String _evidencesKey = 'evidences';
  static const String _notificationsKey = 'notifications';
  static const String _actionPlansKey = 'action_plans';
  static const String _establishmentsKey = 'establishments';

  // Singleton
  static final DataService _instance = DataService._internal();
  factory DataService() => _instance;
  DataService._internal();

  // Métodos de Inspeções
  Future<List<Inspection>> getInspections() async {
    final prefs = await SharedPreferences.getInstance();
    final String? inspectionsJson = prefs.getString(_inspectionsKey);
    
    if (inspectionsJson == null) {
      await _initializeSampleData();
      return getInspections();
    }
    
    final List<dynamic> inspectionsList = json.decode(inspectionsJson);
    return inspectionsList.map((json) => Inspection.fromJson(json)).toList();
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

  // Métodos de Inspetores
  Future<List<Inspector>> getInspectors() async {
    final prefs = await SharedPreferences.getInstance();
    final String? inspectorsJson = prefs.getString(_inspectorsKey);
    
    if (inspectorsJson == null) {
      await _initializeSampleData();
      return getInspectors();
    }
    
    final List<dynamic> inspectorsList = json.decode(inspectorsJson);
    return inspectorsList.map((json) => Inspector.fromJson(json)).toList();
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

  // Inicializar dados de exemplo
  Future<void> _initializeSampleData() async {
    // Inspetores de exemplo
    final sampleInspectors = [
      Inspector(
        id: '1',
        nome: 'João Silva',
        email: 'joao.silva@empresa.com',
        telefone: '(11) 99999-1111',
        cargo: InspectorRole.lider,
        especialidades: ['Estrutural', 'Segurança'],
      ),
      Inspector(
        id: '2',
        nome: 'Maria Santos',
        email: 'maria.santos@empresa.com',
        telefone: '(11) 99999-2222',
        cargo: InspectorRole.tecnico,
        especialidades: ['Elétrica', 'Hidráulica'],
      ),
      Inspector(
        id: '3',
        nome: 'Pedro Oliveira',
        email: 'pedro.oliveira@empresa.com',
        telefone: '(11) 99999-3333',
        cargo: InspectorRole.assistente,
        especialidades: ['Ambiental'],
      ),
    ];

    // Itens de inspeção de exemplo
    final sampleItems = [
      InspectionItem(
        id: '1',
        descricao: 'Verificar integridade estrutural das vigas principais',
        categoria: 'Estrutura',
        status: ItemStatus.pendente,
        obrigatorio: true,
        ordem: 1,
      ),
      InspectionItem(
        id: '2',
        descricao: 'Avaliar sistema de combate a incêndio',
        categoria: 'Segurança',
        status: ItemStatus.pendente,
        obrigatorio: true,
        ordem: 2,
      ),
      InspectionItem(
        id: '3',
        descricao: 'Testar funcionamento das instalações elétricas',
        categoria: 'Elétrica',
        status: ItemStatus.pendente,
        obrigatorio: false,
        ordem: 3,
      ),
    ];

    // Inspeções de exemplo
    final sampleInspections = [
      Inspection(
        id: '1',
        titulo: 'Inspeção Estrutural - Edifício Central',
        descricao: 'Avaliação completa da estrutura do edifício principal',
        tipo: InspectionType.estrutural,
        status: InspectionStatus.agendada,
        dataAgendada: DateTime.now().add(const Duration(days: 2)),
        endereco: 'Rua das Flores, 123, São Paulo - SP',
        latitude: -23.550520,
        longitude: -46.633308,
        equipe: [sampleInspectors[0], sampleInspectors[1]],
        itens: sampleItems,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Inspection(
        id: '2',
        titulo: 'Vistoria Elétrica - Galpão Industrial',
        descricao: 'Verificação das instalações elétricas industriais',
        tipo: InspectionType.eletrica,
        status: InspectionStatus.emAndamento,
        dataAgendada: DateTime.now(),
        endereco: 'Av. Industrial, 456, Guarulhos - SP',
        latitude: -23.462847,
        longitude: -46.533150,
        equipe: [sampleInspectors[1]],
        itens: sampleItems.take(2).toList(),
        dataInicio: DateTime.now().subtract(const Duration(hours: 2)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Inspection(
        id: '3',
        titulo: 'Inspeção Ambiental - Área Verde',
        descricao: 'Avaliação de impacto ambiental na área de preservação',
        tipo: InspectionType.ambiental,
        status: InspectionStatus.concluida,
        dataAgendada: DateTime.now().subtract(const Duration(days: 1)),
        endereco: 'Parque Ecológico, Km 15, Rod. Anhanguera',
        latitude: -23.200000,
        longitude: -46.800000,
        equipe: [sampleInspectors[2]],
        itens: sampleItems.map((item) => item.copyWith(status: ItemStatus.conforme)).toList(),
        dataInicio: DateTime.now().subtract(const Duration(days: 1, hours: 8)),
        dataConclusao: DateTime.now().subtract(const Duration(days: 1, hours: 4)),
        observacoes: 'Área em conformidade com regulamentações ambientais.',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Inspection(
        id: '4',
        titulo: 'Inspeção de Segurança - Fábrica',
        descricao: 'Verificação de equipamentos de segurança',
        tipo: InspectionType.seguranca,
        status: InspectionStatus.agendada,
        dataAgendada: DateTime.now().add(const Duration(days: 3)),
        endereco: 'Rua Industrial, 789, Osasco - SP',
        latitude: -23.5329,
        longitude: -46.7919,
        equipe: [sampleInspectors[0]], // Apenas João Silva
        itens: sampleItems.take(1).toList(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Inspection(
        id: '5',
        titulo: 'Vistoria Hidráulica - Condomínio',
        descricao: 'Verificação das instalações hidráulicas',
        tipo: InspectionType.hidraulica,
        status: InspectionStatus.emAndamento,
        dataAgendada: DateTime.now().subtract(const Duration(hours: 1)),
        endereco: 'Av. Paulista, 1000, São Paulo - SP',
        latitude: -23.5615,
        longitude: -46.6565,
        equipe: [sampleInspectors[1]], // Apenas Maria Santos
        itens: sampleItems.skip(1).take(1).toList(),
        dataInicio: DateTime.now().subtract(const Duration(hours: 1)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    await saveInspectors(sampleInspectors);
    await saveInspections(sampleInspections);
  }

  // Método de login simples (demo)
  Future<User?> login(String email, String password) async {
    // Demo: diferentes usuários baseados no email
    if (email.isNotEmpty && password.isNotEmpty) {
      User user;
      
      if (email.contains('admin')) {
        user = User(
          id: '1',
          nome: 'Administrador',
          email: email,
          role: UserRole.admin,
          dataCriacao: DateTime(2024, 1, 15),
          ultimoAcesso: DateTime.now(),
        );
      } else if (email.contains('supervisor')) {
        user = User(
          id: '2',
          nome: 'Supervisor',
          email: email,
          role: UserRole.supervisor,
          dataCriacao: DateTime(2024, 2, 10),
          ultimoAcesso: DateTime.now(),
        );
      } else if (email.contains('inspector') || email.contains('inspetor')) {
        user = User(
          id: '3',
          nome: 'Inspetor',
          email: email,
          role: UserRole.inspetor,
          dataCriacao: DateTime(2024, 3, 5),
          ultimoAcesso: DateTime.now(),
        );
      } else {
        // Default: admin para outros emails
        user = User(
          id: '1',
          nome: 'Administrador',
          email: email,
          role: UserRole.admin,
          dataCriacao: DateTime(2024, 1, 15),
          ultimoAcesso: DateTime.now(),
        );
      }
      
      await setCurrentUser(user);
      return user;
    }
    return null;
  }

  // Método para obter inspeções filtradas por role do usuário
  Future<List<Inspection>> getInspectionsForUser(User user) async {
    final allInspections = await getInspections();
    
    if (user.role == UserRole.admin || user.role == UserRole.supervisor) {
      return allInspections; // Admin e supervisor veem todas
    } else if (user.role == UserRole.inspetor) {
      // Inspetor vê apenas inspeções onde ele está na equipe
      return allInspections.where((inspection) {
        return inspection.equipe.any((inspector) => inspector.email == user.email);
      }).toList();
    }
    
    return [];
  }

  // Método para verificar se usuário pode criar inspeção
  bool canUserCreateInspection(User user) {
    return user.role == UserRole.admin || user.role == UserRole.supervisor;
  }

  // Método para verificar se usuário pode editar inspeção específica
  bool canUserEditInspection(User user, Inspection inspection) {
    if (user.role == UserRole.admin) return true;
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

  // Métodos de Notificações
  Future<List<AppNotification>> getNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final String? notificationsJson = prefs.getString(_notificationsKey);
    
    if (notificationsJson == null) {
      await _initializeSampleNotifications();
      return getNotifications();
    }
    
    try {
      final List<dynamic> notificationsList = json.decode(notificationsJson);
      return notificationsList.map((json) => AppNotification.fromJson(json)).toList();
    } catch (e) {
      // Se houver erro ao decodificar (ex: tipo message_received), limpar e reinicializar
      await prefs.remove(_notificationsKey);
      await _initializeSampleNotifications();
      return getNotifications();
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

  Future<void> _initializeSampleNotifications() async {
    final user = await getCurrentUser();
    if (user == null) return;

    final sampleNotifications = [
      AppNotification(
        id: '1',
        title: 'Nova Inspeção Atribuída',
        message: 'Você foi atribuído à inspeção "Edifício Central"',
        type: NotificationType.inspection_assigned,
        priority: NotificationPriority.high,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        relatedId: '1',
      ),
      AppNotification(
        id: '2',
        title: 'Inspeção Concluída',
        message: 'Inspeção estrutural foi finalizada',
        type: NotificationType.inspection_status_update,
        priority: NotificationPriority.medium,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      AppNotification(
        id: '3',
        title: 'Sistema Atualizado',
        message: 'Nova versão do app disponível',
        type: NotificationType.system_alert,
        priority: NotificationPriority.low,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];

    await _saveNotifications(sampleNotifications);
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

  // Métodos de Estabelecimentos
  Future<List<Establishment>> getAllEstablishments() async {
    final prefs = await SharedPreferences.getInstance();
    final String? establishmentsJson = prefs.getString(_establishmentsKey);
    
    if (establishmentsJson == null) {
      await _initializeSampleEstablishments();
      return getAllEstablishments();
    }
    
    try {
      final List<dynamic> establishmentsList = json.decode(establishmentsJson);
      return establishmentsList.map((json) => Establishment.fromJson(json)).toList();
    } catch (e) {
      return [];
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

  Future<void> _initializeSampleEstablishments() async {
    final now = DateTime.now();
    final sampleEstablishments = [
      Establishment(
        id: 'est_1',
        nome: 'Hospital Central',
        descricao: 'Hospital público principal da cidade',
        tipo: EstablishmentType.entidadeSaude,
        endereco: 'Rua das Flores, 123 - Centro',
        latitude: -23.5505,
        longitude: -46.6333,
        telefone: '(11) 3333-4444',
        email: 'contato@hospitalcentral.com',
        responsavel: 'Dr. João Silva',
        observacoes: 'Hospital com 200 leitos',
        createdAt: now.subtract(const Duration(days: 30)),
        updatedAt: now.subtract(const Duration(days: 30)),
      ),
      Establishment(
        id: 'est_2',
        nome: 'Escola Municipal São Paulo',
        descricao: 'Escola pública de ensino fundamental',
        tipo: EstablishmentType.instituicao,
        endereco: 'Av. Paulista, 1000 - Bela Vista',
        latitude: -23.5613,
        longitude: -46.6565,
        telefone: '(11) 2222-3333',
        email: 'escola@municipal.com',
        responsavel: 'Maria Santos',
        observacoes: 'Escola com 500 alunos',
        createdAt: now.subtract(const Duration(days: 25)),
        updatedAt: now.subtract(const Duration(days: 25)),
      ),
      Establishment(
        id: 'est_3',
        nome: 'Restaurante Bom Sabor',
        descricao: 'Restaurante popular do centro',
        tipo: EstablishmentType.estabelecimento,
        endereco: 'Rua Augusta, 456 - Consolação',
        latitude: -23.5475,
        longitude: -46.6361,
        telefone: '(11) 4444-5555',
        email: 'contato@bomsabor.com',
        responsavel: 'Carlos Oliveira',
        observacoes: 'Especializado em comida caseira',
        createdAt: now.subtract(const Duration(days: 20)),
        updatedAt: now.subtract(const Duration(days: 20)),
      ),
      Establishment(
        id: 'est_4',
        nome: 'Ambulância SAMU-001',
        descricao: 'Veículo de emergência médica',
        tipo: EstablishmentType.veiculo,
        endereco: 'Base SAMU - Rua das Emergências, 789',
        latitude: -23.5405,
        longitude: -46.6403,
        telefone: '(11) 192',
        responsavel: 'Enfermeiro Pedro Costa',
        observacoes: 'Ambulância equipada com UTI móvel',
        createdAt: now.subtract(const Duration(days: 15)),
        updatedAt: now.subtract(const Duration(days: 15)),
      ),
      Establishment(
        id: 'est_5',
        nome: 'Equipamento Raio-X',
        descricao: 'Aparelho de radiografia portátil',
        tipo: EstablishmentType.equipamento,
        endereco: 'Hospital Central - Ala de Diagnóstico',
        latitude: -23.5505,
        longitude: -46.6333,
        responsavel: 'Técnico Ana Lima',
        observacoes: 'Equipamento móvel para emergências',
        createdAt: now.subtract(const Duration(days: 10)),
        updatedAt: now.subtract(const Duration(days: 10)),
      ),
    ];

    await _saveEstablishments(sampleEstablishments);
  }

  Future<void> _saveEstablishments(List<Establishment> establishments) async {
    final prefs = await SharedPreferences.getInstance();
    final String establishmentsJson = json.encode(
      establishments.map((establishment) => establishment.toJson()).toList(),
    );
    await prefs.setString(_establishmentsKey, establishmentsJson);
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

