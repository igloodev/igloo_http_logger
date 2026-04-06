import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:igloo_http_logger/igloo_http_logger.dart';

/// Strips ANSI escape codes from a string for clean text assertions.
String stripAnsi(String text) => text.replaceAll(RegExp(r'\x1B\[[0-9;]*m'), '');

/// Captures all [debugPrint] output during [action] and returns the lines.
Future<List<String>> captureDebugPrint(Future<void> Function() action) async {
  final output = <String>[];
  final original = debugPrint;
  debugPrint = (message, {wrapWidth}) {
    if (message != null) output.add(message);
  };
  try {
    await action();
  } finally {
    debugPrint = original;
  }
  return output;
}

/// Creates an [IglooHttpLogger] backed by a [MockClient] that always returns
/// [statusCode] with [body] as JSON.
IglooHttpLogger mockLogger(
  dynamic body, {
  int statusCode = 200,
  Map<String, String>? headers,
  bool logResponseHeader = false,
  bool logResponseBody = true,
  bool logRequestHeader = true,
  bool logRequestBody = true,
  bool logErrors = true,
  bool onlyErrors = false,
  int? slowRequestThresholdMs,
  List<String>? includeEndpoints,
  List<String>? excludeEndpoints,
}) {
  final responseBody = body is String ? body : jsonEncode(body);
  final responseHeaders = {
    'content-type': 'application/json',
    ...?headers,
  };
  return IglooHttpLogger(
    client: MockClient((_) async => http.Response(responseBody, statusCode, headers: responseHeaders)),
    logResponseHeader: logResponseHeader,
    logResponseBody: logResponseBody,
    logRequestHeader: logRequestHeader,
    logRequestBody: logRequestBody,
    logErrors: logErrors,
    onlyErrors: onlyErrors,
    slowRequestThresholdMs: slowRequestThresholdMs,
    includeEndpoints: includeEndpoints,
    excludeEndpoints: excludeEndpoints,
  );
}

void main() {
  group('IglooHttpLogger — instantiation', () {
    test('can be instantiated with default values', () {
      final logger = IglooHttpLogger();
      expect(logger, isNotNull);
      expect(logger, isA<http.BaseClient>());
      logger.close();
    });

    test('can be instantiated with custom values', () {
      final logger = IglooHttpLogger(
        logRequestHeader: false,
        logRequestBody: false,
        logResponseHeader: true,
        logResponseBody: false,
        logErrors: true,
        maxWidth: 120,
        onlyErrors: true,
        slowRequestThresholdMs: 1000,
      );
      expect(logger, isNotNull);
      logger.close();
    });

    test('throws assertion error when maxWidth is too small', () {
      expect(() => IglooHttpLogger(maxWidth: 50), throwsA(isA<AssertionError>()));
    });

    test('throws assertion error when maxWidth is too large', () {
      expect(() => IglooHttpLogger(maxWidth: 300), throwsA(isA<AssertionError>()));
    });

    test('accepts maxWidth within valid range', () {
      expect(() => IglooHttpLogger(maxWidth: 60), returnsNormally);
      expect(() => IglooHttpLogger(maxWidth: 120), returnsNormally);
      expect(() => IglooHttpLogger(maxWidth: 200), returnsNormally);
    });
  });

  group('IglooHttpLogger — request/response logging', () {
    test('logs a GET response and returns usable response', () async {
      final logger = mockLogger({'id': 1, 'name': 'Alice'});
      late http.Response response;

      final lines = await captureDebugPrint(() async {
        response = await logger.get(Uri.parse('https://api.example.com/users/1'));
      });

      final joined = stripAnsi(lines.join('\n'));
      expect(joined, contains('HTTP REQUEST'));
      expect(joined, contains('HTTP RESPONSE'));
      expect(joined, contains('GET'));
      expect(joined, contains('200'));
      expect(response.statusCode, 200);
      expect(jsonDecode(response.body)['name'], 'Alice');

      logger.close();
    });

    test('logs a POST request with body', () async {
      final logger = mockLogger({'success': true}, statusCode: 201);

      final lines = await captureDebugPrint(() async {
        await logger.post(
          Uri.parse('https://api.example.com/users'),
          body: jsonEncode({'name': 'Bob'}),
          headers: {'content-type': 'application/json'},
        );
      });

      final joined = stripAnsi(lines.join('\n'));
      expect(joined, contains('POST'));
      expect(joined, contains('201'));

      logger.close();
    });

    test('response body is still readable after logging', () async {
      final expectedBody = [
        {'id': 1},
        {'id': 2},
      ];
      final logger = mockLogger(expectedBody);

      late http.Response response;
      await captureDebugPrint(() async {
        response = await logger.get(Uri.parse('https://api.example.com/items'));
      });

      final decoded = jsonDecode(response.body) as List;
      expect(decoded.length, 2);

      logger.close();
    });
  });

  group('IglooHttpLogger — Items count in status line', () {
    test('shows Items count when root response is a List', () async {
      final logger = mockLogger([
        {'id': 1},
        {'id': 2},
        {'id': 3},
      ]);

      final lines = await captureDebugPrint(() async {
        await logger.get(Uri.parse('https://api.example.com/users'));
      });

      final joined = stripAnsi(lines.join('\n'));
      expect(joined, contains('Items: 3'));

      logger.close();
    });

    test('does not show Items when root response is a plain Map with no list', () async {
      final logger = mockLogger({'success': true, 'message': 'ok'});

      final lines = await captureDebugPrint(() async {
        await logger.get(Uri.parse('https://api.example.com/users'));
      });

      expect(lines.join('\n'), isNot(contains('Items:')));

      logger.close();
    });

    test('shows Items count when response has "data" wrapper key', () async {
      final logger = mockLogger({'data': [{'id': 1}, {'id': 2}], 'total': 2});

      final lines = await captureDebugPrint(() async {
        await logger.get(Uri.parse('https://api.example.com/users'));
      });

      final joined = stripAnsi(lines.join('\n'));
      expect(joined, contains('Items: 2'));

      logger.close();
    });

    test('shows Items count when response has "users" wrapper key', () async {
      final logger = mockLogger({'users': [{'id': 1}, {'id': 2}, {'id': 3}], 'total': 3});

      final lines = await captureDebugPrint(() async {
        await logger.get(Uri.parse('https://api.example.com/users'));
      });

      final joined = stripAnsi(lines.join('\n'));
      expect(joined, contains('Items: 3'));

      logger.close();
    });

    test('does not show Items when response has multiple matching wrapper keys', () async {
      final logger = mockLogger({'data': [{'id': 1}], 'results': [{'id': 2}]});

      final lines = await captureDebugPrint(() async {
        await logger.get(Uri.parse('https://api.example.com/users'));
      });

      expect(lines.join('\n'), isNot(contains('Items:')));

      logger.close();
    });
  });

  group('IglooHttpLogger — array item comments // [n]', () {
    test('single array — items labeled // [0], // [1] (zero-based)', () async {
      final logger = mockLogger({
        'items': [
          {'id': 1, 'name': 'Alice'},
          {'id': 2, 'name': 'Bob'},
        ],
      });

      final lines = await captureDebugPrint(() async {
        await logger.get(Uri.parse('https://api.example.com/test'));
      });

      final joined = lines.join('\n');
      expect(joined, contains('// [0]'));
      expect(joined, contains('// [1]'));

      logger.close();
    });

    test('named object closing labeled with key name', () async {
      final logger = mockLogger({
        'meta': {'total': 10, 'page': 1},
      });

      final lines = await captureDebugPrint(() async {
        await logger.get(Uri.parse('https://api.example.com/test'));
      });

      expect(lines.join('\n'), contains('// meta'));

      logger.close();
    });
  });

  group('IglooHttpLogger — filtering', () {
    test('onlyErrors: true suppresses successful responses', () async {
      final logger = mockLogger({'ok': true}, onlyErrors: true);

      final lines = await captureDebugPrint(() async {
        await logger.get(Uri.parse('https://api.example.com/test'));
      });

      final joined = stripAnsi(lines.join('\n'));
      expect(joined, isNot(contains('HTTP RESPONSE')));

      logger.close();
    });

    test('onlyErrors: true still logs 4xx responses', () async {
      final logger = mockLogger({'error': 'not found'}, statusCode: 404, onlyErrors: true);

      final lines = await captureDebugPrint(() async {
        await logger.get(Uri.parse('https://api.example.com/test'));
      });

      final joined = stripAnsi(lines.join('\n'));
      expect(joined, contains('HTTP RESPONSE'));
      expect(joined, contains('404'));

      logger.close();
    });

    test('includeEndpoints filters out non-matching paths', () async {
      final logger = mockLogger({'ok': true}, includeEndpoints: [r'/api/auth/.*']);

      final lines = await captureDebugPrint(() async {
        await logger.get(Uri.parse('https://api.example.com/users'));
      });

      final joined = stripAnsi(lines.join('\n'));
      expect(joined, isNot(contains('HTTP RESPONSE')));

      logger.close();
    });

    test('excludeEndpoints suppresses matching paths', () async {
      final logger = mockLogger({'ok': true}, excludeEndpoints: [r'/users']);

      final lines = await captureDebugPrint(() async {
        await logger.get(Uri.parse('https://api.example.com/users'));
      });

      final joined = stripAnsi(lines.join('\n'));
      expect(joined, isNot(contains('HTTP RESPONSE')));

      logger.close();
    });
  });

  group('IglooHttpLogger — error logging', () {
    test('logs ClientException and rethrows', () async {
      final logger = IglooHttpLogger(
        client: MockClient((_) async => throw http.ClientException('Connection refused')),
      );

      late List<String> lines;
      Object? caughtError;

      lines = await captureDebugPrint(() async {
        try {
          await logger.get(Uri.parse('https://api.example.com/test'));
        } catch (e) {
          caughtError = e;
        }
      });

      final joined = stripAnsi(lines.join('\n'));
      expect(joined, contains('HTTP ERROR'));
      expect(joined, contains('Connection refused'));
      expect(caughtError, isA<http.ClientException>());

      logger.close();
    });
  });
}
