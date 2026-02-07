/// Model para representar a resposta da API de login
class CoreAuthLoginResponse {
  final String token;
  final String? refreshToken;
  final UserData? user;

  const CoreAuthLoginResponse({
    required this.token,
    this.refreshToken,
    this.user,
  });

  factory CoreAuthLoginResponse.fromJson(Map<String, dynamic> json) {
    return CoreAuthLoginResponse(
      token: json['token'] as String,
      refreshToken: json['refreshToken'] as String?,
      user: json['user'] != null 
          ? UserData.fromJson(json['user'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      if (refreshToken != null) 'refreshToken': refreshToken,
      if (user != null) 'user': user!.toJson(),
    };
  }
}

/// Model para dados do usuário retornado no login
class UserData {
  final String? id;
  final String? email;
  final String? name;

  const UserData({
    this.id,
    this.email,
    this.name,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      id: json['id'] as String?,
      email: json['email'] as String?,
      name: json['name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (email != null) 'email': email,
      if (name != null) 'name': name,
    };
  }
}

/// Model para requisição de login
class CoreAuthLoginRequest {
  final String email;
  final String password;

  const CoreAuthLoginRequest({
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
    };
  }
}
