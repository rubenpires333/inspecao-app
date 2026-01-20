import 'package:inspecao/models/user.dart';

/// Mapeamento de permissões da API para funcionalidades
class PermissionCodes {
  // Inspeções
  static const String criarInspecao = 'CRIAR_INSPECAO';
  static const String editarInspecao = 'EDITAR_INSPECAO';
  static const String deletarInspecao = 'DELETAR_INSPECAO';
  static const String visualizarInspecao = 'VISUALIZAR_INSPECAO';
  static const String executarInspecao = 'EXECUTAR_INSPECAO';
  static const String visualizarTodasInspecoes = 'VISUALIZAR_TODAS_INSPECOES';
  
  // Relatórios
  static const String visualizarRelatorios = 'VISUALIZAR_RELATORIOS';
  
  // Gestão
  static const String gerenciarInspetores = 'GERENCIAR_INSPETORES';
  static const String gerenciarUsuarios = 'GERENCIAR_USUARIOS';
  static const String gerenciarTemplates = 'GERENCIAR_TEMPLATES';
}

class RoleService {
  /// Verifica se pode criar inspeções
  static bool canCreateInspection(User user) {
    // Prioridade: permissões da API
    if (user.permissions.isNotEmpty) {
      return user.hasPermission(PermissionCodes.criarInspecao);
    }
    // Fallback: baseado no role
    return user.role == UserRole.supervisor || 
           user.role == UserRole.gestor ||
           user.role == UserRole.inspetor ||
           user.role == UserRole.diretor;
  }

  /// Verifica se pode editar inspeções
  static bool canEditInspection(User user) {
    // Prioridade: permissões da API
    if (user.permissions.isNotEmpty) {
      return user.hasPermission(PermissionCodes.editarInspecao);
    }
    // Fallback: baseado no role
    return user.role == UserRole.supervisor || 
           user.role == UserRole.gestor ||
           user.role == UserRole.diretor ||
           user.role == UserRole.inspetor; // Inspetor pode editar suas próprias inspeções
  }

  /// Verifica se pode deletar inspeções
  static bool canDeleteInspection(User user) {
    // Prioridade: permissões da API
    if (user.permissions.isNotEmpty) {
      return user.hasPermission(PermissionCodes.deletarInspecao);
    }
    // Fallback: baseado no role
    return user.role == UserRole.supervisor || 
           user.role == UserRole.diretor || 
           user.role == UserRole.gestor;
  }

  /// Verifica se pode gerenciar inspetores
  static bool canManageInspectors(User user) {
    // Prioridade: permissões da API
    if (user.permissions.isNotEmpty) {
      return user.hasPermission(PermissionCodes.gerenciarInspetores);
    }
    // Fallback: baseado no role
    return user.role == UserRole.supervisor || 
           user.role == UserRole.diretor ||
           user.role == UserRole.gestor;
  }

  /// Verifica se pode visualizar todas as inspeções
  static bool canViewAllInspections(User user) {
    // Prioridade: permissões da API
    if (user.permissions.isNotEmpty) {
      return user.hasPermission(PermissionCodes.visualizarTodasInspecoes);
    }
    // Fallback: baseado no role
    return user.role == UserRole.supervisor || 
           user.role == UserRole.gestor ||
           user.role == UserRole.diretor ||
           user.role == UserRole.inspetor;
  }

  /// Verifica se pode visualizar relatórios
  static bool canViewReports(User user) {
    // Prioridade: permissões da API
    if (user.permissions.isNotEmpty) {
      return user.hasPermission(PermissionCodes.visualizarRelatorios);
    }
    // Fallback: baseado no role
    return user.role == UserRole.supervisor || 
           user.role == UserRole.gestor ||
           user.role == UserRole.diretor ||
           user.role == UserRole.inspetor;
  }

  /// Verifica se pode executar inspeções (objetivo principal)
  static bool canExecuteInspections(User user) {
    // Prioridade: permissões da API
    if (user.permissions.isNotEmpty) {
      return user.hasPermission(PermissionCodes.executarInspecao);
    }
    // Fallback: baseado no role
    return user.role == UserRole.inspetor || 
           user.role == UserRole.supervisor || 
           user.role == UserRole.gestor ||
           user.role == UserRole.diretor;
  }

  /// Verifica se pode ver o mapa
  static bool canViewMap(User user) {
    // Todos podem ver o mapa (sem verificação de permissão)
    return true;
  }

  /// Verifica se pode ver o calendário
  static bool canViewCalendar(User user) {
    // Todos podem ver o calendário (sem verificação de permissão)
    return true;
  }

  /// Verifica se pode gerenciar usuários
  static bool canManageUsers(User user) {
    // Prioridade: permissões da API
    if (user.permissions.isNotEmpty) {
      return user.hasPermission(PermissionCodes.gerenciarUsuarios);
    }
    // Fallback: baseado no role
    return user.role == UserRole.diretor ||
           user.role == UserRole.gestor ||
           user.role == UserRole.supervisor;
  }

  /// Verifica se pode gerenciar templates de auditoria
  static bool canManageTemplates(User user) {
    // Prioridade: permissões da API
    if (user.permissions.isNotEmpty) {
      return user.hasPermission(PermissionCodes.gerenciarTemplates);
    }
    // Fallback: baseado no role
    return user.role == UserRole.diretor ||
           user.role == UserRole.supervisor ||
           user.role == UserRole.gestor;
  }

  static String getRoleDisplayName(UserRole role) {
    switch (role) {
      case UserRole.diretor:
        return 'Diretor';
      case UserRole.gestor:
        return 'Gestor';
      case UserRole.inspetor:
        return 'Inspetor';
      case UserRole.supervisor:
        return 'Supervisor';
    }
  }

  static String getRoleDescription(UserRole role) {
    switch (role) {
      case UserRole.diretor:
        return 'Gestão completa e visualização';
      case UserRole.gestor:
        return 'Gestão de inspeções e equipes';
      case UserRole.inspetor:
        return 'Executa inspeções atribuídas';
      case UserRole.supervisor:
        return 'Supervisiona e gerencia inspeções';
    }
  }
}
