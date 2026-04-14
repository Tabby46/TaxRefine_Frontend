class UserModel {
  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.plaidLinkActive,
    this.institutionName,
  });

  final String id;
  final String name;
  final String email;
  final bool plaidLinkActive;
  final String? institutionName;

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    bool? plaidLinkActive,
    String? institutionName,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      plaidLinkActive: plaidLinkActive ?? this.plaidLinkActive,
      institutionName: institutionName ?? this.institutionName,
    );
  }
}
