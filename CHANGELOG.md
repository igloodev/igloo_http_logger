
## 🔗 1.2.0

### ✨ New Features
* 🎨 cURL block upgraded to full bordered style (`╔═══ 🔗 cURL ═══...`) — consistent with request/response blocks
  * Includes `-L` for redirect following
  * All lines now have `║` border prefix matching the logger visual style
* 🌍 `LoggerConstants` is now exported as public API — allows access to regex patterns and other constants from outside the package

### 🐛 Bug Fixes
* 🔀 Separator `│` in error block now uses `LoggerConstants.separator` — consistent with response block
* ♻️ Inline regex patterns in `_json_formatter.dart` replaced with `LoggerConstants.reOpenBrace`, `reKeyValue`, `reNumber` — compiled once as `static final`

## 🔗 1.1.0

### ✨ New Features
* 🔗 Added `logCurl: false` — opt-in cURL command logging after each request
  * Plain text output (no `║` border) — copy directly from the console
  * `http.Request` → `-d '...'` with JSON compaction and single-quote escaping
  * `http.MultipartRequest` → `--form` flags per field; files use `--form 'key=@"filename"'` placeholder
  * `http.StreamedRequest` → body omitted with a `⚠️` note: _"body bytes not available at log time"_
  * Single quotes in body are safely escaped (`'` → `'\''`) for valid bash syntax
  * Syntax is bash/zsh/fish; a `# bash/zsh/fish` comment is shown for clarity

## 🔧 1.0.1

### 📝 Documentation
* Updated `igloo_dio_logger` reference from "sister package" to "companion package" in README

## 🎉 1.0.0

* 🎨 Initial release
* 🌈 Beautiful colored HTTP logging with ANSI colors
* 😀 Emoji status indicators for HTTP status codes
* 📊 Request/Response size tracking
* ⏱️ Duration tracking
* 🔢 Array item annotations — items labeled `// [0]`, `// [1]`, etc.
* 📋 `Items:` count in status line — detects root List responses and common wrapper keys (`data`, `items`, `results`, `users`, `posts`, `products`, `records`, `list`, `content`, `entries`)
* 🛡️ When multiple wrapper keys match, `Items:` is hidden to avoid showing an ambiguous count
* 🔍 Advanced filtering options (endpoints, errors, slow requests)
* 📦 Pretty JSON formatting with syntax highlighting
* 🎯 Smart header wrapping for long values (e.g. JWT tokens)
* ⚡ Production-safe (only logs in debug mode)
