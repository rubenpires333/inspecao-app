import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:inspecao/models/user.dart';
import 'package:inspecao/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Serviço de autenticação com API backend
class AuthService {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _tokenExpiresAtKey = 'token_expires_at';
  static const String _userKey = 'current_user';

  final ApiService _apiService;
  final SharedPreferences _prefs;

  AuthService(this._apiService, this._prefs);

  /// Falha de rede / timeout (não inclui 401 de credenciais inválidas).
  static bool isLikelyNetworkFailure(Object e) {
    if (e is DioException) {
      final code = e.response?.statusCode;
      if (code == 401 || code == 403) return false;
      return e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.badCertificate ||
          (e.type == DioExceptionType.unknown && e.error != null);
    }
    final msg = e.toString().toLowerCase();
    return msg.contains('socket') ||
        msg.contains('failed host lookup') ||
        msg.contains('network') ||
        msg.contains('connection refused') ||
        msg.contains('connection reset') ||
        msg.contains('timed out') ||
        msg.contains('timeout');
  }

  /// Realiza login via API backend
  Future<User> login(String username, String password) async {
    try {
      final response = await _apiService.login(username, password);

      // Extrair dados da resposta
      final accessToken = response['accessToken'] as String;
      final refreshToken = response['refreshToken'] as String?;
      final expiresIn = response['expiresIn'] as int? ?? 3600;
      final userData = response['user'] as Map<String, dynamic>;

      // Calcular data de expiração
      final expiresAt = DateTime.now().add(Duration(seconds: expiresIn));

      // Salvar tokens de forma segura
      await _saveTokens(accessToken, refreshToken, expiresAt);

      // Converter dados do usuário para o modelo local
      User user = _mapUserFromResponse(userData);

      // Configurar token no ApiService para próximas requisições
      _apiService.setAuthToken(accessToken);

      // Buscar permissões do usuário da API
      try {
        // Extrair keycloakId do email ou username
        final keycloakId = userData['email']?.toString() ?? 
                          userData['username']?.toString() ?? 
                          user.email;
        final permissions = await _apiService.getUserPermissions(keycloakId);
        
        // Atualizar usuário com permissões
        user = user.copyWith(permissions: permissions);
      } catch (e) {
        // Se não conseguir buscar permissões, continua sem elas
        // O RoleService usará fallback baseado no role
        print('Aviso: Não foi possível buscar permissões do usuário: $e');
      }

      // Salvar usuário (com ou sem permissões)
      await _saveUser(user);

      return user;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Credenciais inválidas');
      } else if (e.response?.statusCode == 400) {
        throw Exception('Dados inválidos: ${e.response?.data}');
      } else if (e.response?.statusCode == 500) {
        // Erro 500 - verificar se é problema de autenticação no Keycloak
        final responseData = e.response?.data;
        final responseText = responseData?.toString().toLowerCase() ?? '';
        
        if (responseText.contains('autenticação') || 
            responseText.contains('keycloak') ||
            responseText.contains('unauthorized') ||
            responseText.contains('401')) {
          throw Exception('Erro na autenticação. Verifique suas credenciais ou entre em contato com o suporte.');
        }
        throw Exception('Erro no servidor. Tente novamente em alguns instantes.');
      } else {
        throw Exception('Erro ao fazer login: ${e.message}');
      }
    } catch (e) {
      throw Exception('Erro ao fazer login: $e');
    }
  }

  /// Realiza logout
  Future<void> logout() async {
    try {
      // Tentar fazer logout no servidor
      await _apiService.logout();
    } catch (e) {
      // Continuar mesmo se houver erro no servidor
      print('Erro ao fazer logout no servidor: $e');
    } finally {
      // Limpar dados locais
      await _clearTokens();
      await _clearUser();
      _apiService.clearAuthToken();
    }
  }

  /// Verifica se o usuário está autenticado
  Future<bool> isAuthenticated() async {
    final token = await getAccessToken();
    if (token == null) return false;

    final expiresAt = await getTokenExpiresAt();
    if (expiresAt == null) return false;

    // Verificar se o token ainda não expirou (com margem de 5 minutos)
    return DateTime.now().isBefore(expiresAt.subtract(const Duration(minutes: 5)));
  }

  /// Obtém o token de acesso atual
  Future<String?> getAccessToken() async {
    return _prefs.getString(_accessTokenKey);
  }

  /// Obtém o refresh token
  Future<String?> getRefreshToken() async {
    return _prefs.getString(_refreshTokenKey);
  }

  /// Obtém a data de expiração do token
  Future<DateTime?> getTokenExpiresAt() async {
    final expiresAtString = _prefs.getString(_tokenExpiresAtKey);
    if (expiresAtString == null) return null;
    return DateTime.parse(expiresAtString);
  }

  /// Renova o token usando refresh token
  Future<User> refreshToken() async {
    final refreshToken = await getRefreshToken();
    if (refreshToken == null) {
      throw Exception('Refresh token não encontrado');
    }

    try {
      final response = await _apiService.refreshToken(refreshToken);

      final accessToken = response['accessToken'] as String;
      final newRefreshToken = response['refreshToken'] as String?;
      final expiresIn = response['expiresIn'] as int? ?? 3600;
      final userData = response['user'] as Map<String, dynamic>;

      final expiresAt = DateTime.now().add(Duration(seconds: expiresIn));

      await _saveTokens(accessToken, newRefreshToken, expiresAt);

      final user = _mapUserFromResponse(userData);
      await _saveUser(user);

      _apiService.setAuthToken(accessToken);

      return user;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await logout();
        throw Exception('Sessão expirada. Faça login novamente.');
      }
      rethrow;
    }
  }

  /// Obtém o usuário atual
  Future<User?> getCurrentUser() async {
    final userJsonString = _prefs.getString(_userKey);
    if (userJsonString == null) return null;

    try {
      final userData = json.decode(userJsonString) as Map<String, dynamic>;
      if (_isPersistedAppUserJson(userData)) {
        try {
          return User.fromJson(userData);
        } catch (_) {
          // Continuar para formato API
        }
      }
      return _mapUserFromResponse(userData);
    } catch (e) {
      print('Erro ao parsear usuário: $e');
      return null;
    }
  }

  /// JSON gravado pelo modelo [User] ([toJson]), não pelo payload cru da API.
  bool _isPersistedAppUserJson(Map<String, dynamic> m) {
    return m.containsKey('id') &&
        m.containsKey('nome') &&
        m.containsKey('email') &&
        m['role'] is String &&
        m['roles'] == null;
  }

  /// Inicializa o token nas requisições se existir
  Future<void> initializeToken() async {
    final token = await getAccessToken();
    if (token != null) {
      _apiService.setAuthToken(token);
    }
  }

  /// Ao abrir a app: reativa o token no [ApiService], repara `exp` em falta,
  /// renova com refresh se o access tiver expirado e garante utilizador em prefs.
  /// Sem rede, reutiliza access token (mesmo expirado) e utilizador em cache para modo offline.
  Future<bool> ensureSessionRestored() async {
    await initializeToken();
    await _repairExpiresFromJwtIfNeeded();

    if (!await isAuthenticated()) {
      final rt = await getRefreshToken();
      if (rt != null && rt.isNotEmpty) {
        try {
          await refreshToken();
        } on DioException catch (e) {
          if (isLikelyNetworkFailure(e)) {
            if (!await activateOfflineSessionFromCache()) return false;
          } else {
            return false;
          }
        } catch (e) {
          if (isLikelyNetworkFailure(e)) {
            if (!await activateOfflineSessionFromCache()) return false;
          } else {
            return false;
          }
        }
      } else {
        if (!await activateOfflineSessionFromCache()) return false;
      }
    }

    if (await getCurrentUser() != null) {
      return true;
    }

    try {
      await _hydrateUserFromProfile();
    } catch (_) {
      final fallback = _userFromStoredAccessTokenClaims(await getAccessToken());
      if (fallback != null) {
        await _saveUser(fallback);
      }
    }

    return await getCurrentUser() != null;
  }

  /// Coloca o token em cache no [ApiService] e garante [User] em prefs (ex.: claims JWT).
  Future<bool> activateOfflineSessionFromCache() async {
    final access = await getAccessToken();
    if (access == null || access.isEmpty) return false;
    _apiService.setAuthToken(access);
    var user = await getCurrentUser();
    if (user == null) {
      user = _userFromStoredAccessTokenClaims(access);
      if (user != null) await _saveUser(user);
    }
    return await getCurrentUser() != null;
  }

  /// Após falha de rede no login: reentra se o identificador coincide com o último utilizador
  /// neste dispositivo e existe access token guardado (pode estar expirado).
  Future<User?> tryReuseCachedSessionForOfflineLogin(String identifier) async {
    await initializeToken();
    await _repairExpiresFromJwtIfNeeded();
    final access = await getAccessToken();
    if (access == null || access.isEmpty) return null;

    var user = await getCurrentUser();
    if (user == null) {
      user = _userFromStoredAccessTokenClaims(access);
      if (user != null) await _saveUser(user);
      user = await getCurrentUser();
    }
    if (user == null) return null;
    if (!_cachedUserMatchesIdentifier(user, identifier)) return null;

    _apiService.setAuthToken(access);
    return user;
  }

  bool _cachedUserMatchesIdentifier(User cached, String raw) {
    final t = raw.trim().toLowerCase();
    if (t.isEmpty) return false;
    return cached.email.trim().toLowerCase() == t ||
        cached.id.trim().toLowerCase() == t;
  }

  Future<void> _repairExpiresFromJwtIfNeeded() async {
    if (await getTokenExpiresAt() != null) return;
    final access = await getAccessToken();
    if (access == null || access.isEmpty) return;
    try {
      final map = json.decode(_jwtPayloadJson(access)) as Map<String, dynamic>;
      final exp = map['exp'];
      if (exp is int) {
        final expiresAt = DateTime.fromMillisecondsSinceEpoch(exp * 1000, isUtc: true);
        await _prefs.setString(_tokenExpiresAtKey, expiresAt.toIso8601String());
      }
    } catch (_) {}
  }

  String _jwtPayloadJson(String jwt) {
    final parts = jwt.split('.');
    if (parts.length < 2) {
      throw const FormatException('JWT inválido');
    }
    var seg = parts[1];
    final pad = seg.length % 4;
    if (pad != 0) {
      seg += '=' * (4 - pad);
    }
    return utf8.decode(base64Url.decode(seg));
  }

  Future<void> _hydrateUserFromProfile() async {
    final data = await _apiService.getProfile();
    var user = _mapUserFromResponse(data);
    try {
      final keycloakId = data['email']?.toString() ??
          data['username']?.toString() ??
          user.email;
      final permissions = await _apiService.getUserPermissions(keycloakId);
      user = user.copyWith(permissions: permissions);
    } catch (e) {
      print('Aviso: Não foi possível buscar permissões (perfil): $e');
    }
    await _saveUser(user);
  }

  User? _userFromStoredAccessTokenClaims(String? access) {
    if (access == null || access.isEmpty) return null;
    try {
      final map = json.decode(_jwtPayloadJson(access)) as Map<String, dynamic>;
      final sub = map['sub']?.toString() ?? '';
      final nome = map['name']?.toString() ??
          map['preferred_username']?.toString() ??
          map['email']?.toString() ??
          'Usuário';
      final email = map['email']?.toString() ?? '';
      return User(
        id: sub.isNotEmpty ? sub : email,
        nome: nome,
        email: email,
        role: UserRole.inspetor,
        dataCriacao: DateTime.now(),
        ultimoAcesso: DateTime.now(),
      );
    } catch (_) {
      return null;
    }
  }

  /// Salva tokens de forma segura
  Future<void> _saveTokens(String accessToken, String? refreshToken, DateTime expiresAt) async {
    await _prefs.setString(_accessTokenKey, accessToken);
    if (refreshToken != null) {
      await _prefs.setString(_refreshTokenKey, refreshToken);
    }
    await _prefs.setString(_tokenExpiresAtKey, expiresAt.toIso8601String());
  }

  /// Limpa tokens
  Future<void> _clearTokens() async {
    await _prefs.remove(_accessTokenKey);
    await _prefs.remove(_refreshTokenKey);
    await _prefs.remove(_tokenExpiresAtKey);
  }

  /// Salva usuário
  Future<void> _saveUser(User user) async {
    // Salvar como JSON string
    final userJson = json.encode(user.toJson());
    await _prefs.setString(_userKey, userJson);
  }

  /// Limpa usuário
  Future<void> _clearUser() async {
    await _prefs.remove(_userKey);
  }

  /// Mapeia dados do usuário da resposta da API para o modelo local
  User _mapUserFromResponse(Map<String, dynamic> userData) {
    // Mapear roles do backend para UserRole local
    final roles = (userData['roles'] as List<dynamic>?) ?? [];
    UserRole role = UserRole.inspetor; // Default - foco em execução de inspeções

    // Mapear roles do backend (ROLE_ADMIN, ROLE_DIRETOR, etc.)
    final rolesString = roles.map((r) => r.toString().toUpperCase()).join(',');
    
    if (userData['isAdmin'] == true || rolesString.contains('ROLE_ADMIN')) {
      role = UserRole.supervisor;
    } else if (rolesString.contains('ROLE_DIRETOR')) {
      role = UserRole.diretor;
    } else if (rolesString.contains('ROLE_GESTOR')) {
      role = UserRole.gestor;
    } else if (rolesString.contains('ROLE_SUPERVISOR')) {
      role = UserRole.supervisor;
    } else if (rolesString.contains('ROLE_INSPETOR') ||
        rolesString.contains('INSPETOR') ||
        rolesString.contains('ROLE_TECNICO') ||
        rolesString.contains('TECNICO')) {
      role = UserRole.inspetor;
    }

    return User(
      id: userData['id']?.toString() ?? '',
      nome: userData['nomeCompleto']?.toString() ??
            userData['nome']?.toString() ??
            userData['username']?.toString() ??
            userData['email']?.toString() ??
            'Usuário',
      email: userData['email']?.toString() ?? userData['username']?.toString() ?? '',
      role: role,
      avatar: userData['foto']?.toString(),
      dataCriacao: DateTime.now(), // Backend não retorna isso
      ultimoAcesso: DateTime.now(),
    );
  }
}
