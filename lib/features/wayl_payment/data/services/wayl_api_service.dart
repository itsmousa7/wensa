import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

import '../../config/wayl_config.dart';
import '../models/wayl_link_request.dart';
import '../models/wayl_link_response.dart';

class WaylApiException implements Exception {
  final int statusCode;
  final String message;

  const WaylApiException({required this.statusCode, required this.message});

  @override
  String toString() => 'WaylApiException($statusCode): $message';
}

class WaylApiService {
  WaylApiService({http.Client? client}) : _client = client ?? _buildClient();

  final http.Client _client;

  static http.Client _buildClient() {
    if (WaylConfig.env == 'test') {
      final httpClient = HttpClient()
        ..badCertificateCallback = (_, _, _) => true;
      return IOClient(httpClient);
    }
    return http.Client();
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'X-WAYL-AUTHENTICATION': WaylConfig.apiKey,
      };

  Future<WaylLinkResponse> createLink(WaylLinkRequest request) async {
    final uri = Uri.parse('${WaylConfig.baseUrl}/api/v1/links');
    final response = await _client.post(
      uri,
      headers: _headers,
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      String message;
      try {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        message = body['message'] as String? ?? 'Failed to create payment link';
      } catch (_) {
        final snippet = response.body.length > 120
            ? '${response.body.substring(0, 120)}…'
            : response.body;
        message = snippet.isEmpty
            ? 'HTTP ${response.statusCode} — no response body'
            : snippet;
      }
      throw WaylApiException(statusCode: response.statusCode, message: message);
    }

    final body = _decode(response);
    final data = body['data'] as Map<String, dynamic>;
    return WaylLinkResponse.fromJson(data);
  }

  Future<WaylLinkResponse> checkPaymentStatus(String referenceId) async {
    final uri =
        Uri.parse('${WaylConfig.baseUrl}/api/v1/links/$referenceId');
    final response = await _client.get(uri, headers: _headers);

    if (response.statusCode != 200) {
      String message;
      try {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        message =
            body['message'] as String? ?? 'Failed to check payment status';
      } catch (_) {
        message = 'HTTP ${response.statusCode} — no response body';
      }
      throw WaylApiException(statusCode: response.statusCode, message: message);
    }

    final body = _decode(response);
    final data = body['data'] as Map<String, dynamic>;
    return WaylLinkResponse.fromJson(data);
  }

  Map<String, dynamic> _decode(http.Response response) {
    try {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw WaylApiException(
        statusCode: response.statusCode,
        message: 'Invalid response from server',
      );
    }
  }
}
