import 'package:dio/dio.dart';
import 'package:inspecao/models/inspection.dart';
import 'package:inspecao/models/evidence.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  late Dio _dio;
  String? _baseUrl;
  
  void initialize({required String baseUrl}) {
    _baseUrl = baseUrl;
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Interceptor para logs (apenas em debug)
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (obj) => print(obj),
    ));
  }

  // Métodos de autenticação
  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await _dio.post('/api/v1/auth/login', data: {
      'username': username,
      'password': password,
    });
    return response.data;
  }

  Future<void> logout() async {
    await _dio.post('/api/v1/auth/logout');
  }

  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    final response = await _dio.post('/api/v1/auth/refresh-token', data: {
      'refreshToken': refreshToken,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> getProfile() async {
    final response = await _dio.get('/api/v1/auth/profile');
    return response.data;
  }

  // Sincronização de inspeções
  Future<List<Map<String, dynamic>>> syncInspections(List<Map<String, dynamic>> inspections) async {
    final response = await _dio.post('/api/inspections/sync', data: {
      'inspections': inspections,
    });
    return List<Map<String, dynamic>>.from(response.data['synced']);
  }

  Future<List<Map<String, dynamic>>> getInspectionsFromServer() async {
    final response = await _dio.get('/api/inspections');
    return List<Map<String, dynamic>>.from(response.data);
  }

  Future<Map<String, dynamic>> createInspectionOnServer(Map<String, dynamic> inspection) async {
    final response = await _dio.post('/api/inspections', data: inspection);
    return response.data;
  }

  Future<Map<String, dynamic>> updateInspectionOnServer(String id, Map<String, dynamic> inspection) async {
    final response = await _dio.put('/api/inspections/$id', data: inspection);
    return response.data;
  }

  Future<void> deleteInspectionOnServer(String id) async {
    await _dio.delete('/api/inspections/$id');
  }

  // Sincronização de evidências
  Future<List<Map<String, dynamic>>> syncEvidences(List<Map<String, dynamic>> evidences) async {
    final response = await _dio.post('/api/evidences/sync', data: {
      'evidences': evidences,
    });
    return List<Map<String, dynamic>>.from(response.data['synced']);
  }

  Future<List<Map<String, dynamic>>> getEvidencesFromServer(String inspectionId) async {
    final response = await _dio.get('/api/inspections/$inspectionId/evidences');
    return List<Map<String, dynamic>>.from(response.data);
  }

  Future<Map<String, dynamic>> uploadEvidence(Map<String, dynamic> evidence) async {
    final response = await _dio.post('/api/evidences', data: evidence);
    return response.data;
  }

  // Sincronização de usuários
  Future<List<Map<String, dynamic>>> getUsersFromServer() async {
    final response = await _dio.get('/api/users');
    return List<Map<String, dynamic>>.from(response.data);
  }

  // Sincronização de inspetores
  Future<List<Map<String, dynamic>>> getInspectorsFromServer() async {
    final response = await _dio.get('/api/inspectors');
    return List<Map<String, dynamic>>.from(response.data);
  }

  // Sincronização de notificações
  Future<List<Map<String, dynamic>>> getNotificationsFromServer() async {
    final response = await _dio.get('/api/notifications');
    return List<Map<String, dynamic>>.from(response.data);
  }

  // Upload de arquivos
  Future<Map<String, dynamic>> uploadFile(String filePath, String inspectionId, String evidenceId) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
      'inspectionId': inspectionId,
      'evidenceId': evidenceId,
    });

    final response = await _dio.post('/api/upload', data: formData);
    return response.data;
  }

  // Métodos de configuração
  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  void clearAuthToken() {
    _dio.options.headers.remove('Authorization');
  }

  String? get baseUrl => _baseUrl;
}
