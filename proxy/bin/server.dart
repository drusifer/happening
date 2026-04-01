// OAuth token exchange proxy for the happening app.
//
// TLDR:
// Overview: Thin HTTP proxy that adds client_secret to Google token exchange requests.
// Problem: Desktop apps can't safely embed OAuth client_secret in their binary.
// Solution: Proxy holds the secret via env var; app calls localhost instead of Google directly.
// Breaking Changes: No.
//
// Usage:
//   GOOGLE_CLIENT_SECRET=/path/to/client_secret.json dart run bin/server.dart [--port 8080]
//
// The app POSTs { client_id, code, code_verifier, redirect_uri, grant_type } to /token.
// The proxy appends client_secret and forwards to Google's token endpoint.
// ---------------------------------------------------------------------------

import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

const _googleTokenUrl = 'https://oauth2.googleapis.com/token';
const _defaultPort = 8080;

void main(List<String> args) async {
  final secretPath = Platform.environment['GOOGLE_CLIENT_SECRET'];
  if (secretPath == null || secretPath.isEmpty) {
    stderr.writeln('Error: GOOGLE_CLIENT_SECRET environment variable not set.');
    exit(1);
  }
  final secretJson = jsonDecode(await File(secretPath).readAsString());
  final secret = (secretJson['installed'] ?? secretJson['web'])['client_secret'] as String;

  final port = _parsePort(args) ?? _defaultPort;
  final server = await HttpServer.bind('0.0.0.0', port);
  stdout.writeln('[proxy] Happening token proxy listening on http://0.0.0.0:$port');
  stdout.writeln('[proxy] Press Ctrl+C to stop.');

  await for (final request in server) {
    if (request.method == 'POST' && request.uri.path == '/token') {
      await _handleToken(request, secret);
    } else {
      request.response
        ..statusCode = HttpStatus.notFound
        ..write('Not found')
        ..close();
    }
  }
}

Future<void> _handleToken(HttpRequest request, String secret) async {
  try {
    final rawBody = await utf8.decoder.bind(request).join();
    final params = Map<String, String>.from(Uri.splitQueryString(rawBody));
    stdout.writeln('[proxy] Received params: ${params.keys.toList()}');
    stdout.writeln('[proxy] client_id: ${params['client_id']}');

    // Inject the secret — this is the only thing the proxy adds.
    params['client_secret'] = secret;

    final googleResponse = await http.post(
      Uri.parse(_googleTokenUrl),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: params,
    );

    stdout.writeln('[proxy] Token exchange: ${googleResponse.statusCode}');

    request.response
      ..statusCode = googleResponse.statusCode
      ..headers.contentType = ContentType.json
      ..write(googleResponse.body);
    await request.response.close();
  } catch (e) {
    stderr.writeln('[proxy] Error: $e');
    request.response
      ..statusCode = HttpStatus.internalServerError
      ..write('{"error":"proxy_error"}');
    await request.response.close();
  }
}

int? _parsePort(List<String> args) {
  final idx = args.indexOf('--port');
  if (idx != -1 && idx + 1 < args.length) {
    return int.tryParse(args[idx + 1]);
  }
  return null;
}
