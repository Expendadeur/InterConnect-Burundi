abstract class Failure {
  final String message;
  final int? statusCode;

  const Failure({required this.message, this.statusCode});

  @override
  String toString() => 'Failure(message: $message)';
}

class NetworkFailure extends Failure {
  const NetworkFailure({super.message = 'Erreur de connexion réseau'});
}

class ServerFailure extends Failure {
  const ServerFailure({required super.message, super.statusCode});
}

class AuthFailure extends Failure {
  const AuthFailure({required super.message, super.statusCode = 401});
}

class NotFoundFailure extends Failure {
  const NotFoundFailure({super.message = 'Ressource introuvable', super.statusCode = 404});
}

class ValidationFailure extends Failure {
  final Map<String, List<String>>? errors;

  const ValidationFailure({
    super.message = 'Données invalides',
    this.errors,
    super.statusCode = 422,
  });
}

class CacheFailure extends Failure {
  const CacheFailure({super.message = 'Erreur de cache local'});
}

class UnknownFailure extends Failure {
  const UnknownFailure({super.message = 'Une erreur inconnue est survenue'});
}
