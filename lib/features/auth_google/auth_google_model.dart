/// Modelo para dados do usuário obtidos do Google Sign-In
class AuthGoogleUserData {
  final String id; // Google User ID
  final String email;
  final String? displayName;
  final String? photoUrl;
  final String? accessToken; // Token OAuth Google
  final String? idToken; // ID Token JWT do Google
  final List<String> scopes; // Escopos autorizados
  
  // YouTube Data
  final String? youtubeUserId; // YouTube User ID (sem prefixo UC, ex: AW0lk_gWgAjclw3EXT_hmg)
  final String? youtubeChannelId; // YouTube Channel ID (com prefixo UC, ex: UCAW0lk_gWgAjclw3EXT_hmg)
  final String? youtubeChannelTitle; // Nome do canal YouTube
  final bool hasYouTubeChannel; // Se possui canal YouTube

  const AuthGoogleUserData({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.accessToken,
    this.idToken,
    this.scopes = const [],
    this.youtubeUserId,
    this.youtubeChannelId,
    this.youtubeChannelTitle,
    this.hasYouTubeChannel = false,
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
  String toString() => 'AuthGoogleUserData(id: $id, email: $email, name: $displayName, youtubeUserId: $youtubeUserId, youtubeChannelId: $youtubeChannelId)';
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
  final String? youtubeUserId; // YouTube User ID (sem UC)
  final String? youtubeChannelId; // YouTube Channel ID (com UC)
  final String? youtubeChannelTitle; // Título do canal YouTube

  const AuthGoogleOAuthRequest({
    required this.email,
    required this.name,
    this.surname,
    required this.oauthProvider,
    required this.oauthId,
    required this.accessToken,
    this.idToken,
    this.youtubeUserId,
    this.youtubeChannelId,
    this.youtubeChannelTitle,
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
    // ✅ Adicionar dados YouTube ao backend
    if (youtubeUserId != null && youtubeUserId!.isNotEmpty) {
      json['youtubeUserId'] = youtubeUserId;
    }
    if (youtubeChannelId != null && youtubeChannelId!.isNotEmpty) {
      json['youtubeChannelId'] = youtubeChannelId;
    }
    if (youtubeChannelTitle != null && youtubeChannelTitle!.isNotEmpty) {
      json['youtubeChannelTitle'] = youtubeChannelTitle;
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
