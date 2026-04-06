import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'logger_constants.dart';

/// Igloo HTTP Logger — a drop-in logging wrapper for the `http` package.
///
/// Wraps any [http.Client] (defaults to a plain [http.Client]) and logs
/// every request/response with ANSI colors and emojis, just like
/// [IglooDioLogger] does for Dio.
///
/// Usage:
/// ```dart
/// final client = IglooHttpLogger();
/// final response = await client.get(Uri.parse('https://api.example.com/users'));
/// client.close(); // close when done
/// ```
///
/// With custom inner client:
/// ```dart
/// final client = IglooHttpLogger(client: MyCustomClient());
/// ```
class IglooHttpLogger extends http.BaseClient {
  /// Creates an [IglooHttpLogger] with customizable options.
  ///
  /// [client] — the inner [http.Client] to delegate requests to.
  ///            Defaults to a fresh [http.Client].
  IglooHttpLogger({
    http.Client? client,
    this.logRequestHeader = true,
    this.logRequestBody = true,
    this.logResponseHeader = false,
    this.logResponseBody = true,
    this.logErrors = true,
    this.maxWidth = 90,
    this.includeEndpoints,
    this.excludeEndpoints,
    this.onlyErrors = false,
    this.slowRequestThresholdMs,
  })  : _inner = client ?? http.Client(),
        assert(maxWidth >= 60 && maxWidth <= 200, LoggerConstants.textMaxWidthError);

  final http.Client _inner;

  /// Whether to log request headers
  final bool logRequestHeader;

  /// Whether to log request body
  final bool logRequestBody;

  /// Whether to log response headers
  final bool logResponseHeader;

  /// Whether to log response body
  final bool logResponseBody;

  /// Whether to log errors
  final bool logErrors;

  /// Maximum width of the log output (used for border formatting)
  ///
  /// Valid range: 60–200. Values outside this range throw an [AssertionError].
  final int maxWidth;

  /// Only log endpoints matching these regex patterns
  ///
  /// Example: `[r'/api/v1/auth/.*', r'/api/v1/users/.*']`
  final List<String>? includeEndpoints;

  /// Exclude endpoints matching these regex patterns
  ///
  /// Example: `[r'/api/v1/health', r'/api/v1/ping']`
  final List<String>? excludeEndpoints;

  /// Only log error responses (4xx and 5xx status codes)
  ///
  /// When true, successful responses (2xx, 3xx) are not logged.
  final bool onlyErrors;

  /// Threshold for logging slow requests (in milliseconds)
  ///
  /// Only logs requests that take longer than this duration.
  ///
  /// Example: `slowRequestThresholdMs: 500` logs requests taking ≥ 500 ms.
  final int? slowRequestThresholdMs;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final startTime = DateTime.now().millisecondsSinceEpoch;

    if (kDebugMode && _shouldLogEndpoint(request.url.path)) {
      _printRequest(request);
    }

    try {
      final streamedResponse = await _inner.send(request);

      // Buffer the response stream so we can both log and return the body.
      final bytes = await streamedResponse.stream.toBytes();
      final duration = DateTime.now().millisecondsSinceEpoch - startTime;

      if (kDebugMode && _shouldLogResponse(streamedResponse.statusCode, request.url.path, duration)) {
        _printResponse(request, streamedResponse, bytes, duration);
      }

      // Return a new StreamedResponse backed by the buffered bytes.
      return http.StreamedResponse(
        Stream.value(bytes),
        streamedResponse.statusCode,
        contentLength: streamedResponse.contentLength,
        request: streamedResponse.request,
        headers: streamedResponse.headers,
        isRedirect: streamedResponse.isRedirect,
        persistentConnection: streamedResponse.persistentConnection,
        reasonPhrase: streamedResponse.reasonPhrase,
      );
    } catch (e) {
      final duration = DateTime.now().millisecondsSinceEpoch - startTime;
      if (kDebugMode && logErrors && _shouldLogEndpoint(request.url.path)) {
        _printError(request, e, duration);
      }
      rethrow;
    }
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }

  // =========================================================================
  // FILTERING
  // =========================================================================

  /// Returns true if this endpoint should be logged.
  bool _shouldLogEndpoint(String path) {
    if (includeEndpoints != null && includeEndpoints!.isNotEmpty) {
      final matches = includeEndpoints!.any((pattern) => RegExp(pattern).hasMatch(path));
      if (!matches) return false;
    }

    if (excludeEndpoints != null && excludeEndpoints!.isNotEmpty) {
      final matches = excludeEndpoints!.any((pattern) => RegExp(pattern).hasMatch(path));
      if (matches) return false;
    }

    return true;
  }

  /// Returns true if this response should be logged.
  bool _shouldLogResponse(int statusCode, String path, int duration) {
    if (!_shouldLogEndpoint(path)) return false;

    if (onlyErrors && statusCode >= 200 && statusCode < 400) return false;

    if (slowRequestThresholdMs != null && duration < slowRequestThresholdMs!) return false;

    return true;
  }

  // =========================================================================
  // PRINT — REQUEST
  // =========================================================================

  void _printRequest(http.BaseRequest request) {
    final method = request.method.toUpperCase();
    final uri = request.url;
    final baseUrl = _baseUrl(uri);
    final hasQueryParams = uri.queryParameters.isNotEmpty;

    // Body is only accessible for http.Request (not StreamedRequest)
    final requestSize = request is http.Request ? request.bodyBytes.length : 0;
    final requestSizeText = requestSize > 0 ? _formatSize(requestSize) : null;

    debugPrint('');
    const topBorder = '${LoggerConstants.borderTop} ${LoggerConstants.textHttpRequest} ';
    final remainingWidth = maxWidth - topBorder.length;
    debugPrint('${LoggerConstants.colorBold}${LoggerConstants.colorCyan}$topBorder${LoggerConstants.borderHorizontal * remainingWidth}${LoggerConstants.colorReset}');

    // Method and URL
    if (requestSizeText != null) {
      debugPrint(
        '${LoggerConstants.colorCyan}${LoggerConstants.borderVertical}${LoggerConstants.colorReset} '
        '${LoggerConstants.colorBold}${LoggerConstants.colorBlue}$method${LoggerConstants.colorReset} '
        '${LoggerConstants.colorDim}$baseUrl${LoggerConstants.colorReset} '
        '${LoggerConstants.colorDim}│${LoggerConstants.colorReset} '
        '${LoggerConstants.colorYellow}$requestSizeText${LoggerConstants.colorReset}',
      );
    } else {
      debugPrint(
        '${LoggerConstants.colorCyan}${LoggerConstants.borderVertical}${LoggerConstants.colorReset} '
        '${LoggerConstants.colorBold}${LoggerConstants.colorBlue}$method${LoggerConstants.colorReset} '
        '${LoggerConstants.colorDim}$baseUrl${LoggerConstants.colorReset}',
      );
    }

    // Query parameters
    if (hasQueryParams) {
      debugPrint('${LoggerConstants.colorCyan}${LoggerConstants.borderVertical}${LoggerConstants.colorReset}');
      debugPrint('${LoggerConstants.colorCyan}${LoggerConstants.borderVertical}${LoggerConstants.colorReset} ${LoggerConstants.colorDim}${LoggerConstants.textQueryParams}${LoggerConstants.colorReset}');
      uri.queryParameters.forEach((key, value) {
        debugPrint('${LoggerConstants.colorCyan}${LoggerConstants.borderVertical}${LoggerConstants.colorReset}   ${LoggerConstants.colorGrey}$key:${LoggerConstants.colorReset} ${LoggerConstants.colorYellow}$value${LoggerConstants.colorReset}');
      });
    }

    // Headers
    if (logRequestHeader && request.headers.isNotEmpty) {
      debugPrint('${LoggerConstants.colorCyan}${LoggerConstants.borderVertical}${LoggerConstants.colorReset}');
      debugPrint('${LoggerConstants.colorCyan}${LoggerConstants.borderVertical}${LoggerConstants.colorReset} ${LoggerConstants.colorDim}${LoggerConstants.textHeaders}${LoggerConstants.colorReset}');
      request.headers.forEach((key, value) {
        _printHeaderValue(key, value, LoggerConstants.colorCyan);
      });
    }

    // Body (only for http.Request)
    if (logRequestBody && request is http.Request && request.body.isNotEmpty) {
      debugPrint('${LoggerConstants.colorCyan}${LoggerConstants.borderVertical}${LoggerConstants.colorReset}');
      debugPrint('${LoggerConstants.colorCyan}${LoggerConstants.borderVertical}${LoggerConstants.colorReset} ${LoggerConstants.colorDim}${LoggerConstants.textBody}${LoggerConstants.colorReset}');
      final body = _tryParseJson(request.body) ?? request.body;
      _printLongText(_formatJson(body), LoggerConstants.colorCyan);
    }

    debugPrint('${LoggerConstants.colorCyan}${LoggerConstants.borderBottom}${LoggerConstants.borderHorizontal * (maxWidth - 1)}${LoggerConstants.colorReset}');
  }

  // =========================================================================
  // PRINT — RESPONSE
  // =========================================================================

  void _printResponse(
    http.BaseRequest request,
    http.StreamedResponse response,
    Uint8List bytes,
    int duration,
  ) {
    final statusCode = response.statusCode;
    final method = request.method.toUpperCase();
    final uri = request.url;
    final baseUrl = _baseUrl(uri);
    final hasQueryParams = uri.queryParameters.isNotEmpty;
    final color = _getStatusColor(statusCode);
    final durationText = _formatDuration(duration);

    // Decode response body
    final bodyData = _decodeBytes(bytes, response.headers);
    final responseSizeText = _formatSize(bytes.length);

    // Items count — root List or common wrapper keys (data, items, results, etc.)
    final itemsCount = _extractItemsCount(bodyData);

    debugPrint('');
    const topBorder = '${LoggerConstants.borderTop} ${LoggerConstants.textHttpResponse} ';
    final remainingWidth = maxWidth - topBorder.length;
    debugPrint('${LoggerConstants.colorBold}$color$topBorder${LoggerConstants.borderHorizontal * remainingWidth}${LoggerConstants.colorReset}');

    // Method and URL
    debugPrint(
      '$color${LoggerConstants.borderVertical}${LoggerConstants.colorReset} '
      '${LoggerConstants.colorBold}${LoggerConstants.colorBlue}$method${LoggerConstants.colorReset} '
      '${LoggerConstants.colorDim}$baseUrl${LoggerConstants.colorReset}',
    );

    // Query parameters
    if (hasQueryParams) {
      debugPrint(
        '$color${LoggerConstants.borderVertical}${LoggerConstants.colorReset} '
        '${LoggerConstants.colorDim}${LoggerConstants.textQueryParams}${LoggerConstants.colorReset} '
        '${LoggerConstants.colorGrey}${uri.queryParameters.entries.map((e) => '${e.key}=${e.value}').join('&')}${LoggerConstants.colorReset}',
      );
    }

    // Status line
    final itemsInfo = itemsCount != null
        ? ' ${LoggerConstants.colorDim}${LoggerConstants.separator} ${LoggerConstants.textItems}${LoggerConstants.colorReset} ${LoggerConstants.colorCyan}$itemsCount${LoggerConstants.colorReset}'
        : '';
    debugPrint(
      '$color${LoggerConstants.borderVertical}${LoggerConstants.colorReset} '
      '${LoggerConstants.colorDim} ${LoggerConstants.textStatus}${LoggerConstants.colorReset} $color$statusCode${LoggerConstants.colorReset} ${_getStatusEmoji(statusCode)} '
      '${LoggerConstants.colorDim}${LoggerConstants.separator} ${LoggerConstants.textDuration}${LoggerConstants.colorReset} ${LoggerConstants.colorMagenta}$durationText${LoggerConstants.colorReset} '
      '${LoggerConstants.colorDim}${LoggerConstants.separator} ${LoggerConstants.textSize}${LoggerConstants.colorReset} ${LoggerConstants.colorYellow}$responseSizeText${LoggerConstants.colorReset}'
      '$itemsInfo',
    );

    // Response headers
    if (logResponseHeader && response.headers.isNotEmpty) {
      debugPrint('$color${LoggerConstants.borderVertical}${LoggerConstants.colorReset}');
      debugPrint('$color${LoggerConstants.borderVertical}${LoggerConstants.colorReset} ${LoggerConstants.colorDim}${LoggerConstants.textHeaders}${LoggerConstants.colorReset}');
      response.headers.forEach((key, value) {
        _printHeaderValue(key, value, color);
      });
    }

    // Response body
    if (logResponseBody && bodyData != null) {
      debugPrint('$color${LoggerConstants.borderVertical}${LoggerConstants.colorReset}');
      debugPrint('$color${LoggerConstants.borderVertical}${LoggerConstants.colorReset} ${LoggerConstants.colorDim}${LoggerConstants.textBody}${LoggerConstants.colorReset}');
      _printLongText(_formatJson(bodyData), color);
    }

    debugPrint('$color${LoggerConstants.borderBottom}${LoggerConstants.borderHorizontal * (maxWidth - 1)}${LoggerConstants.colorReset}');
  }

  // =========================================================================
  // PRINT — ERROR
  // =========================================================================

  void _printError(http.BaseRequest request, Object error, int duration) {
    final method = request.method.toUpperCase();
    final uri = request.url;
    final baseUrl = _baseUrl(uri);
    final hasQueryParams = uri.queryParameters.isNotEmpty;
    final durationText = _formatDuration(duration);

    final errorMessage = error is http.ClientException ? error.message : error.toString();

    debugPrint('');
    const topBorder = '${LoggerConstants.borderTop} ${LoggerConstants.textHttpError} ';
    final remainingWidth = maxWidth - topBorder.length;
    debugPrint('${LoggerConstants.colorBold}${LoggerConstants.colorRed}$topBorder${LoggerConstants.borderHorizontal * remainingWidth}${LoggerConstants.colorReset}');

    // Method and URL
    debugPrint(
      '${LoggerConstants.colorRed}${LoggerConstants.borderVertical}${LoggerConstants.colorReset} '
      '${LoggerConstants.colorBold}${LoggerConstants.colorBlue}$method${LoggerConstants.colorReset} '
      '${LoggerConstants.colorDim}$baseUrl${LoggerConstants.colorReset}',
    );

    // Query parameters
    if (hasQueryParams) {
      debugPrint(
        '${LoggerConstants.colorRed}${LoggerConstants.borderVertical}${LoggerConstants.colorReset} '
        '${LoggerConstants.colorDim}${LoggerConstants.textQueryParams}${LoggerConstants.colorReset} '
        '${LoggerConstants.colorGrey}${uri.queryParameters.entries.map((e) => '${e.key}=${e.value}').join('&')}${LoggerConstants.colorReset}',
      );
    }

    // Error type and duration
    debugPrint(
      '${LoggerConstants.colorRed}${LoggerConstants.borderVertical}${LoggerConstants.colorReset} '
      '${LoggerConstants.colorBold}${error.runtimeType}${LoggerConstants.colorReset} '
      '${LoggerConstants.colorDim}│ ${LoggerConstants.textDuration}${LoggerConstants.colorReset} ${LoggerConstants.colorMagenta}$durationText${LoggerConstants.colorReset}',
    );
    debugPrint('${LoggerConstants.colorRed}${LoggerConstants.borderVertical}${LoggerConstants.colorReset} $errorMessage');

    debugPrint('${LoggerConstants.colorRed}${LoggerConstants.borderBottom}${LoggerConstants.borderHorizontal * (maxWidth - 1)}${LoggerConstants.colorReset}');
  }

  // =========================================================================
  // HELPERS
  // =========================================================================

  /// Builds the base URL string (origin + path) from a [Uri].
  String _baseUrl(Uri uri) {
    final origin = uri.hasAuthority ? '${uri.scheme}://${uri.host}${uri.port != 80 && uri.port != 443 && uri.port != 0 ? ':${uri.port}' : ''}' : '';
    return '$origin${uri.path}';
  }

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

  /// Extracts item count from response data.
  ///
  /// Returns the length if [data] is a root List, or if it's a Map containing
  /// a common wrapper key whose value is a List.
  ///
  /// Wrapper keys are checked in priority order:
  /// `data` → `items` → `results` → `users` → `posts` → `products` →
  /// `records` → `list` → `content` → `entries`
  ///
  /// If the response contains multiple matching wrapper keys, `Items:` is
  /// hidden to avoid showing an ambiguous count.
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
          if (found != null) return null; // multiple matches — ambiguous, skip
          found = data[key] as List;
        }
      }
      return found?.length;
    }
    return null;
  }

  String _getStatusColor(int statusCode) {
    if (statusCode >= 200 && statusCode < 300) return LoggerConstants.colorGreen;
    if (statusCode >= 300 && statusCode < 400) return LoggerConstants.colorYellow;
    if (statusCode >= 400) return LoggerConstants.colorRed;
    return LoggerConstants.colorCyan;
  }

  /// Format duration in human-readable format
  String _formatDuration(int milliseconds) {
    if (milliseconds < 1000) {
      return '${milliseconds}ms';
    } else if (milliseconds < 60000) {
      return '${(milliseconds / 1000).toStringAsFixed(2)}s';
    } else {
      final minutes = milliseconds ~/ 60000;
      final seconds = ((milliseconds % 60000) / 1000).toStringAsFixed(0);
      return '${minutes}m ${seconds}s';
    }
  }

  /// Format size in human-readable format
  String _formatSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)}KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(2)}MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)}GB';
  }

  /// Format header value — wrap long values (e.g. JWT tokens) to multiple lines
  void _printHeaderValue(String key, String value, String borderColor) {
    const maxLength = 100;
    if (value.length <= maxLength) {
      debugPrint('$borderColor${LoggerConstants.borderVertical}${LoggerConstants.colorReset}   ${LoggerConstants.colorGrey}$key:${LoggerConstants.colorReset} ${LoggerConstants.colorYellow}$value${LoggerConstants.colorReset}');
      return;
    }
    debugPrint('$borderColor${LoggerConstants.borderVertical}${LoggerConstants.colorReset}   ${LoggerConstants.colorGrey}$key:${LoggerConstants.colorReset}');
    var remaining = value;
    while (remaining.isNotEmpty) {
      if (remaining.length <= maxLength) {
        debugPrint('$borderColor${LoggerConstants.borderVertical}${LoggerConstants.colorReset}     ${LoggerConstants.colorYellow}$remaining${LoggerConstants.colorReset}');
        break;
      }
      var breakPoint = maxLength;
      if (value.contains('.') && key.toLowerCase() == 'authorization') {
        final dotIndex = remaining.lastIndexOf('.', maxLength);
        if (dotIndex > maxLength - 50 && dotIndex < maxLength) breakPoint = dotIndex + 1;
      }
      debugPrint('$borderColor${LoggerConstants.borderVertical}${LoggerConstants.colorReset}     ${LoggerConstants.colorYellow}${remaining.substring(0, breakPoint)}${LoggerConstants.colorReset}');
      remaining = remaining.substring(breakPoint);
    }
  }

  String _getStatusEmoji(int statusCode) {
    switch (statusCode) {
      case 200: return '✅';
      case 201: return '✨';
      case 202: return '⏳';
      case 204: return '⭕';
      case 301: return '↪️';
      case 302: return '🔄';
      case 304: return '📦';
      case 400: return '⚠️';
      case 401: return '🔒';
      case 403: return '🚫';
      case 404: return '🔍';
      case 405: return '🚷';
      case 408: return '⏱️';
      case 409: return '⚔️';
      case 422: return '📋';
      case 429: return '🚦';
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

  String _formatJson(dynamic data) {
    try {
      if (data is Map || data is List) {
        const encoder = JsonEncoder.withIndent('  ');
        return encoder.convert(data);
      }
      return data.toString();
    } catch (_) {
      return data.toString();
    }
  }

  /// Prints [text] line by line with border prefix and JSON colorization.
  void _printLongText(String text, String color) {
    final lines = text.split('\n');

    // Stack to track nested object/array names with their indent levels
    final stack = <MapEntry<String, int>>[];
    // Stack to track nested array depths — each entry is the current item index (-1 = no items yet)
    final arrayStack = <int>[];

    for (final originalLine in lines) {
      var line = originalLine;
      final indent = line.length - line.trimLeft().length;
      final trimmed = line.trim();

      // Track opening braces/brackets with their keys
      final openMatch = RegExp(r'"([^"]+)"\s*:\s*[\{\[]').firstMatch(line);
      if (openMatch != null) {
        final key = openMatch.group(1)!;
        stack.add(MapEntry(key, indent));
        if (line.contains('[') && !line.contains('[]')) arrayStack.add(-1);
      }

      // Track standalone array opening
      if (trimmed == '[') arrayStack.add(-1);

      // Increment item index when a new object starts inside an array
      if (arrayStack.isNotEmpty && trimmed == '{') {
        arrayStack[arrayStack.length - 1]++;
      }

      // Add closing comments
      line = _addClosingComments(line, stack, arrayStack, indent);

      // Pop array stack on closing bracket
      if ((trimmed == ']' || trimmed == '],') && arrayStack.isNotEmpty) {
        arrayStack.removeLast();
      }

      final colorizedLine = _colorizeJsonLine(line, color);

      if (line.length <= 800) {
        debugPrint('$color${LoggerConstants.borderVertical}${LoggerConstants.colorReset}   $colorizedLine');
      } else {
        _printVeryLongLine(line, color);
      }
    }
  }

  /// Adds closing comments to `}` and `]` tokens.
  /// - Named closings  → cyan   `// keyName`
  /// - Array item closings → yellow `// [0]`, `// [1]`, etc.
  String _addClosingComments(
    String line,
    List<MapEntry<String, int>> stack,
    List<int> arrayStack,
    int currentIndent,
  ) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) return line;
    final lineIndent = ' ' * currentIndent;

    if (trimmed == ']' || trimmed == '],') {
      final comma = trimmed.endsWith(',') ? ',' : '';
      if (stack.isNotEmpty && currentIndent == stack.last.value) {
        final name = stack.removeLast().key;
        return '$lineIndent]$comma ${LoggerConstants.colorCyan}// $name${LoggerConstants.colorReset}';
      }
    }

    if (trimmed == '}' || trimmed == '},') {
      final comma = trimmed.endsWith(',') ? ',' : '';
      if (stack.isNotEmpty && currentIndent == stack.last.value) {
        final name = stack.removeLast().key;
        return '$lineIndent}$comma ${LoggerConstants.colorCyan}// $name${LoggerConstants.colorReset}';
      }
      if (arrayStack.isNotEmpty) {
        final itemIndex = arrayStack.last;
        return '$lineIndent}$comma ${LoggerConstants.colorYellow}// [$itemIndex]${LoggerConstants.colorReset}';
      }
    }

    return line;
  }

  /// Colorizes JSON keys and values with ANSI codes.
  String _colorizeJsonLine(String line, String color) {
    const structuralTokens = {'{', '}', '[', ']', '},', '],', '{}', '[]'};
    if (structuralTokens.contains(line.trim())) {
      return '${LoggerConstants.colorDim}$line${LoggerConstants.colorReset}';
    }

    final keyValuePattern = RegExp(r'^(\s*)"([^"]+)"\s*:\s*(.*)$');
    final match = keyValuePattern.firstMatch(line);

    if (match != null) {
      final indentStr = match.group(1) ?? '';
      final key = match.group(2) ?? '';
      final value = (match.group(3) ?? '').trimRight();

      final String colorizedValue;
      if (value.startsWith('"')) {
        colorizedValue = '${LoggerConstants.colorYellow}$value${LoggerConstants.colorReset}';
      } else if (RegExp(r'^-?\d+\.?\d*,?$').hasMatch(value)) {
        colorizedValue = '${LoggerConstants.colorMagenta}$value${LoggerConstants.colorReset}';
      } else if (value == 'true,' || value == 'false,' || value == 'null,' || value == 'true' || value == 'false' || value == 'null') {
        colorizedValue = '${LoggerConstants.colorCyan}$value${LoggerConstants.colorReset}';
      } else if (value == '{' || value == '[') {
        colorizedValue = '${LoggerConstants.colorDim}$value${LoggerConstants.colorReset}';
      } else {
        colorizedValue = '$color$value${LoggerConstants.colorReset}';
      }

      return '$indentStr${LoggerConstants.colorGrey}"$key"${LoggerConstants.colorReset}: $colorizedValue';
    }

    return line;
  }

  /// Splits very long lines (> 800 chars) at word boundaries to avoid truncation.
  void _printVeryLongLine(String line, String color) {
    const maxLength = 800;
    var remaining = line;
    while (remaining.isNotEmpty) {
      if (remaining.length <= maxLength) {
        debugPrint('$color${LoggerConstants.borderVertical}${LoggerConstants.colorReset}   $remaining');
        break;
      }
      var breakPoint = maxLength;
      const searchStart = maxLength - 100;
      for (var i = maxLength; i >= searchStart && i < remaining.length; i--) {
        if (remaining[i] == ' ' || remaining[i] == ',' || remaining[i] == ';' || remaining[i] == ':') {
          breakPoint = i + 1;
          break;
        }
      }
      debugPrint('$color${LoggerConstants.borderVertical}${LoggerConstants.colorReset}   ${remaining.substring(0, breakPoint).trimRight()}');
      remaining = remaining.substring(breakPoint).trimLeft();
    }
  }
}
