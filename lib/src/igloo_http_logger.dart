import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'logger_constants.dart';

part '_helpers.dart';
part '_printer.dart';
part '_json_formatter.dart';
part '_curl_builder.dart';

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
    this.logCurl = false,
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

  /// Whether to print a cURL command after each request block.
  ///
  /// The cURL is printed in a full bordered block (`╔═══ 🔗 cURL ═══...`),
  /// consistent with the request/response block style.
  ///
  /// Body handling:
  /// - [http.Request] with a non-empty body → `-d '...'` (single quotes safely escaped)
  /// - [http.MultipartRequest] → `--form 'key=value'` per field; `--form 'key=@"filename"'` per file
  /// - [http.StreamedRequest] → body line omitted; a placeholder note is shown above the command
  ///
  /// cURL syntax is bash/zsh/fish. Windows CMD users should run under WSL or
  /// Git Bash, or adapt `\` → `^` and single quotes → double quotes manually.
  ///
  /// Defaults to `false`.
  final bool logCurl;

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
      if (logCurl) _printCurl(request);
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

  bool _shouldLogEndpoint(String path) {
    if (includeEndpoints != null && includeEndpoints!.isNotEmpty) {
      final matches = includeEndpoints!.any((p) => RegExp(p).hasMatch(path));
      if (!matches) return false;
    }
    if (excludeEndpoints != null && excludeEndpoints!.isNotEmpty) {
      final matches = excludeEndpoints!.any((p) => RegExp(p).hasMatch(path));
      if (matches) return false;
    }
    return true;
  }

  bool _shouldLogResponse(int statusCode, String path, int duration) {
    if (!_shouldLogEndpoint(path)) return false;
    if (onlyErrors && statusCode >= 200 && statusCode < 400) return false;
    if (slowRequestThresholdMs != null && duration < slowRequestThresholdMs!) return false;
    return true;
  }
}
