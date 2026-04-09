/// Constants for IglooHttpLogger
///
/// Contains all text strings, border characters, and ANSI color codes
/// used for formatting HTTP logs.
class LoggerConstants {
  LoggerConstants._(); // Private constructor to prevent instantiation

  // =========================================================================
  // ANSI COLOR CODES
  // =========================================================================

  /// Reset all styles
  static const colorReset = '\x1B[0m';

  /// Bold text
  static const colorBold = '\x1B[1m';

  /// Dim/faded text
  static const colorDim = '\x1B[2m';

  /// Grey (bright black) - used for secondary text
  static const colorGrey = '\x1B[90m';

  /// Cyan - used for request borders and structure
  static const colorCyan = '\x1B[36m';

  /// Green - used for successful responses (2xx)
  static const colorGreen = '\x1B[32m';

  /// Yellow - used for values and redirects (3xx)
  static const colorYellow = '\x1B[33m';

  /// Red - used for errors (4xx, 5xx)
  static const colorRed = '\x1B[31m';

  /// Blue - used for HTTP methods (GET, POST, etc.)
  static const colorBlue = '\x1B[34m';

  /// Magenta - used for duration/timing
  static const colorMagenta = '\x1B[35m';

  // =========================================================================
  // LOG SECTION TITLES
  // =========================================================================

  /// HTTP request title with emoji
  static const textHttpRequest = '🚀 HTTP REQUEST';

  /// HTTP response title with emoji
  static const textHttpResponse = '✅ HTTP RESPONSE';

  /// HTTP error title with emoji
  static const textHttpError = '❌ HTTP ERROR';

  /// cURL command block title with emoji
  static const textCurl = '🔗 cURL';

  // =========================================================================
  // LOG LABELS
  // =========================================================================

  /// Query parameters label
  static const textQueryParams = 'Query Params:';

  /// Headers label
  static const textHeaders = 'Headers:';

  /// Body label
  static const textBody = 'Body:';

  /// Status label
  static const textStatus = 'Status:';

  /// Duration label
  static const textDuration = 'Duration:';

  /// Size label
  static const textSize = 'Size:';

  /// Response label
  static const textResponse = 'Response:';

  /// Items label — shown when root response is a List
  static const textItems = 'Items:';

  // =========================================================================
  // ERROR MESSAGES
  // =========================================================================

  /// Default error message when exception message is null
  static const textUnknownError = 'Unknown error';

  /// Error message for invalid maxWidth value
  static const textMaxWidthError = 'maxWidth must be between 60 and 200';

  // =========================================================================
  // REGEX PATTERNS
  // =========================================================================
  // RegExp has no const constructor in Dart, so static final is used.
  // static final is initialized once (lazily on first access).

  /// Matches a JSON key that opens an object or array: `"key": {` or `"key": [`
  static final reOpenBrace = RegExp(r'"([^"]+)"\s*:\s*[\{\[]');

  /// Matches a JSON key-value line: `  "key": value`
  static final reKeyValue = RegExp(r'^(\s*)"([^"]+)"\s*:\s*(.*)$');

  /// Matches a JSON number value (with optional trailing comma)
  static final reNumber = RegExp(r'^-?\d+\.?\d*,?$');

  // =========================================================================
  // BORDER CHARACTERS
  // =========================================================================

  /// Top-left corner with horizontal line
  static const borderTop = '╔═══';

  /// Bottom-left corner
  static const borderBottom = '╚';

  /// Vertical line
  static const borderVertical = '║';

  /// Horizontal line
  static const borderHorizontal = '═';

  /// Separator for inline values
  static const separator = '│';
}
