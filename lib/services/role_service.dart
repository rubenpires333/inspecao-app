import 'package:inspecao/models/user.dart';

class RoleService {
  static bool canCreateInspection(UserRole role) {
    return role == UserRole.admin || role == UserRole.supervisor;
  }

  static bool canEditInspection(UserRole role) {
    return role == UserRole.admin || role == UserRole.supervisor;
  }

  static bool canDeleteInspection(UserRole role) {
    return role == UserRole.admin;
  }

  static bool canManageInspectors(UserRole role) {
    return role == UserRole.admin;
  }

  static bool canViewAllInspections(UserRole role) {
    return role == UserRole.admin || role == UserRole.supervisor;
  }

  static bool canViewReports(UserRole role) {
    return role == UserRole.admin || role == UserRole.supervisor;
  }

  static bool canViewMap(UserRole role) {
    return true; // Todos podem ver o mapa
  }

  static bool canViewCalendar(UserRole role) {
    return true; // Todos podem ver o calendário
  }

  static String getRoleDisplayName(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'Administrador';
      case UserRole.supervisor:
        return 'Supervisor';
      case UserRole.inspetor:
        return 'Inspetor';
    }
  }

  static String getRoleDescription(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'Acesso completo ao sistema';
      case UserRole.supervisor:
        return 'Pode criar e gerenciar inspeções';
      case UserRole.inspetor:
        return 'Executa inspeções atribuídas';
    }
  }
}
