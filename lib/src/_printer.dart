part of 'igloo_http_logger.dart';

extension _IglooHttpLoggerPrinter on IglooHttpLogger {
  // =========================================================================
  // REQUEST
  // =========================================================================

  void _printRequest(http.BaseRequest request, String requestId) {
    final method = request.method.toUpperCase();
    final uri = request.url;
    final baseUrl = _baseUrl(uri);
    final hasQueryParams = uri.queryParameters.isNotEmpty;

    final requestSize = request is http.Request ? request.bodyBytes.length : 0;
    final requestSizeText = requestSize > 0 ? _formatSize(requestSize) : null;
    final requestIdSuffix =
        ' ${LoggerConstants.colorDim}${LoggerConstants.separator} ${LoggerConstants.textRequestId}${LoggerConstants.colorReset} '
        '${LoggerConstants.colorBold}${LoggerConstants.colorCyan}#$requestId${LoggerConstants.colorReset}';

    debugPrint('');
    const topBorder = '${LoggerConstants.borderTop} ${LoggerConstants.textHttpRequest} ';
    final remainingWidth = maxWidth - topBorder.length;
    debugPrint('${LoggerConstants.colorBold}${LoggerConstants.colorCyan}$topBorder${LoggerConstants.borderHorizontal * remainingWidth}${LoggerConstants.colorReset}');

    if (requestSizeText != null) {
      debugPrint(
        '${LoggerConstants.colorCyan}${LoggerConstants.borderVertical}${LoggerConstants.colorReset} '
        '${LoggerConstants.colorBold}${LoggerConstants.colorBlue}$method${LoggerConstants.colorReset} '
        '${LoggerConstants.colorDim}$baseUrl${LoggerConstants.colorReset} '
        '${LoggerConstants.colorDim}│${LoggerConstants.colorReset} '
        '${LoggerConstants.colorYellow}$requestSizeText${LoggerConstants.colorReset}$requestIdSuffix',
      );
    } else {
      debugPrint(
        '${LoggerConstants.colorCyan}${LoggerConstants.borderVertical}${LoggerConstants.colorReset} '
        '${LoggerConstants.colorBold}${LoggerConstants.colorBlue}$method${LoggerConstants.colorReset} '
        '${LoggerConstants.colorDim}$baseUrl${LoggerConstants.colorReset}$requestIdSuffix',
      );
    }

    if (hasQueryParams) {
      debugPrint('${LoggerConstants.colorCyan}${LoggerConstants.borderVertical}${LoggerConstants.colorReset}');
      debugPrint('${LoggerConstants.colorCyan}${LoggerConstants.borderVertical}${LoggerConstants.colorReset} ${LoggerConstants.colorDim}${LoggerConstants.textQueryParams}${LoggerConstants.colorReset}');
      uri.queryParameters.forEach((key, value) {
        debugPrint('${LoggerConstants.colorCyan}${LoggerConstants.borderVertical}${LoggerConstants.colorReset}   ${LoggerConstants.colorGrey}$key:${LoggerConstants.colorReset} ${LoggerConstants.colorYellow}$value${LoggerConstants.colorReset}');
      });
    }

    if (logRequestHeader && request.headers.isNotEmpty) {
      debugPrint('${LoggerConstants.colorCyan}${LoggerConstants.borderVertical}${LoggerConstants.colorReset}');
      debugPrint('${LoggerConstants.colorCyan}${LoggerConstants.borderVertical}${LoggerConstants.colorReset} ${LoggerConstants.colorDim}${LoggerConstants.textHeaders}${LoggerConstants.colorReset}');
      request.headers.forEach((key, value) {
        _printHeaderValue(key, value, LoggerConstants.colorCyan);
      });
    }

    if (logRequestBody) {
      if (request is http.MultipartRequest) {
        debugPrint('${LoggerConstants.colorCyan}${LoggerConstants.borderVertical}${LoggerConstants.colorReset}');
        debugPrint('${LoggerConstants.colorCyan}${LoggerConstants.borderVertical}${LoggerConstants.colorReset} ${LoggerConstants.colorDim}${LoggerConstants.textBody}${LoggerConstants.colorReset}');
        _printMultipartFormData(request, LoggerConstants.colorCyan);
      } else if (request is http.Request && request.body.isNotEmpty) {
        debugPrint('${LoggerConstants.colorCyan}${LoggerConstants.borderVertical}${LoggerConstants.colorReset}');
        debugPrint('${LoggerConstants.colorCyan}${LoggerConstants.borderVertical}${LoggerConstants.colorReset} ${LoggerConstants.colorDim}${LoggerConstants.textBody}${LoggerConstants.colorReset}');
        final body = _tryParseJson(request.body) ?? request.body;
        if (_isGraphQLRequest(body)) {
          _printGraphQL(body as Map, LoggerConstants.colorCyan);
        } else {
          _printLongText(_formatJson(body), LoggerConstants.colorCyan);
        }
      }
    }

    debugPrint('${LoggerConstants.colorCyan}${LoggerConstants.borderBottom}${LoggerConstants.borderHorizontal * (maxWidth - 1)}${LoggerConstants.colorReset}');
  }

  // =========================================================================
  // RESPONSE
  // =========================================================================

  void _printResponse(
    http.BaseRequest request,
    http.StreamedResponse response,
    Uint8List bytes,
    int duration,
    String requestId,
  ) {
    final statusCode = response.statusCode;
    final method = request.method.toUpperCase();
    final uri = request.url;
    final baseUrl = _baseUrl(uri);
    final hasQueryParams = uri.queryParameters.isNotEmpty;
    final color = _getStatusColor(statusCode);
    final durationText = _formatDuration(duration);

    final bodyData = _decodeBytes(bytes, response.headers);
    final responseSizeText = _formatSize(bytes.length);
    final itemsCount = _extractItemsCount(bodyData);
    final requestIdSuffix =
        ' ${LoggerConstants.colorDim}${LoggerConstants.separator} ${LoggerConstants.textRequestId}${LoggerConstants.colorReset} '
        '${LoggerConstants.colorBold}${LoggerConstants.colorCyan}#$requestId${LoggerConstants.colorReset}';

    debugPrint('');
    const topBorder = '${LoggerConstants.borderTop} ${LoggerConstants.textHttpResponse} ';
    final remainingWidth = maxWidth - topBorder.length;
    debugPrint('${LoggerConstants.colorBold}$color$topBorder${LoggerConstants.borderHorizontal * remainingWidth}${LoggerConstants.colorReset}');

    debugPrint(
      '$color${LoggerConstants.borderVertical}${LoggerConstants.colorReset} '
      '${LoggerConstants.colorBold}${LoggerConstants.colorBlue}$method${LoggerConstants.colorReset} '
      '${LoggerConstants.colorDim}$baseUrl${LoggerConstants.colorReset}$requestIdSuffix',
    );

    if (hasQueryParams) {
      debugPrint(
        '$color${LoggerConstants.borderVertical}${LoggerConstants.colorReset} '
        '${LoggerConstants.colorDim}${LoggerConstants.textQueryParams}${LoggerConstants.colorReset} '
        '${LoggerConstants.colorGrey}${uri.queryParameters.entries.map((e) => '${e.key}=${e.value}').join('&')}${LoggerConstants.colorReset}',
      );
    }

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

    if (logResponseHeader && response.headers.isNotEmpty) {
      debugPrint('$color${LoggerConstants.borderVertical}${LoggerConstants.colorReset}');
      debugPrint('$color${LoggerConstants.borderVertical}${LoggerConstants.colorReset} ${LoggerConstants.colorDim}${LoggerConstants.textHeaders}${LoggerConstants.colorReset}');
      response.headers.forEach((key, value) {
        _printHeaderValue(key, value, color);
      });
    }

    if (logResponseBody && bodyData != null) {
      debugPrint('$color${LoggerConstants.borderVertical}${LoggerConstants.colorReset}');
      debugPrint('$color${LoggerConstants.borderVertical}${LoggerConstants.colorReset} ${LoggerConstants.colorDim}${LoggerConstants.textBody}${LoggerConstants.colorReset}');
      _printLongText(_formatJson(bodyData), color);
    }

    debugPrint('$color${LoggerConstants.borderBottom}${LoggerConstants.borderHorizontal * (maxWidth - 1)}${LoggerConstants.colorReset}');
  }

  // =========================================================================
  // ERROR
  // =========================================================================

  void _printError(http.BaseRequest request, Object error, int duration, String requestId) {
    final method = request.method.toUpperCase();
    final uri = request.url;
    final baseUrl = _baseUrl(uri);
    final hasQueryParams = uri.queryParameters.isNotEmpty;
    final durationText = _formatDuration(duration);
    final errorMessage = error is http.ClientException ? error.message : error.toString();
    final requestIdSuffix =
        ' ${LoggerConstants.colorDim}${LoggerConstants.separator} ${LoggerConstants.textRequestId}${LoggerConstants.colorReset} '
        '${LoggerConstants.colorBold}${LoggerConstants.colorCyan}#$requestId${LoggerConstants.colorReset}';

    debugPrint('');
    const topBorder = '${LoggerConstants.borderTop} ${LoggerConstants.textHttpError} ';
    final remainingWidth = maxWidth - topBorder.length;
    debugPrint('${LoggerConstants.colorBold}${LoggerConstants.colorRed}$topBorder${LoggerConstants.borderHorizontal * remainingWidth}${LoggerConstants.colorReset}');

    debugPrint(
      '${LoggerConstants.colorRed}${LoggerConstants.borderVertical}${LoggerConstants.colorReset} '
      '${LoggerConstants.colorBold}${LoggerConstants.colorBlue}$method${LoggerConstants.colorReset} '
      '${LoggerConstants.colorDim}$baseUrl${LoggerConstants.colorReset}$requestIdSuffix',
    );

    if (hasQueryParams) {
      debugPrint(
        '${LoggerConstants.colorRed}${LoggerConstants.borderVertical}${LoggerConstants.colorReset} '
        '${LoggerConstants.colorDim}${LoggerConstants.textQueryParams}${LoggerConstants.colorReset} '
        '${LoggerConstants.colorGrey}${uri.queryParameters.entries.map((e) => '${e.key}=${e.value}').join('&')}${LoggerConstants.colorReset}',
      );
    }

    debugPrint(
      '${LoggerConstants.colorRed}${LoggerConstants.borderVertical}${LoggerConstants.colorReset} '
      '${LoggerConstants.colorBold}${error.runtimeType}${LoggerConstants.colorReset} '
      '${LoggerConstants.colorDim}${LoggerConstants.separator} ${LoggerConstants.textDuration}${LoggerConstants.colorReset} ${LoggerConstants.colorMagenta}$durationText${LoggerConstants.colorReset}',
    );
    final displayMessage = errorMessage.isNotEmpty ? errorMessage : LoggerConstants.textUnknownError;
    debugPrint('${LoggerConstants.colorRed}${LoggerConstants.borderVertical}${LoggerConstants.colorReset} $displayMessage');

    debugPrint('${LoggerConstants.colorRed}${LoggerConstants.borderBottom}${LoggerConstants.borderHorizontal * (maxWidth - 1)}${LoggerConstants.colorReset}');
  }

  // =========================================================================
  // MULTIPART FORM DATA
  // =========================================================================

  void _printMultipartFormData(http.MultipartRequest request, String borderColor) {
    debugPrint('$borderColor${LoggerConstants.borderVertical}${LoggerConstants.colorReset}   ${LoggerConstants.colorDim}[Form Data]${LoggerConstants.colorReset}');

    if (request.fields.isNotEmpty) {
      debugPrint('$borderColor${LoggerConstants.borderVertical}${LoggerConstants.colorReset}');
      debugPrint('$borderColor${LoggerConstants.borderVertical}${LoggerConstants.colorReset}   ${LoggerConstants.colorDim}${LoggerConstants.textFormFields} (${request.fields.length})${LoggerConstants.colorReset}');
      request.fields.forEach((key, value) {
        debugPrint('$borderColor${LoggerConstants.borderVertical}${LoggerConstants.colorReset}     ${LoggerConstants.colorGrey}$key:${LoggerConstants.colorReset} ${LoggerConstants.colorYellow}$value${LoggerConstants.colorReset}');
      });
    }

    if (request.files.isNotEmpty) {
      debugPrint('$borderColor${LoggerConstants.borderVertical}${LoggerConstants.colorReset}');
      debugPrint('$borderColor${LoggerConstants.borderVertical}${LoggerConstants.colorReset}   ${LoggerConstants.colorDim}${LoggerConstants.textFormFiles} (${request.files.length})${LoggerConstants.colorReset}');
      for (final file in request.files) {
        final contentType = file.contentType.toString();
        debugPrint('$borderColor${LoggerConstants.borderVertical}${LoggerConstants.colorReset}     ${LoggerConstants.colorGrey}${file.field}${LoggerConstants.colorReset} → ${LoggerConstants.colorYellow}${file.filename ?? 'unnamed'}${LoggerConstants.colorReset} ${LoggerConstants.colorDim}($contentType)${LoggerConstants.colorReset}');
      }
    }
  }

  // =========================================================================
  // GRAPHQL
  // =========================================================================

  bool _isGraphQLRequest(dynamic body) {
    if (body is! Map) return false;
    final query = body['query'];
    return query is String && query.isNotEmpty;
  }

  void _printGraphQL(Map body, String borderColor) {
    debugPrint('$borderColor${LoggerConstants.borderVertical}${LoggerConstants.colorReset}   ${LoggerConstants.colorDim}[GraphQL]${LoggerConstants.colorReset}');

    final query = body['query'] as String;
    debugPrint('$borderColor${LoggerConstants.borderVertical}${LoggerConstants.colorReset}');
    debugPrint('$borderColor${LoggerConstants.borderVertical}${LoggerConstants.colorReset}   ${LoggerConstants.colorDim}${LoggerConstants.textGraphQL}${LoggerConstants.colorReset}');
    for (final line in query.trim().split('\n')) {
      debugPrint('$borderColor${LoggerConstants.borderVertical}${LoggerConstants.colorReset}     ${LoggerConstants.colorYellow}$line${LoggerConstants.colorReset}');
    }

    final variables = body['variables'];
    if (variables != null) {
      debugPrint('$borderColor${LoggerConstants.borderVertical}${LoggerConstants.colorReset}');
      debugPrint('$borderColor${LoggerConstants.borderVertical}${LoggerConstants.colorReset}   ${LoggerConstants.colorDim}${LoggerConstants.textVariables}${LoggerConstants.colorReset}');
      _printLongText(_formatJson(variables), borderColor);
    }
  }

  // =========================================================================
  // HEADER VALUE
  // =========================================================================

  /// Prints a header key-value pair, wrapping long values (e.g. JWT tokens).
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
}
