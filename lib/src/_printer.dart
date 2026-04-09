part of 'igloo_http_logger.dart';

extension _IglooHttpLoggerPrinter on IglooHttpLogger {
  // =========================================================================
  // REQUEST
  // =========================================================================

  void _printRequest(http.BaseRequest request) {
    final method = request.method.toUpperCase();
    final uri = request.url;
    final baseUrl = _baseUrl(uri);
    final hasQueryParams = uri.queryParameters.isNotEmpty;

    final requestSize = request is http.Request ? request.bodyBytes.length : 0;
    final requestSizeText = requestSize > 0 ? _formatSize(requestSize) : null;

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
        '${LoggerConstants.colorYellow}$requestSizeText${LoggerConstants.colorReset}',
      );
    } else {
      debugPrint(
        '${LoggerConstants.colorCyan}${LoggerConstants.borderVertical}${LoggerConstants.colorReset} '
        '${LoggerConstants.colorBold}${LoggerConstants.colorBlue}$method${LoggerConstants.colorReset} '
        '${LoggerConstants.colorDim}$baseUrl${LoggerConstants.colorReset}',
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

    if (logRequestBody && request is http.Request && request.body.isNotEmpty) {
      debugPrint('${LoggerConstants.colorCyan}${LoggerConstants.borderVertical}${LoggerConstants.colorReset}');
      debugPrint('${LoggerConstants.colorCyan}${LoggerConstants.borderVertical}${LoggerConstants.colorReset} ${LoggerConstants.colorDim}${LoggerConstants.textBody}${LoggerConstants.colorReset}');
      final body = _tryParseJson(request.body) ?? request.body;
      _printLongText(_formatJson(body), LoggerConstants.colorCyan);
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

    debugPrint('');
    const topBorder = '${LoggerConstants.borderTop} ${LoggerConstants.textHttpResponse} ';
    final remainingWidth = maxWidth - topBorder.length;
    debugPrint('${LoggerConstants.colorBold}$color$topBorder${LoggerConstants.borderHorizontal * remainingWidth}${LoggerConstants.colorReset}');

    debugPrint(
      '$color${LoggerConstants.borderVertical}${LoggerConstants.colorReset} '
      '${LoggerConstants.colorBold}${LoggerConstants.colorBlue}$method${LoggerConstants.colorReset} '
      '${LoggerConstants.colorDim}$baseUrl${LoggerConstants.colorReset}',
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

    debugPrint(
      '${LoggerConstants.colorRed}${LoggerConstants.borderVertical}${LoggerConstants.colorReset} '
      '${LoggerConstants.colorBold}${LoggerConstants.colorBlue}$method${LoggerConstants.colorReset} '
      '${LoggerConstants.colorDim}$baseUrl${LoggerConstants.colorReset}',
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
    debugPrint('${LoggerConstants.colorRed}${LoggerConstants.borderVertical}${LoggerConstants.colorReset} $errorMessage');

    debugPrint('${LoggerConstants.colorRed}${LoggerConstants.borderBottom}${LoggerConstants.borderHorizontal * (maxWidth - 1)}${LoggerConstants.colorReset}');
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
