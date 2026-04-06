
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
