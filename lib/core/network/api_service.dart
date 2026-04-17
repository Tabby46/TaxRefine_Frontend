import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:taxrefine/core/auth/auth_session.dart';
import 'package:taxrefine/core/models/bank_connection.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.1.11:9090/api';

  final http.Client client;

  ApiService({required this.client});

  Future<List<BankConnection>> fetchBankConnections() async {
    final response = await client.get(
      Uri.parse('$baseUrl/bank-connections'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => BankConnection.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load bank connections');
    }
  }

  Future<void> deleteBankConnection(String id) async {
    final response = await client.delete(
      Uri.parse('$baseUrl/bank-connections/$id'),
      headers: await _getHeaders(),
    );

    if (response.statusCode != 204) {
      throw Exception('Failed to unlink bank connection');
    }
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _getAuthToken();
    return {
      'Content-Type': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<String> _getAuthToken() async {
    // Get JWT from auth session
    return AuthSession.jwt ?? '';
  }
}
