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
- 🔗 **cURL logging** — opt-in `logCurl: true` prints a copy-pasteable cURL command after each request
- 🪪 **Request ID tracking** — bold cyan `│ ID: #xxxx` on every request/response/error block for easy correlation of concurrent requests
- 📋 **Multipart form data preview** — `http.MultipartRequest` bodies log `Fields:` and `Files:` metadata (name, filename, content-type)
- 🔍 **GraphQL support** — requests with a `query` key render as a dedicated `[GraphQL]` block with query and variables sections
- ⚡ **Zero performance impact** in release mode (only logs in debug mode)

## 📸 Screenshots

### Request Logging
![Request Logging](https://raw.githubusercontent.com/igloodev/igloo_http_logger/master/screenshots/01_request.png)

### Response Logging
![Response Logging](https://raw.githubusercontent.com/igloodev/igloo_http_logger/master/screenshots/02_response.png)

### List Response (with Items count)
![List Response](https://raw.githubusercontent.com/igloodev/igloo_http_logger/master/screenshots/03_list_response.png)

### cURL Logging (opt-in)
![cURL Logging](https://raw.githubusercontent.com/igloodev/igloo_http_logger/master/screenshots/04_curl.png)

### Multipart Form Data Preview
![FormData Preview](https://raw.githubusercontent.com/igloodev/igloo_http_logger/master/screenshots/05_formdata.png)

### GraphQL Support
![GraphQL Support](https://raw.githubusercontent.com/igloodev/igloo_http_logger/master/screenshots/06_graphql.png)

### Request ID Tracking

Every request, response, and error block shows a bold cyan `│ ID: #xxxx` suffix. The 4-hex ID is auto-generated per request, making it easy to match logs from concurrent calls:

![Request ID Tracking](https://raw.githubusercontent.com/igloodev/igloo_http_logger/master/screenshots/07_concurrent_requests_id.png)

> **How to use it:** When you see an unexpected response in the console, note its `ID:` value and search upward for the matching request block with the same ID. No configuration needed — IDs are generated automatically.

### Error Logging
![Error Logging](https://raw.githubusercontent.com/igloodev/igloo_http_logger/master/screenshots/08_error.png)

## 🚀 Getting Started

### Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  igloo_http_logger: ^1.2.0
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
| `logCurl` | `bool` | `false` | Print a copy-pasteable cURL command after each request |
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

### Log cURL Commands

Enable `logCurl: true` to print a ready-to-paste cURL command after every request.
The cURL block uses the same `╔═══ ... ╚═══` bordered style as request/response logs.

```dart
final client = IglooHttpLogger(logCurl: true);
```

**Body handling at a glance:**

| Request type | cURL output |
|---|---|
| `http.Request` (JSON/text body) | `-d '{"key":"value"}'` |
| `http.MultipartRequest` (text fields) | `--form 'key=value'` per field |
| `http.MultipartRequest` (file fields) | `--form 'key=@"filename"'` — replace with full path |
| `http.StreamedRequest` | Body omitted + `⚠️` note: _"body bytes not available at log time"_ |

> **Windows users:** cURL syntax uses bash `\` line continuation and single-quoted values.
> Run in WSL, Git Bash, or adapt manually: `\` → `^`, `'...'` → `"..."` with `\"` escaping.

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
