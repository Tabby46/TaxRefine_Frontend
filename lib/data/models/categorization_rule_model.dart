class CategorizationRuleModel {
  const CategorizationRuleModel({
    this.id,
    required this.userId,
    required this.merchantName,
    required this.categoryId,
    this.createdAt,
    this.updatedAt,
  });

  final int? id;
  final String userId;
  final String merchantName;
  final int categoryId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory CategorizationRuleModel.fromJson(Map<String, dynamic> json) {
    return CategorizationRuleModel(
      id: json['id'] as int?,
      userId: json['userId'] as String,
      merchantName: json['merchantName'] as String,
      categoryId: json['categoryId'] as int,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'merchantName': merchantName,
      'categoryId': categoryId,
    };
  }
}
