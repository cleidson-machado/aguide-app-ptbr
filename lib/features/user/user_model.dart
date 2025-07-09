import 'dart:convert';

import 'package:portugal_guide/app/core/base/base_model.dart';

class UserModel implements BaseModel {

  @override
  final String id;
  
  String name;
  String surname;
  String email;

  UserModel({
    required this.id,
    required this.name,
    required this.surname,
    required this.email,
  });

  UserModel copyWith({
    String? id,
    String? name,
    String? surname,
    String? email,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      surname: surname ?? this.surname,
      email: email ?? this.email,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'surname': surname,
      'email': email,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      name: map['name'] ?? 'No Name',
      surname: map['surname'] ?? 'No Surname',
      email: map['email'] ?? 'no.email@provider.com',
    );
  }

  String toJson() => json.encode(toMap());

  factory UserModel.fromJson(String source) => UserModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'UserModel(id: $id, name: $name, surname: $surname, email: $email)';
  }

  @override
  bool operator ==(covariant UserModel other) {
    if (identical(this, other)) return true;
  
    return 
      other.id == id &&
      other.name == name &&
      other.surname == surname &&
      other.email == email;
  }

  @override
  int get hashCode {
    return id.hashCode ^
      name.hashCode ^
      surname.hashCode ^
      email.hashCode;
  }
}