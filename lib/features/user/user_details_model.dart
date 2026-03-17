import 'dart:convert';
import 'package:portugal_guide/features/user/user_phone_model.dart';

/// Model para representar os detalhes completos de um usuário
/// Retornado pelo endpoint /users/{id}/details
class UserDetailsModel {
  final String id;
  final String name;
  final String surname;
  final String email;
  final String role;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String? oauthProvider;
  final String? oauthId;
  final bool active;
  final String fullName;
  final List<UserPhoneModel> phones;

  const UserDetailsModel({
    required this.id,
    required this.name,
    required this.surname,
    required this.email,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.oauthProvider,
    this.oauthId,
    required this.active,
    required this.fullName,
    required this.phones,
  });

  UserDetailsModel copyWith({
    String? id,
    String? name,
    String? surname,
    String? email,
    String? role,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    String? oauthProvider,
    String? oauthId,
    bool? active,
    String? fullName,
    List<UserPhoneModel>? phones,
  }) {
    return UserDetailsModel(
      id: id ?? this.id,
      name: name ?? this.name,
      surname: surname ?? this.surname,
      email: email ?? this.email,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      oauthProvider: oauthProvider ?? this.oauthProvider,
      oauthId: oauthId ?? this.oauthId,
      active: active ?? this.active,
      fullName: fullName ?? this.fullName,
      phones: phones ?? this.phones,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'surname': surname,
      'email': email,
      'role': role,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
      'oauthProvider': oauthProvider,
      'oauthId': oauthId,
      'active': active,
      'fullName': fullName,
      'phones': phones.map((x) => x.toMap()).toList(),
    };
  }

  factory UserDetailsModel.fromMap(Map<String, dynamic> map) {
    return UserDetailsModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      surname: map['surname'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'USER',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : DateTime.now(),
      deletedAt:
          map['deletedAt'] != null ? DateTime.parse(map['deletedAt'] as String) : null,
      oauthProvider: map['oauthProvider'],
      oauthId: map['oauthId'],
      active: map['active'] ?? true,
      fullName: map['fullName'] ?? '',
      phones: map['phones'] != null
          ? List<UserPhoneModel>.from(
              (map['phones'] as List<dynamic>).map<UserPhoneModel>(
                (x) => UserPhoneModel.fromMap(x as Map<String, dynamic>),
              ),
            )
          : [],
    );
  }

  String toJson() => json.encode(toMap());

  factory UserDetailsModel.fromJson(String source) =>
      UserDetailsModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'UserDetailsModel(id: $id, name: $name, surname: $surname, email: $email, role: $role, phones: ${phones.length})';
  }

  @override
  bool operator ==(covariant UserDetailsModel other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.name == name &&
        other.surname == surname &&
        other.email == email &&
        other.role == role &&
        other.fullName == fullName;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        surname.hashCode ^
        email.hashCode ^
        role.hashCode ^
        fullName.hashCode;
  }
}
