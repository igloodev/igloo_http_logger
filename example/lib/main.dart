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
  // IglooHttpLogger wraps any http.Client — just swap it in
  final _client = IglooHttpLogger(
    logRequestHeader: true,
    logRequestBody: true,
    logResponseHeader: false,
    logResponseBody: true,
    logErrors: true,
    maxWidth: 90,
  );

  String _status = 'Press a button to make a request.\nCheck your debug console for logs.';
  bool _loading = false;

  @override
  void dispose() {
    _client.close();
    super.dispose();
  }

  Future<void> _get() async {
    _setLoading();
    try {
      final response = await _client.get(
        Uri.parse('https://api.github.com/users/octocat'),
        headers: {'accept': 'application/vnd.github+json'},
      );
      _setStatus('GET /users/octocat → ${response.statusCode}');
    } catch (e) {
      _setStatus('Error: $e');
    }
  }

  Future<void> _getList() async {
    _setLoading();
    try {
      final response = await _client.get(
        Uri.parse('https://api.github.com/users/octocat/repos'),
        headers: {'accept': 'application/vnd.github+json'},
      );
      final list = jsonDecode(response.body) as List;
      _setStatus('GET /repos → ${response.statusCode} (${list.length} items)');
    } catch (e) {
      _setStatus('Error: $e');
    }
  }

  Future<void> _post() async {
    _setLoading();
    try {
      final response = await _client.post(
        Uri.parse('https://httpbin.org/post'),
        headers: {'content-type': 'application/json'},
        body: jsonEncode({
          'title': 'Hello from IglooHttpLogger',
          'body': 'This is a test post',
          'userId': 1,
        }),
      );
      _setStatus('POST /post → ${response.statusCode}');
    } catch (e) {
      _setStatus('Error: $e');
    }
  }

  Future<void> _getWithQueryParams() async {
    _setLoading();
    try {
      final response = await _client.get(
        Uri.parse('https://api.github.com/search/users').replace(
          queryParameters: {'q': 'flutter', 'per_page': '3'},
        ),
        headers: {'accept': 'application/vnd.github+json'},
      );
      _setStatus('GET /search/users?q=flutter → ${response.statusCode}');
    } catch (e) {
      _setStatus('Error: $e');
    }
  }

  Future<void> _triggerError() async {
    _setLoading();
    final errorClient = IglooHttpLogger(
      client: http.Client(),
      onlyErrors: true,
    );
    try {
      await errorClient.get(
        Uri.parse('https://api.github.com/users/this-user-xyz-404-not-exist'),
        headers: {'accept': 'application/vnd.github+json'},
      );
      _setStatus('GET /users/... → 404 (logged because onlyErrors: true)');
    } catch (e) {
      _setStatus('Error: $e');
    } finally {
      errorClient.close();
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
      body: Padding(
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
            _Button(label: '🚀 GET /users/octocat', onTap: _get),
            const SizedBox(height: 12),
            _Button(label: '📋 GET /users/octocat/repos  —  Items count', onTap: _getList),
            const SizedBox(height: 12),
            _Button(label: '🔍 GET /search/users?q=flutter  —  Query params', onTap: _getWithQueryParams),
            const SizedBox(height: 12),
            _Button(label: '✨ POST /post  —  With JSON body', onTap: _post),
            const SizedBox(height: 12),
            _Button(label: '❌ GET /users/unknown  —  404 error', onTap: _triggerError, isError: true),
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

class _Button extends StatelessWidget {
  const _Button({
    required this.label,
    required this.onTap,
    this.isError = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: isError ? Colors.red.shade50 : null,
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      child: Text(label),
    );
  }
}
