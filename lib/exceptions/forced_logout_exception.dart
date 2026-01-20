/// Exceção customizada para forçar logout quando há erro 403/401
class ForcedLogoutException implements Exception {
  final String message;
  ForcedLogoutException(this.message);
  
  @override
  String toString() => message;
}
