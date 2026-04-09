part of 'igloo_http_logger.dart';

extension _IglooHttpLoggerCurl on IglooHttpLogger {
  // =========================================================================
  // PRINT CURL
  // =========================================================================

  /// Prints a cURL command for [request] in a full bordered block,
  /// consistent with the request/response block style.
  ///
  /// A placeholder note is shown when the body cannot be represented as a
  /// cURL argument:
  /// - [http.StreamedRequest] (or any other [http.BaseRequest] subclass that is
  ///   neither [http.Request] nor [http.MultipartRequest]) → body bytes are not
  ///   accessible at log time; a note instructs the dev accordingly.
  ///
  /// cURL syntax: bash/zsh/fish (`\` line continuation, single-quoted values).
  void _printCurl(http.BaseRequest request) {
    final isStreamed =
        request is! http.Request && request is! http.MultipartRequest;

    const color = LoggerConstants.colorYellow;
    const border = '$color${LoggerConstants.borderVertical}${LoggerConstants.colorReset}';

    // Top border
    debugPrint('');
    const topBorder = '${LoggerConstants.borderTop} ${LoggerConstants.textCurl} ';
    final remainingWidth = maxWidth - topBorder.length;
    debugPrint('${LoggerConstants.colorBold}$color$topBorder${LoggerConstants.borderHorizontal * remainingWidth}${LoggerConstants.colorReset}');

    // bash/zsh/fish hint
    debugPrint('$border ${LoggerConstants.colorDim}# bash/zsh/fish${LoggerConstants.colorReset}');

    if (isStreamed) {
      debugPrint(
        '$border ${LoggerConstants.colorDim}# ⚠️  Streamed body — body bytes not available at log time${LoggerConstants.colorReset}',
      );
    }

    // cURL command lines
    final curl = _buildCurl(request);
    for (final line in curl.split('\n')) {
      debugPrint('$border ${LoggerConstants.colorGrey}$line${LoggerConstants.colorReset}');
    }

    // Bottom border
    debugPrint('$color${LoggerConstants.borderBottom}${LoggerConstants.borderHorizontal * (maxWidth - 1)}${LoggerConstants.colorReset}');
  }

  // =========================================================================
  // BUILD CURL
  // =========================================================================

  /// Builds the cURL command string from [request].
  ///
  /// - Skips `-X GET` (curl default).
  /// - Adds `-L` to follow redirects (matches http.Client default behaviour).
  /// - Adds one `-H` flag per header.
  /// - Body:
  ///   - [http.Request] with non-empty body → `-d '...'` (JSON compacted if possible)
  ///   - [http.MultipartRequest] → `--form` flags (text fields + file placeholders with filename)
  ///   - [http.StreamedRequest] / other → body line omitted (caller shows placeholder note)
  String _buildCurl(http.BaseRequest request) {
    final method = request.method.toUpperCase();
    final lines = <String>['curl'];

    lines.add('  -L'); // follow redirects
    if (method != 'GET') lines.add('  -X $method');

    request.headers.forEach((key, value) {
      lines.add("  -H '${_sq(key)}: ${_sq(value)}'");
    });

    if (request is http.Request && request.body.isNotEmpty) {
      // Compact JSON for cleaner output; fall back to raw body if not JSON
      final body = request.body;
      final compacted = _tryCompactJson(body);
      lines.add("  -d '${_sq(compacted ?? body)}'");
    } else if (request is http.MultipartRequest) {
      // Text fields
      request.fields.forEach((key, value) {
        lines.add("  --form '${_sq(key)}=${_sq(value)}'");
      });
      // File fields — filename only (full path not available at runtime)
      for (final file in request.files) {
        lines.add("  --form '${_sq(file.field)}=@\"${file.filename ?? 'file'}\"'");
      }
    }
    // StreamedRequest / other BaseRequest — body silently omitted (note shown by _printCurl)

    lines.add("  '${_sq(request.url.toString())}'");
    return lines.join(' \\\n');
  }

  // =========================================================================
  // HELPERS
  // =========================================================================

  /// Tries to compact a JSON string (strip pretty-print whitespace).
  /// Returns `null` if [text] is not valid JSON.
  String? _tryCompactJson(String text) {
    try {
      return jsonEncode(jsonDecode(text));
    } catch (_) {
      return null;
    }
  }

  /// Escapes single quotes for safe use inside bash single-quoted strings.
  ///
  /// In bash, a single-quoted string cannot contain a literal `'`.
  /// The standard workaround is to close the string, append `\'`, then reopen:
  /// `'` → `'\''`
  ///
  /// Example: `it's` becomes `it'\''s`, so `curl -d 'it'\''s'` is valid bash.
  String _sq(String value) => value.replaceAll("'", r"'\''");
}
