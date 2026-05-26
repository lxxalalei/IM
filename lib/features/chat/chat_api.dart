import 'dart:convert';

import 'package:http/http.dart' as http;

import 'chat_models.dart';

class ChatApi {
  ChatApi({http.Client? client, this.baseUrl = 'http://127.0.0.1:8000'})
    : _client = client ?? http.Client();

  final http.Client _client;
  final String baseUrl;

  Future<List<Conversation>> fetchConversations({String query = ''}) async {
    final response = await _client.get(
      _uri('/api/conversations', queryParameters: {'q': query}),
    );
    _ensureSuccess(response);

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final items = payload['items'] as List<dynamic>;
    return items
        .map((item) => Conversation.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<ChatMessage>> fetchMessages(String conversationId) async {
    final response = await _client.get(
      _uri('/api/conversations/$conversationId/messages'),
    );
    _ensureSuccess(response);

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final items = payload['items'] as List<dynamic>;
    return items
        .map((item) => ChatMessage.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<ChatMessage> sendMessage({
    required String conversationId,
    required String content,
  }) async {
    final response = await _client.post(
      _uri('/api/conversations/$conversationId/messages'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'content': content}),
    );
    _ensureSuccess(response, expectedStatus: 201);

    return ChatMessage.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<void> markRead(String conversationId) async {
    final response = await _client.patch(
      _uri('/api/conversations/$conversationId/read'),
    );
    _ensureSuccess(response, expectedStatus: 204);
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

  void _ensureSuccess(http.Response response, {int? expectedStatus}) {
    final expected = expectedStatus ?? 200;
    if (response.statusCode != expected) {
      throw ChatApiException(
        'Request failed with status ${response.statusCode}: ${response.body}',
      );
    }
  }
}

class ChatApiException implements Exception {
  ChatApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
