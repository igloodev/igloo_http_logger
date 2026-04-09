part of 'igloo_http_logger.dart';

extension _IglooHttpLoggerHelpers on IglooHttpLogger {
  // =========================================================================
  // ITEMS COUNT
  // =========================================================================

  /// Extracts item count from response data.
  ///
  /// Returns the length if [data] is a root List, or if it's a Map containing
  /// a common wrapper key whose value is a List.
  ///
  /// If multiple wrapper keys match, returns null to avoid an ambiguous count.
  int? _extractItemsCount(dynamic data) {
    if (data is List) return data.length;
    if (data is Map) {
      const wrapperKeys = {
        'data', 'items', 'results', 'users', 'posts',
        'products', 'records', 'list', 'content', 'entries',
      };
      List? found;
      for (final key in wrapperKeys) {
        if (data[key] is List) {
          if (found != null) return null; // multiple matches — ambiguous
          found = data[key] as List;
        }
      }
      return found?.length;
    }
    return null;
  }

  // =========================================================================
  // STATUS HELPERS
  // =========================================================================

  String _getStatusColor(int statusCode) {
    if (statusCode >= 200 && statusCode < 300) return LoggerConstants.colorGreen;
    if (statusCode >= 300 && statusCode < 400) return LoggerConstants.colorYellow;
    if (statusCode >= 400) return LoggerConstants.colorRed;
    return LoggerConstants.colorCyan;
  }

  String _getStatusEmoji(int statusCode) {
    switch (statusCode) {
      // 2xx Success
      case 200: return '✅';
      case 201: return '✨';
      case 202: return '⏳';
      case 204: return '⭕';
      // 3xx Redirection
      case 301: return '↪️';
      case 302: return '🔄';
      case 304: return '📦';
      // 4xx Client Errors
      case 400: return '⚠️';
      case 401: return '🔒';
      case 403: return '🚫';
      case 404: return '🔍';
      case 405: return '🚷';
      case 408: return '⏱️';
      case 409: return '⚔️';
      case 422: return '📋';
      case 429: return '🚦';
      // 5xx Server Errors
      case 500: return '💥';
      case 502: return '🚧';
      case 503: return '🔴';
      case 504: return '⌛';
      default:
        if (statusCode >= 200 && statusCode < 300) return '✅';
        if (statusCode >= 300 && statusCode < 400) return '🔄';
        if (statusCode >= 400 && statusCode < 500) return '⚠️';
        if (statusCode >= 500) return '💥';
        return 'ℹ️';
    }
  }

  // =========================================================================
  // SIZE / DURATION FORMATTERS
  // =========================================================================

  String _formatDuration(int milliseconds) {
    if (milliseconds < 1000) return '${milliseconds}ms';
    if (milliseconds < 60000) return '${(milliseconds / 1000).toStringAsFixed(2)}s';
    final minutes = milliseconds ~/ 60000;
    final seconds = ((milliseconds % 60000) / 1000).toStringAsFixed(0);
    return '${minutes}m ${seconds}s';
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)}KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(2)}MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)}GB';
  }

  // =========================================================================
  // DECODE RESPONSE BYTES
  // =========================================================================

  /// Attempts to decode [bytes] into a Dart object.
  ///
  /// Tries JSON first (guided by Content-Type), then falls back to a UTF-8
  /// string, and finally returns null if decoding fails entirely.
  dynamic _decodeBytes(Uint8List bytes, Map<String, String> headers) {
    if (bytes.isEmpty) return null;
    try {
      final body = utf8.decode(bytes);
      final contentType = headers['content-type'] ?? '';
      if (contentType.contains('application/json') ||
          body.trimLeft().startsWith('{') ||
          body.trimLeft().startsWith('[')) {
        return _tryParseJson(body) ?? body;
      }
      return body;
    } catch (_) {
      return null;
    }
  }

  /// Tries to JSON-decode [text]. Returns null on failure.
  dynamic _tryParseJson(String text) {
    try {
      return jsonDecode(text);
    } catch (_) {
      return null;
    }
  }

  // =========================================================================
  // URL HELPER
  // =========================================================================

  /// Builds the base URL string (scheme + host + path) from a [Uri].
  String _baseUrl(Uri uri) {
    final origin = uri.hasAuthority
        ? '${uri.scheme}://${uri.host}${uri.port != 80 && uri.port != 443 && uri.port != 0 ? ':${uri.port}' : ''}'
        : '';
    return '$origin${uri.path}';
  }
}
