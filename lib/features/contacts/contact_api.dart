import 'dart:convert';

import 'package:http/http.dart' as http;

import 'contact_models.dart';

class ContactApi {
  ContactApi({http.Client? client, this.baseUrl = 'http://127.0.0.1:8000'})
    : _client = client ?? http.Client();

  final http.Client _client;
  final String baseUrl;

  Future<List<Contact>> fetchContacts({String query = ''}) async {
    final response = await _client.get(
      _uri('/api/contacts', queryParameters: {'q': query}),
    );
    _ensureSuccess(response);

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final items = payload['items'] as List<dynamic>;
    return items
        .map((item) => Contact.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Uri _uri(String path, {Map<String, String>? queryParameters}) {
    final filteredQuery = <String, String>{};
    for (final entry in queryParameters?.entries ?? const Iterable.empty()) {
      if (entry.value.trim().isNotEmpty) {
        filteredQuery[entry.key] = entry.value.trim();
      }
    }

    return Uri.parse(
      '$baseUrl$path',
    ).replace(queryParameters: filteredQuery.isEmpty ? null : filteredQuery);
  }

  void _ensureSuccess(http.Response response) {
    if (response.statusCode != 200) {
      throw ContactApiException(
        'Request failed with status ${response.statusCode}: ${response.body}',
      );
    }
  }
}

class ContactApiException implements Exception {
  ContactApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
