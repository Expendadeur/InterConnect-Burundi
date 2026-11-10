class AppException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  const AppException({
    required this.message,
    this.statusCode,
    this.data,
  });

  @override
  String toString() => 'AppException(message: $message, statusCode: $statusCode)';
}

class NetworkException extends AppException {
  const NetworkException({super.message = 'Erreur de connexion réseau'});
}

class UnauthorizedException extends AppException {
  const UnauthorizedException({super.message = 'Non autorisé'}) : super(statusCode: 401);
}

class NotFoundException extends AppException {
  const NotFoundException({super.message = 'Ressource introuvable'}) : super(statusCode: 404);
}

class ServerException extends AppException {
  const ServerException({super.message = 'Erreur serveur interne'}) : super(statusCode: 500);
}

class ValidationException extends AppException {
  final Map<String, List<String>>? errors;

  const ValidationException({
    super.message = 'Données invalides',
    this.errors,
  }) : super(statusCode: 422);
}

class TimeoutException extends AppException {
  const TimeoutException({super.message = 'La requête a expiré'});
}

class CacheException extends AppException {
  const CacheException({super.message = 'Erreur de cache local'});
}
