import 'package:equatable/equatable.dart';

class BankConnection extends Equatable {
  final String id;
  final String? institutionName;
  final bool isActive;
  final DateTime? lastSynced;
  final DateTime? createdAt;
  final int transactionCount;

  const BankConnection({
    required this.id,
    this.institutionName,
    required this.isActive,
    this.lastSynced,
    this.createdAt,
    required this.transactionCount,
  });

  factory BankConnection.fromJson(Map<String, dynamic> json) {
    return BankConnection(
      id: json['id'] as String,
      institutionName: json['institutionName'] as String?,
      isActive: json['isActive'] as bool,
      lastSynced: json['lastSynced'] != null
          ? DateTime.parse(json['lastSynced'] as String)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      transactionCount: json['transactionCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'institutionName': institutionName,
      'isActive': isActive,
      'lastSynced': lastSynced?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'transactionCount': transactionCount,
    };
  }

  @override
  List<Object?> get props => [
        id,
        institutionName,
        isActive,
        lastSynced,
        createdAt,
        transactionCount,
      ];
}