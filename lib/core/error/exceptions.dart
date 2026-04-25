class ServerException implements Exception {
  final String message;
  final int? statusCode;
  ServerException(this.message, {this.statusCode});
}

class UnauthorizedException implements Exception {
  final String message;
  UnauthorizedException([this.message = 'unauthorized']);
}

class RefreshReuseException implements Exception {
  final String message;
  RefreshReuseException([this.message = 'refresh_token_reuse']);
}

class CacheException implements Exception {
  final String message;
  CacheException([this.message = 'cache_error']);
}
