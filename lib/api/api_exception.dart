class ApiException implements Exception {
  final int statusCode;
  final String message;
  final StackTrace? stackTrace;

  ApiException({
    required this.statusCode,
    required this.message,
    this.stackTrace,
  });

  @override
  String toString() => 'ApiException($statusCode): $message';
}