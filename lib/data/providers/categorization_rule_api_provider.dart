import 'package:dio/dio.dart';
import 'package:taxrefine/core/network/dio_client.dart';
import 'package:taxrefine/data/models/categorization_rule_model.dart';

class CategorizationRuleApiProvider {
  CategorizationRuleApiProvider(this._dioClient);

  final DioClient _dioClient;

  Future<List<CategorizationRuleModel>> getRules(String userId) async {
    final response = await _dioClient.dio.get(
      '/categorization-rules',
      queryParameters: {'userId': userId},
    );
    final data = response.data as List<dynamic>;
    return data
        .map((e) => CategorizationRuleModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<CategorizationRuleModel> createRule(
    CategorizationRuleModel rule, {
    required bool bulkApply,
  }) async {
    final response = await _dioClient.dio.post(
      '/categorization-rules',
      queryParameters: {'bulkApply': bulkApply},
      data: rule.toJson(),
    );
    return CategorizationRuleModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<void> deleteRule(int id) async {
    await _dioClient.dio.delete('/categorization-rules/$id');
  }
}
