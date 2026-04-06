# Igloo HTTP Logger 🎨

A beautiful HTTP request/response logger for the [`http`](https://pub.dev/packages/http) package with ANSI colors, emojis, and advanced filtering options.

![Igloo HTTP Logger](https://img.shields.io/pub/v/igloo_http_logger.svg)
![License](https://img.shields.io/badge/license-MIT-blue.svg)

> Also using **Dio**? Check out [igloo_dio_logger](https://pub.dev/packages/igloo_dio_logger) — the companion package with the same beautiful output.

## ✨ Features

- 🎨 **Beautiful colored output** with ANSI colors
- 😀 **Emoji status indicators** for HTTP status codes
- 📊 **Request/Response sizes** in human-readable format (B, KB, MB, GB)
- ⏱️ **Duration tracking** for each request
- 🔍 **Advanced filtering options**:
  - Filter by endpoints (include/exclude patterns)
  - Log only errors (4xx, 5xx)
  - Log only slow requests (minimum duration)
- 📦 **Pretty JSON formatting** with syntax highlighting
- 🔢 **Array item annotations** — each item labeled `// [0]`, `// [1]`, with nested array support
- 📋 **Items count** in the status line for List responses and common wrapper keys like `data`, `users`, `results` (`Items: 42`)
- 🎯 **Smart header wrapping** for long values (like JWT tokens)
- ⚡ **Zero performance impact** in release mode (only logs in debug mode)

## 📸 Screenshots

### Request Logging
```
╔═══ 🚀 HTTP REQUEST ═══════════════════════════════════════════════
║ POST /api/v1/auth/login │ 156B
║
║ Headers:
║   content-type: application/json
║   authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
║
║ Body:
║   {
║     "email": "user@example.com",
║     "password": "********"
║   }
╚═══════════════════════════════════════════════════════════════════
```

### Response Logging
```
╔═══ ✅ HTTP RESPONSE ══════════════════════════════════════════════
║ POST /api/v1/auth/login
║ Status: 200 ✅ │ Duration: 245ms │ Size: 1.24KB
║
║ Body:
║   {
║     "success": true,
║     "data": {
║       "user": {
║         "id": "123",
║         "email": "user@example.com"
║       }, // user
║       "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
║     } // data
║   }
╚═══════════════════════════════════════════════════════════════════
```

### List Response (with Items count)
```
╔═══ ✅ HTTP RESPONSE ══════════════════════════════════════════════
║ GET /api/v1/users
║ Status: 200 ✅ │ Duration: 112ms │ Size: 2.48KB │ Items: 3
║
║ Body:
║   [
║     {
║       "id": "1",
║       "name": "Alice"
║     }, // [0]
║     {
║       "id": "2",
║       "name": "Bob"
║     }, // [1]
║     {
║       "id": "3",
║       "name": "Charlie"
║     } // [2]
║   ]
╚═══════════════════════════════════════════════════════════════════
```

### Error Logging
```
╔═══ ❌ HTTP ERROR ═════════════════════════════════════════════════
║ GET /api/v1/users/999
║ ClientException │ Duration: 89ms
║ Connection refused
╚═══════════════════════════════════════════════════════════════════
```

## 🚀 Getting Started

### Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  igloo_http_logger: ^1.0.0
```

Run:
```bash
flutter pub get
```

### Basic Usage

```dart
import 'package:igloo_http_logger/igloo_http_logger.dart';

// Create the logger client (wraps a default http.Client)
final client = IglooHttpLogger();

// Use just like a normal http.Client
final response = await client.get(Uri.parse('https://api.example.com/users'));

// Always close when done
client.close();
```

### With a Custom Inner Client

```dart
import 'package:http/http.dart' as http;
import 'package:igloo_http_logger/igloo_http_logger.dart';

final client = IglooHttpLogger(client: http.Client());
```

### Advanced Configuration

```dart
final client = IglooHttpLogger(
  // Show/hide different parts of the log
  logRequestHeader: true,
  logRequestBody: true,
  logResponseHeader: false,
  logResponseBody: true,
  logErrors: true,

  // Control the width of the log output
  maxWidth: 90,

  // Filter by endpoints (regex patterns)
  includeEndpoints: [r'/api/v1/auth/.*', r'/api/v1/users/.*'],
  excludeEndpoints: [r'/api/v1/health'],

  // Only log errors (4xx, 5xx status codes)
  onlyErrors: false,

  // Only log slow requests (in milliseconds)
  slowRequestThresholdMs: 200,
);
```

## 🎯 Configuration Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `client` | `http.Client?` | `http.Client()` | Inner HTTP client to delegate requests to |
| `logRequestHeader` | `bool` | `true` | Show request headers |
| `logRequestBody` | `bool` | `true` | Show request body |
| `logResponseHeader` | `bool` | `false` | Show response headers |
| `logResponseBody` | `bool` | `true` | Show response body |
| `logErrors` | `bool` | `true` | Show errors |
| `maxWidth` | `int` | `90` | Maximum width of log output |
| `includeEndpoints` | `List<String>?` | `null` | Only log matching endpoints (regex) |
| `excludeEndpoints` | `List<String>?` | `null` | Exclude matching endpoints (regex) |
| `onlyErrors` | `bool` | `false` | Only log error responses (4xx, 5xx) |
| `slowRequestThresholdMs` | `int?` | `null` | Only log requests slower than X ms |

## 📋 Examples

### Filter Specific Endpoints

```dart
final client = IglooHttpLogger(
  includeEndpoints: [r'/auth/.*', r'/users/.*'],
);
```

### Log Only Errors

```dart
final client = IglooHttpLogger(onlyErrors: true);
```

### Log Only Slow Requests

```dart
final client = IglooHttpLogger(slowRequestThresholdMs: 500);
```

### Production-Safe Setup

```dart
import 'package:flutter/foundation.dart';

final client = IglooHttpLogger(
  logRequestBody: kDebugMode,
  logResponseBody: kDebugMode,
  onlyErrors: !kDebugMode,
);
```

## 🎨 Status Code Emojis

### 2xx Success
- ✅ 200 OK
- ✨ 201 Created
- ⏳ 202 Accepted
- ⭕ 204 No Content

### 3xx Redirection
- ↪️ 301 Moved Permanently
- 🔄 302 Found
- 📦 304 Not Modified

### 4xx Client Errors
- ⚠️ 400 Bad Request
- 🔒 401 Unauthorized
- 🚫 403 Forbidden
- 🔍 404 Not Found
- 🚷 405 Method Not Allowed
- ⏱️ 408 Request Timeout
- ⚔️ 409 Conflict
- 📋 422 Unprocessable Entity
- 🚦 429 Too Many Requests

### 5xx Server Errors
- 💥 500 Internal Server Error
- 🚧 502 Bad Gateway
- 🔴 503 Service Unavailable
- ⌛ 504 Gateway Timeout

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👨‍💻 Author

Created with ❤️ by [Akhilesh](https://igloodev.github.io/)

## 🙏 Acknowledgments

- Inspired by [igloo_dio_logger](https://pub.dev/packages/igloo_dio_logger)
- ANSI color codes for beautiful terminal output
- Emojis for quick visual status recognition

## 📚 Additional Resources

- [http package documentation](https://pub.dev/packages/http)
- [HTTP Status Codes](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status)

---

If you find this package useful, please give it a ⭐ on [GitHub](https://github.com/igloodev/igloo_http_logger) and a 👍 on [pub.dev](https://pub.dev/packages/igloo_http_logger)!
