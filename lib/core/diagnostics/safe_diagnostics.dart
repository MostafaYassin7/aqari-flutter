import 'dart:convert';
import 'dart:developer' as developer;

/// Closed fields prevent URLs, tokens, bodies, notes and raw errors entering logs.
/// Uses Dart's local diagnostics sink; no external telemetry service is configured.
enum DiagnosticEvent {
  networkFailure,
  serverFailure,
  parsingFailure,
  socketFailure,
}

String diagnosticRecord(DiagnosticEvent event, {int? statusCode}) => jsonEncode(
  {'event': event.name, if (statusCode != null) 'statusCode': statusCode},
);
void reportDiagnostic(DiagnosticEvent event, {int? statusCode}) =>
    developer.log(
      diagnosticRecord(event, statusCode: statusCode),
      name: 'aqari.network',
      level: 900,
    );
