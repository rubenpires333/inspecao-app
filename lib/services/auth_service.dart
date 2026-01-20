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
      final user = _mapUserFromResponse(userData);

      // Salvar usuário
      await _saveUser(user);

      // Configurar token no ApiService para próximas requisições
      _apiService.setAuthToken(accessToken);

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
        // Refresh token inválido, fazer logout
        await logout();
        throw Exception('Sessão expirada. Faça login novamente.');
      }
      throw Exception('Erro ao renovar token: ${e.message}');
    }
  }

  /// Obtém o usuário atual
  Future<User?> getCurrentUser() async {
    final userJsonString = _prefs.getString(_userKey);
    if (userJsonString == null) return null;

    try {
      // Tentar parsear como JSON
      final userData = json.decode(userJsonString) as Map<String, dynamic>;
      return _mapUserFromResponse(userData);
    } catch (e) {
      print('Erro ao parsear usuário: $e');
      return null;
    }
  }

  /// Inicializa o token nas requisições se existir
  Future<void> initializeToken() async {
    final token = await getAccessToken();
    if (token != null) {
      _apiService.setAuthToken(token);
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
    UserRole role = UserRole.inspetor; // Default

    if (userData['isAdmin'] == true) {
      role = UserRole.admin;
    } else if (roles.any((r) => r.toString().toLowerCase().contains('supervisor'))) {
      role = UserRole.supervisor;
    } else if (roles.any((r) => r.toString().toLowerCase().contains('admin'))) {
      role = UserRole.admin;
    } else if (roles.any((r) => r.toString().toLowerCase().contains('inspetor'))) {
      role = UserRole.inspetor;
    }

    return User(
      id: userData['id']?.toString() ?? '',
      nome: userData['nomeCompleto']?.toString() ?? 
            userData['username']?.toString() ?? 
            userData['email']?.toString() ?? 'Usuário',
      email: userData['email']?.toString() ?? userData['username']?.toString() ?? '',
      role: role,
      avatar: userData['foto']?.toString(),
      dataCriacao: DateTime.now(), // Backend não retorna isso
      ultimoAcesso: DateTime.now(),
    );
  }
}
