/// Modelo para dados do usuário obtidos do Google Sign-In
class AuthGoogleUserData {
  final String id; // Google User ID
  final String email;
  final String? displayName;
  final String? photoUrl;
  final String? accessToken; // Token OAuth Google
  final String? idToken; // ID Token JWT do Google
  final List<String> scopes; // Escopos autorizados

  const AuthGoogleUserData({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.accessToken,
    this.idToken,
    this.scopes = const [],
  });

  /// Extrai primeiro nome do displayName
  String get firstName {
    if (displayName == null || displayName!.isEmpty) return '';
    final parts = displayName!.split(' ');
    return parts.first;
  }

  /// Extrai sobrenome do displayName
  String? get surname {
    if (displayName == null || displayName!.isEmpty) return null;
    final parts = displayName!.split(' ');
    if (parts.length < 2) return null;
    return parts.sublist(1).join(' ');
  }

  @override
  String toString() => 'AuthGoogleUserData(id: $id, email: $email, name: $displayName)';
}

/// Request para enviar dados OAuth do Google ao backend
class AuthGoogleOAuthRequest {
  final String email;
  final String name;
  final String? surname;
  final String oauthProvider; // "GOOGLE"
  final String oauthId; // Google User ID
  final String accessToken; // Token OAuth do Google
  final String? idToken; // ID Token JWT

  const AuthGoogleOAuthRequest({
    required this.email,
    required this.name,
    this.surname,
    required this.oauthProvider,
    required this.oauthId,
    required this.accessToken,
    this.idToken,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'email': email,
      'name': name,
      'oauthProvider': oauthProvider,
      'oauthId': oauthId,
      'accessToken': accessToken,
    };

    if (surname != null && surname!.isNotEmpty) {
      json['surname'] = surname;
    }
    if (idToken != null && idToken!.isNotEmpty) {
      json['idToken'] = idToken;
    }

    return json;
  }

  @override
  String toString() => 'AuthGoogleOAuthRequest(email: $email, provider: $oauthProvider)';
}

/// Estados possíveis do OAuth
enum OAuthState {
  initial,
  loading,
  success,
  error,
  cancelled, // Usuário cancelou o fluxo
}
