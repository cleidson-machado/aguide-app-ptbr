import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:portugal_guide/app/helpers/env_key_helper_config.dart';
import 'package:portugal_guide/app/core/auth/auth_exception.dart';
import 'package:portugal_guide/util/oauth_debug_logger.dart';
import 'package:portugal_guide/features/auth_credentials/auth_credentials_model.dart';
import 'package:portugal_guide/features/auth_google/auth_google_model.dart';
import 'package:portugal_guide/features/auth_google/auth_google_mock_service.dart';

/// Exceção customizada para erros de OAuth Google
class GoogleOAuthException implements Exception {
  final String message;
  final int? statusCode;

  GoogleOAuthException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

/// Service responsável pela autenticação com Google OAuth 2.0
class AuthGoogleService {
  final GoogleSignIn _googleSignIn;
  final http.Client _httpClient;
  final AuthGoogleMockService _mockService = AuthGoogleMockService();

  // Escopos do Google (incluindo YouTube API)
  static const List<String> _scopes = [
    'email',
    'profile',
    // YouTube API Scopes
    'https://www.googleapis.com/auth/youtube.readonly', // Ler dados do YouTube
    'https://www.googleapis.com/auth/youtube.force-ssl', // Acesso completo via HTTPS
    // Adicionar mais escopos conforme necessidade:
    // 'https://www.googleapis.com/auth/youtube.upload',       // Upload de vídeos
    // 'https://www.googleapis.com/auth/youtube',              // Gerenciar conta
    // 'https://www.googleapis.com/auth/youtube.channel-memberships.creator', // Membros do canal
  ];

  // Usar variável de ambiente para autenticação
  static String get baseUrl => EnvKeyHelperConfig.mocApi3Auth;

  AuthGoogleService(this._googleSignIn, this._httpClient);

  /// Factory para criar instância com configuração padrão
  factory AuthGoogleService.defaultInstance() {
    final googleSignIn = GoogleSignIn(
      scopes: _scopes,
      // Client IDs são configurados automaticamente via:
      // - Android: google-services.json OU hardcoded abaixo
      // - iOS: Info.plist + Reversed Client ID
      // - Web: index.html meta tag
    );

    return AuthGoogleService(googleSignIn, http.Client());
  }

  /// Autentica usuário com Google e solicita escopos YouTube
  Future<AuthGoogleUserData> signInWithGoogle() async {
    // 🎭 MOCK: Usar autenticação fake se habilitado
    if (AuthGoogleMockService.isMockEnabled) {
      if (kDebugMode) {
        print('🎭 [AuthGoogleService] MODO MOCK ATIVADO - Usando dados fake');
      }
      return await _mockService.signInWithGoogle();
    }

    try {
      if (kDebugMode) {
        print('🔐 [AuthGoogleService] Iniciando Google Sign-In...');
        print('📜 [AuthGoogleService] Escopos solicitados: $_scopes');
      }

      // 1. Verifica se já está logado (silent sign-in)
      GoogleSignInAccount? account = await _googleSignIn.signInSilently();

      // 2. Se não está logado, mostra fluxo de autenticação
      account ??= await _googleSignIn.signIn();

      // 3. Usuário cancelou o login
      if (account == null) {
        if (kDebugMode) {
          print('❌ [AuthGoogleService] Login cancelado pelo usuário');
        }
        throw GoogleOAuthException('Login cancelado pelo usuário');
      }

      if (kDebugMode) {
        print('✅ [AuthGoogleService] Usuário autenticado: ${account.email}');
      }

      // 4. Obter tokens OAuth
      final GoogleSignInAuthentication auth = await account.authentication;

      if (auth.accessToken == null || auth.accessToken!.isEmpty) {
        throw GoogleOAuthException('Falha ao obter access token do Google');
      }

      if (kDebugMode) {
        print('🔑 [AuthGoogleService] Access Token obtido: ${auth.accessToken?.substring(0, 20)}...');
        print('🔑 [AuthGoogleService] ID Token obtido: ${auth.idToken?.substring(0, 20) ?? 'null'}...');
      }

      // 5. Buscar informações do YouTube (incluindo User ID + Channel ID)
      String? youtubeUserId; // User ID sem prefixo UC
      String? youtubeChannelId; // Channel ID com prefixo UC
      String? youtubeChannelTitle;
      bool hasYouTubeChannel = false;
      
      if (auth.accessToken != null) {
        try {
          // NOVA IMPLEMENTAÇÃO: Tentar múltiplos métodos para obter YouTube User ID
          if (kDebugMode) {
            print('📺 [AuthGoogleService] === INICIANDO BUSCA DE YOUTUBE USER ID ===');
          }
          
          // Método 1: Analisar ID Token (pode conter User ID)
          if (auth.idToken != null) {
            await _tryExtractUserIdFromIdToken(auth.idToken!);
          }
          
          // Método 2: Tentar endpoint de canal (retorna User ID + Channel ID se existir)
          final youtubeInfo = await _fetchYouTubeChannelInfo(auth.accessToken!);
          youtubeUserId = youtubeInfo['userId']; // User ID sem "UC"
          youtubeChannelId = youtubeInfo['channelId']; // Channel ID com "UC"
          youtubeChannelTitle = youtubeInfo['title'];
          hasYouTubeChannel = youtubeChannelId != null;
          
          // Método 3: Tentar obter informações básicas do YouTube (User ID básico)
          if (youtubeUserId == null) {
            final basicInfo = await _fetchYouTubeBasicUserInfo(auth.accessToken!);
            if (basicInfo['userId'] != null) {
              youtubeUserId = basicInfo['userId'];
              if (kDebugMode) {
                print('✅ [AuthGoogleService] YouTube Basic User ID encontrado: $youtubeUserId');
              }
            }
          }
          
          if (kDebugMode) {
            if (hasYouTubeChannel) {
              print('✅ [AuthGoogleService] YouTube Channel encontrado:');
              print('   - User ID: $youtubeUserId (sem prefixo UC)');
              print('   - Channel ID: $youtubeChannelId (com prefixo UC)');
              print('   - Channel Title: $youtubeChannelTitle');
            } else if (youtubeUserId != null) {
              print('✅ [AuthGoogleService] YouTube User ID básico encontrado: $youtubeUserId');
            } else {
              print('⚠️ [AuthGoogleService] Nenhum YouTube ID capturado');
            }
            print('📺 [AuthGoogleService] === FIM DA BUSCA ===');
          }
        } catch (e) {
          if (kDebugMode) {
            print('⚠️ [AuthGoogleService] Erro ao buscar YouTube info (não-crítico): $e');
          }
          // Não quebra o fluxo de login se falhar
        }
      }

      // 6. Retornar dados do usuário (incluindo YouTube)
      final userData = AuthGoogleUserData(
        id: account.id,
        email: account.email,
        displayName: account.displayName,
        photoUrl: account.photoUrl,
        accessToken: auth.accessToken,
        idToken: auth.idToken,
        scopes: [], // grantedScopes não disponível nesta versão
        youtubeUserId: youtubeUserId,
        youtubeChannelId: youtubeChannelId,
        youtubeChannelTitle: youtubeChannelTitle,
        hasYouTubeChannel: hasYouTubeChannel,
      );

      // ℹ️ Dados do Google capturados (backend receberá depois)
      // Logger será chamado APÓS autenticação com backend para salvar tudo junto

      return userData;
    } catch (e) {
      if (kDebugMode) {
        print('❌ [AuthGoogleService] Erro ao fazer login com Google: $e');
      }

      // 🐛 DEBUG: Salvar erro em arquivo .log
      await OAuthDebugLogger.logOAuthData(
        googleData: {'error_stage': 'google_sign_in'},
        errorMessage: e.toString(),
      );

      if (e is GoogleOAuthException) {
        rethrow;
      }

      throw GoogleOAuthException('Erro ao autenticar com Google: $e');
    }
  }

  /// Busca informações do canal YouTube do usuário
  /// 
  /// Retorna um Map com:
  /// - 'userId': YouTube User ID sem prefixo UC (ex: AW0lk_gWgAjclw3EXT_hmg, null se não tem canal)
  /// - 'channelId': YouTube Channel ID com prefixo UC (ex: UCAW0lk_gWgAjclw3EXT_hmg, null se não tem canal)
  /// - 'title': Nome do canal (null se não tem canal)
  /// 
  /// Usa YouTube Data API v3: channels?mine=true
  Future<Map<String, String?>> _fetchYouTubeChannelInfo(String accessToken) async {
    try {
      if (kDebugMode) {
        print('📺 [AuthGoogleService] Buscando informações do YouTube...');
      }

      final response = await _httpClient.get(
        Uri.parse(
          'https://www.googleapis.com/youtube/v3/channels'
          '?part=id,snippet'
          '&mine=true',
        ),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Accept': 'application/json',
        },
      );

      if (kDebugMode) {
        print('📺 [AuthGoogleService] YouTube API Status: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        
        // 🐛 DEBUG: Mostrar resposta completa
        if (kDebugMode) {
          print('📺 [AuthGoogleService] YouTube API Response: ${jsonEncode(jsonResponse)}');
        }
        
        final List<dynamic> items = jsonResponse['items'] ?? [];

        if (items.isEmpty) {
          // Usuário não tem canal YouTube
          if (kDebugMode) {
            print('📺 [AuthGoogleService] API retornou items vazio - usuário não possui canal YouTube criado');
            print('📺 [AuthGoogleService] Nota: Ter conta Google ≠ ter canal YouTube');
            print('📺 [AuthGoogleService] Para criar canal: https://www.youtube.com/create_channel');
          }
          return {'userId': null, 'channelId': null, 'title': null};
        }

        // Pega o primeiro canal (geralmente usuário tem apenas um)
        final channel = items[0];
        final channelId = channel['id'] as String?;
        final channelTitle = channel['snippet']?['title'] as String?;
        
        // ✅ Extrair User ID removendo prefixo "UC" do Channel ID
        String? userId;
        if (channelId != null && channelId.startsWith('UC') && channelId.length > 2) {
          userId = channelId.substring(2); // Remove "UC" prefix
        }
        
        if (kDebugMode) {
          print('📺 [AuthGoogleService] Channel ID encontrado: $channelId');
          print('📺 [AuthGoogleService] User ID extraído: $userId (sem prefixo UC)');
          print('📺 [AuthGoogleService] Channel Title: $channelTitle');
        }

        return {
          'userId': userId,
          'channelId': channelId,
          'title': channelTitle,
        };
      } else if (response.statusCode == 403) {
        // Quota exceeded ou API não habilitada
        if (kDebugMode) {
          print('⚠️ [AuthGoogleService] YouTube API 403: Quota excedida ou API não habilitada');
        }
        return {'userId': null, 'channelId': null, 'title': null};
      } else {
        throw Exception('YouTube API falhou com status ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [AuthGoogleService] Erro ao buscar YouTube info: $e');
      }
      return {'userId': null, 'channelId': null, 'title': null};
    }
  }

  /// [NOVO] Tenta extrair YouTube User ID do ID Token (JWT)
  /// 
  /// O ID Token pode conter informações adicionais no payload.
  /// Nota: User ID legado (UXeX...) pode não estar disponível.
  Future<void> _tryExtractUserIdFromIdToken(String idToken) async {
    try {
      if (kDebugMode) {
        print('🔐 [AuthGoogleService] Método 1: Analisando ID Token...');
      }
      
      // JWT tem 3 partes: header.payload.signature
      final parts = idToken.split('.');
      if (parts.length != 3) {
        if (kDebugMode) {
          print('⚠️ [AuthGoogleService] ID Token inválido (não tem 3 partes)');
        }
        return;
      }
      
      // Decodificar payload (Base64URL)
      String payload = parts[1];
      // Adicionar padding se necessário
      while (payload.length % 4 != 0) {
        payload += '=';
      }
      
      // Base64URL decode
      final normalizedPayload = payload.replaceAll('-', '+').replaceAll('_', '/');
      final decodedBytes = base64Decode(normalizedPayload);
      final decodedPayload = utf8.decode(decodedBytes);
      final Map<String, dynamic> payloadJson = jsonDecode(decodedPayload);
      
      if (kDebugMode) {
        print('🔐 [AuthGoogleService] ID Token payload completo:');
        print(jsonEncode(payloadJson));
        
        // Verificar campos específicos que podem conter User ID
        final possibleUserIdFields = ['sub', 'user_id', 'youtube_user_id', 'yt_user_id'];
        for (final field in possibleUserIdFields) {
          if (payloadJson.containsKey(field)) {
            print('🔍 [AuthGoogleService] Campo "$field": ${payloadJson[field]}');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [AuthGoogleService] Erro ao analisar ID Token: $e');
      }
    }
  }

  /// [NOVO] Tenta obter YouTube User ID básico usando métodos alternativos
  /// 
  /// Tenta múltiplos endpoints da YouTube API para capturar User ID legado
  /// Retorna Map com 'userId' se encontrado, ou null
  Future<Map<String, String?>> _fetchYouTubeBasicUserInfo(String accessToken) async {
    if (kDebugMode) {
      print('🔍 [AuthGoogleService] Método 3: Tentando obter YouTube Basic User ID...');
    }
    
    // Lista de endpoints alternativos para tentar
    final endpoints = [
      // Endpoint 1: Informações do usuário YouTube (pode incluir User ID)
      'https://www.googleapis.com/youtube/v3/channels?mine=true&part=id,snippet,contentDetails,statistics',
      
      // Endpoint 2: Tentar obter info de canais favoritos (fallback)
      'https://www.googleapis.com/youtube/v3/subscriptions?mine=true&part=snippet&maxResults=1',
      
      // Endpoint 3: Activities (histórico do usuário pode conter User ID)
      'https://www.googleapis.com/youtube/v3/activities?mine=true&part=snippet,contentDetails&maxResults=1',
    ];
    
    for (int i = 0; i < endpoints.length; i++) {
      try {
        if (kDebugMode) {
          print('🔍 [AuthGoogleService] Tentando endpoint ${i + 1}/${endpoints.length}...');
        }
        
        final response = await _httpClient.get(
          Uri.parse(endpoints[i]),
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Accept': 'application/json',
          },
        );
        
        if (kDebugMode) {
          print('📡 [AuthGoogleService] Endpoint ${i + 1} - Status: ${response.statusCode}');
        }
        
        if (response.statusCode == 200) {
          final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
          
          if (kDebugMode) {
            print('📡 [AuthGoogleService] Endpoint ${i + 1} - Response completa:');
            print(jsonEncode(jsonResponse));
          }
          
          // Tentar extrair User ID de diferentes campos
          final possibleUserIdPaths = [
            ['items', 0, 'id'],
            ['items', 0, 'snippet', 'userId'],
            ['items', 0, 'snippet', 'channelId'],
            ['items', 0, 'contentDetails', 'userId'],
            ['userId'],
            ['channelId'],
          ];
          
          for (final path in possibleUserIdPaths) {
            dynamic current = jsonResponse;
            bool found = true;
            
            for (final key in path) {
              if (current is Map && current.containsKey(key)) {
                current = current[key];
              } else if (current is List && key is int && key < current.length) {
                current = current[key];
              } else {
                found = false;
                break;
              }
            }
            
            if (found && current is String && current.isNotEmpty) {
              if (kDebugMode) {
                print('✅ [AuthGoogleService] Possível User ID encontrado em ${path.join('.')}: $current');
              }
              
              // Se começa com UX (User ID legado) ou UC (Channel ID), pode ser útil
              if (current.startsWith('UX') || current.startsWith('UC')) {
                return {'userId': current};
              }
            }
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ [AuthGoogleService] Erro no endpoint ${i + 1}: $e');
        }
        continue; // Tenta próximo endpoint
      }
    }
    
    if (kDebugMode) {
      print('⚠️ [AuthGoogleService] Nenhum User ID básico encontrado após ${endpoints.length} tentativas');
    }
    
    return {'userId': null};
  }

  /// Envia dados OAuth para backend e obtém JWT do app
  Future<AuthCredentialsLoginResponse> authenticateWithBackend(
    AuthGoogleUserData googleData,
  ) async {
    try {
      final request = AuthGoogleOAuthRequest(
        email: googleData.email,
        name: googleData.firstName.isNotEmpty ? googleData.firstName : googleData.email.split('@').first,
        surname: googleData.surname,
        oauthProvider: 'GOOGLE',
        oauthId: googleData.id,
        accessToken: googleData.accessToken!,
        idToken: googleData.idToken,
        // ✅ Enviar YouTube User ID e Channel ID para backend
        youtubeUserId: googleData.youtubeUserId,
        youtubeChannelId: googleData.youtubeChannelId,
        youtubeChannelTitle: googleData.youtubeChannelTitle,
      );

      if (kDebugMode) {
        print('🌐 [AuthGoogleService] Autenticando com backend...');
        print('📍 [AuthGoogleService] URL: $baseUrl/auth/oauth/google');
        print('📤 [AuthGoogleService] Request: ${request.toString()}');
      }

      // POST para endpoint de OAuth do backend
      final response = await _httpClient.post(
        Uri.parse('$baseUrl/auth/oauth/google'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(request.toJson()),
      );

      if (kDebugMode) {
        print('📥 [AuthGoogleService] Status Code: ${response.statusCode}');
        final bodyPreview = response.body.length > 200
            ? '${response.body.substring(0, 200)}...'
            : response.body;
        print('📥 [AuthGoogleService] Response: $bodyPreview');
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        final loginResponse = AuthCredentialsLoginResponse.fromJson(jsonResponse);

        if (kDebugMode) {
          print('✅ [AuthGoogleService] Autenticação com backend bem-sucedida');
          print('🔑 [AuthGoogleService] App Token: ${loginResponse.token.substring(0, 20)}...');
        }

        // 🐛 DEBUG: Salvar resposta do backend em arquivo .log (COMPLETO com YouTube)
        await OAuthDebugLogger.logOAuthData(
          googleData: {
            'id': googleData.id,
            'email': googleData.email,
            'displayName': googleData.displayName,
            'photoUrl': googleData.photoUrl,
            'accessToken': googleData.accessToken,
            'idToken': googleData.idToken,
            'scopes': googleData.scopes,
            // ✨ Dados YouTube
            'youtubeUserId': googleData.youtubeUserId,
            'youtubeChannelId': googleData.youtubeChannelId,
            'youtubeChannelTitle': googleData.youtubeChannelTitle,
            'hasYouTubeChannel': googleData.hasYouTubeChannel,
            // Dados enviados ao backend
            'sentToBackend': request.toJson(),
          },
          backendResponse: jsonResponse,
        );

        // 🖨️ ANDROID FIX: Imprimir log no console (quando não tem acesso ao adb)
        if (kDebugMode) {
          await OAuthDebugLogger.printLogToConsole();
        }

        return loginResponse;
      } else if (response.statusCode == 401) {
        throw AuthException(
          'Credenciais OAuth inválidas',
          statusCode: response.statusCode,
        );
      } else if (response.statusCode == 400) {
        final Map<String, dynamic> errorJson = jsonDecode(response.body);
        final errorMessage = errorJson['message'] ?? 'Dados OAuth inválidos';
        throw AuthException(
          errorMessage,
          statusCode: response.statusCode,
        );
      } else if (response.statusCode >= 500) {
        throw AuthException(
          'Erro no servidor. Tente novamente mais tarde',
          statusCode: response.statusCode,
        );
      } else {
        throw AuthException(
          'Erro ao autenticar com backend: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on AuthException {
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        print('❌ [AuthGoogleService] Erro ao autenticar com backend: $e');
      }
      throw AuthException('Erro de conexão com servidor: $e');
    }
  }

  /// Logout do Google
  Future<void> signOut() async {
    // 🎭 MOCK: Usar logout fake se habilitado
    if (AuthGoogleMockService.isMockEnabled) {
      return await _mockService.signOut();
    }

    try {
      if (kDebugMode) {
        print('🚪 [AuthGoogleService] Fazendo logout do Google...');
      }

      await _googleSignIn.signOut();

      if (kDebugMode) {
        print('✅ [AuthGoogleService] Logout realizado com sucesso');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [AuthGoogleService] Erro ao fazer logout (ignorando): $e');
      }
      // Ignorar erros de logout, pois o token será limpo localmente de qualquer forma
    }
  }

  /// Desconecta completamente a conta Google (revoga acesso)
  Future<void> disconnect() async {
    // 🎭 MOCK: Usar disconnect fake se habilitado
    if (AuthGoogleMockService.isMockEnabled) {
      return await _mockService.disconnect();
    }

    try {
      if (kDebugMode) {
        print('🔌 [AuthGoogleService] Desconectando conta Google...');
      }

      await _googleSignIn.disconnect();

      if (kDebugMode) {
        print('✅ [AuthGoogleService] Desconexão realizada com sucesso');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [AuthGoogleService] Erro ao desconectar (ignorando): $e');
      }
    }
  }

  /// Verifica se usuário está logado no Google
  bool get isSignedIn {
    if (AuthGoogleMockService.isMockEnabled) {
      return _mockService.isSignedIn;
    }
    return _googleSignIn.currentUser != null;
  }

  /// Obtém usuário atual (se logado)
  GoogleSignInAccount? get currentUser {
    if (AuthGoogleMockService.isMockEnabled) {
      return null; // Mock não tem usuário real
    }
    return _googleSignIn.currentUser;
  }

  /// Verifica se está em modo mock
  static bool get isMockMode => AuthGoogleMockService.isMockEnabled;
}
