import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:igloo_http_logger/igloo_http_logger.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Igloo HTTP Logger Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Standard logger — used for most examples
  final _client = IglooHttpLogger(
    logRequestHeader: true,
    logRequestBody: true,
    logResponseHeader: false,
    logResponseBody: true,
    logErrors: true,
    maxWidth: 90,
  );

  // Logger with cURL output enabled
  final _curlClient = IglooHttpLogger(
    logRequestBody: true,
    logResponseBody: true,
    logCurl: true,
    maxWidth: 90,
  );

  // Logger that only logs errors (4xx / 5xx)
  final _errorOnlyClient = IglooHttpLogger(onlyErrors: true);

  String _status = 'Press a button to make a request.\nCheck your debug console for logs.';
  bool _loading = false;

  @override
  void dispose() {
    _client.close();
    _curlClient.close();
    _errorOnlyClient.close();
    super.dispose();
  }

  Future<void> _get() async {
    _setLoading();
    try {
      final response = await _client.get(
        Uri.parse('https://dummyjson.com/posts/1'),
      );
      _setStatus('GET /posts/1 → ${response.statusCode}');
    } catch (e) {
      _setStatus('Error: $e');
    }
  }

  Future<void> _getList() async {
    _setLoading();
    try {
      final response = await _client.get(
        Uri.parse('https://dummyjson.com/posts').replace(
          queryParameters: {'limit': '1'},
        ),
      );
      final posts = (jsonDecode(response.body) as Map?)?['posts'] as List?;
      _setStatus('GET /posts?limit=1 → ${response.statusCode} (${posts?.length} items)');
    } catch (e) {
      _setStatus('Error: $e');
    }
  }

  Future<void> _getWithQueryParams() async {
    _setLoading();
    try {
      final response = await _client.get(
        Uri.parse('https://dummyjson.com/posts/search').replace(
          queryParameters: {'q': 'love', 'limit': '2'},
        ),
      );
      final posts = (jsonDecode(response.body) as Map?)?['posts'] as List?;
      _setStatus('GET /posts/search?q=love → ${response.statusCode} (${posts?.length} items)');
    } catch (e) {
      _setStatus('Error: $e');
    }
  }

  Future<void> _post() async {
    _setLoading();
    try {
      final response = await _client.post(
        Uri.parse('https://dummyjson.com/posts/add'),
        headers: {'content-type': 'application/json'},
        body: jsonEncode({
          'title': 'Hello from IglooHttpLogger',
          'body': 'This is a test post',
          'userId': 1,
          'tags': ['flutter', 'http'],
        }),
      );
      _setStatus('POST /posts/add → ${response.statusCode}');
    } catch (e) {
      _setStatus('Error: $e');
    }
  }

  Future<void> _getCurl() async {
    _setLoading();
    try {
      final response = await _curlClient.post(
        Uri.parse('https://dummyjson.com/posts/add'),
        headers: {
          'content-type': 'application/json',
          'Authorization': 'Bearer my-token',
        },
        body: jsonEncode({'title': 'cURL test', 'userId': 1}),
      );
      _setStatus('POST /posts/add → ${response.statusCode}\n(cURL printed in console)');
    } catch (e) {
      _setStatus('Error: $e');
    }
  }

  Future<void> _postFormData() async {
    _setLoading();
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://dummyjson.com/users/add'),
      );
      request.fields['firstName'] = 'John';
      request.fields['lastName'] = 'Doe';
      request.fields['age'] = '30';
      request.files.add(
        http.MultipartFile.fromBytes(
          'avatar',
          [0, 1, 2, 3],
          filename: 'avatar.jpg',
        ),
      );

      final streamed = await _client.send(request);
      _setStatus('POST multipart/form-data → ${streamed.statusCode}\n(FormData printed in console)');
    } catch (e) {
      _setStatus('Error: $e');
    }
  }

  Future<void> _postGraphQL() async {
    _setLoading();
    try {
      final response = await _client.post(
        Uri.parse('https://graphqlzero.almansi.me/api'),
        headers: {'content-type': 'application/json'},
        body: jsonEncode({
          'query': '''
query GetPost(\$id: ID!) {
  post(id: \$id) {
    id
    title
    body
  }
}''',
          'variables': {'id': '1'},
        }),
      );
      _setStatus('POST /graphql → ${response.statusCode}\n(GraphQL block printed in console)');
    } catch (e) {
      _setStatus('Error: $e');
    }
  }

  Future<void> _concurrentRequests() async {
    _setLoading();
    try {
      final results = await Future.wait([
        _client.get(Uri.parse('https://dummyjson.com/users/1')),
        _client.get(Uri.parse('https://dummyjson.com/posts/1')),
      ]);
      _setStatus(
        'Concurrent requests:\n'
        'GET /users/1 → ${results[0].statusCode}\n'
        'GET /posts/1 → ${results[1].statusCode}\n'
        '(match by ID: in console)',
      );
    } catch (e) {
      _setStatus('Error: $e');
    }
  }

  Future<void> _triggerError() async {
    _setLoading();

    // Success — silently skipped because onlyErrors: true
    try {
      await _errorOnlyClient.get(Uri.parse('https://dummyjson.com/posts/1'));
      _setStatus('GET /posts/1 silently skipped\n(onlyErrors: true)');
    } catch (e) {
      _setStatus('Error: $e');
    }

    // 404 — this will be logged
    try {
      await _errorOnlyClient.get(Uri.parse('https://dummyjson.com/posts/0'));
    } catch (e) {
      _setStatus(
        'GET /posts/0 → error\n'
        '(logged because onlyErrors: true;\nGET /posts/1 silently skipped)',
      );
    }
  }

  void _setLoading() => setState(() {
        _loading = true;
        _status = 'Loading...';
      });

  void _setStatus(String msg) => setState(() {
        _loading = false;
        _status = msg;
      });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Igloo HTTP Logger'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '👇 Tap a button and check your debug console for beautiful logs!',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _Button(label: '🚀 GET /posts/1', onTap: _get),
            const SizedBox(height: 12),
            _Button(label: '📋 GET /posts?limit=1  —  Items count', onTap: _getList),
            const SizedBox(height: 12),
            _Button(label: '🔍 GET /posts/search?q=love  —  Query params', onTap: _getWithQueryParams),
            const SizedBox(height: 12),
            _Button(label: '✨ POST /posts/add  —  With JSON body', onTap: _post),
            const SizedBox(height: 12),
            _Button(label: '🔗 POST /posts/add  —  With cURL output', onTap: _getCurl),
            const SizedBox(height: 24),
            const _SectionLabel('New in v1.2.0'),
            const SizedBox(height: 12),
            _Button(label: '📋 POST multipart  —  Form Data preview', onTap: _postFormData, isNew: true),
            const SizedBox(height: 12),
            _Button(label: '🔍 POST /graphql  —  GraphQL support', onTap: _postGraphQL, isNew: true),
            const SizedBox(height: 12),
            _Button(label: '🪪 Concurrent GETs  —  Request ID tracking', onTap: _concurrentRequests, isNew: true),
            const SizedBox(height: 12),
            _Button(label: '❌ GET /posts/0  —  404 error', onTap: _triggerError, isError: true),
            const SizedBox(height: 32),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _status,
                  style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.deepPurple.shade200),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.deepPurple.shade700,
          letterSpacing: 0.5,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _Button extends StatelessWidget {
  const _Button({
    required this.label,
    required this.onTap,
    this.isError = false,
    this.isNew = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool isError;
  final bool isNew;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: isError
            ? Colors.red.shade50
            : isNew
                ? Colors.deepPurple.shade50
                : null,
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      child: Text(label),
    );
  }
}
