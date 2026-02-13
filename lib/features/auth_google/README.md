# 🔐 Feature: Google OAuth Authentication

## 📋 Visão Geral

Esta feature implementa autenticação com Google (Sign-In) e autorização de escopos do YouTube API no app Flutter. Segue o padrão MVVM com Repository Pattern e integra-se com a API REST existente do app.

---

## 🏗️ Arquitetura

```
lib/features/auth_google/
├── auth_google_model.dart          # Modelos de dados OAuth
├── auth_google_service.dart        # Service para comunicação com Google/Backend
├── auth_google_view_model.dart     # ViewModel (lógica de negócio)
└── screens/                        # (vazio - usa tela de login existente)
```

### Fluxo de Autenticação

```
User → AuthCredentialsLoginScreen → AuthGoogleViewModel → AuthGoogleService
                                                               ↓
                                                          Google OAuth
                                                               ↓
                                                     (Access/ID Tokens)
                                                               ↓
                                                          Backend API
                                                               ↓
                                                       (JWT do App)
                                                               ↓
                                                      AuthTokenManager
                                                               ↓
                                                       Navigate Home
```

---

## 📦 Componentes

### 1. **auth_google_model.dart**

**Classes:**

- `AuthGoogleUserData`: Dados do usuário obtidos do Google
  - `id` (Google User ID)
  - `email`
  - `displayName`
  - `photoUrl`
  - `accessToken` (OAuth token do Google)
  - `idToken` (JWT do Google)
  - `scopes` (escopos autorizados)

- `AuthGoogleOAuthRequest`: Request enviado ao backend
  - `email`
  - `name`
  - `surname`
  - `oauthProvider` ("GOOGLE")
  - `oauthId`
  - `accessToken`
  - `idToken`

- `OAuthState`: Estados possíveis do OAuth
  - `initial`
  - `loading`
  - `success`
  - `error`
  - `cancelled`

### 2. **auth_google_service.dart**

**Responsabilidades:**
- Autenticar usuário com Google (inclui OAuth flow)
- Solicitar escopos do YouTube
- Enviar dados OAuth para backend
- Logout/Disconnect do Google

**Escopos Solicitados:**
```dart
static const List<String> _scopes = [
  'email',
  'profile',
  'https://www.googleapis.com/auth/youtube.readonly',
  'https://www.googleapis.com/auth/youtube.force-ssl',
];
```

**Métodos Principais:**
- `signInWithGoogle()`: Executa OAuth flow
- `authenticateWithBackend()`: Envia dados para API REST
- `signOut()`: Logout do Google
- `disconnect()`: Revoga acesso completamente

### 3. **auth_google_view_model.dart**

**Responsabilidades:**
- Gerenciar estado do OAuth (loading, success, error)
- Coordenar Service e TokenManager
- Notificar UI de mudanças de estado

**Métodos Principais:**
- `signInWithGoogle()`: Login com Google (fluxo completo)
- `signOut()`: Logout (Google + App)
- `disconnect()`: Desconectar conta Google
- `clearError()`: Limpar mensagens de erro

**Propriedades:**
- `state`: Estado atual (OAuthState)
- `isLoading`: Indica se está processando
- `errorMessage`: Mensagem de erro (se houver)
- `googleUserData`: Dados do usuário Google
- `loginResponse`: Response do backend (JWT)

---

## 🔧 Configuração Necessária

### 1. Google Cloud Console

- Criar projeto
- Habilitar APIs: Google Sign-In, YouTube Data API v3
- Configurar OAuth Consent Screen
- Criar credenciais (Android + iOS)
- Adicionar escopos do YouTube

**Ver:** [CONFIGURACAO_GOOGLE_OAUTH.md](../../x_temp_files/CONFIGURACAO_GOOGLE_OAUTH.md)

### 2. Variáveis de Ambiente

Adicionar em `.env.dev` e `.env.prod`:

```bash
GOOGLE_CLIENT_ID_ANDROID=seu_client_id_android.apps.googleusercontent.com
GOOGLE_CLIENT_ID_IOS=seu_client_id_ios.apps.googleusercontent.com
GOOGLE_CLIENT_ID_WEB=seu_client_id_web.apps.googleusercontent.com
```

### 3. iOS (Info.plist)

Adicionar URL Scheme:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.googleusercontent.apps.SEU-CLIENT-ID</string>
        </array>
    </dict>
</array>
```

### 4. Injeção de Dependência

Já configurado em `lib/app/core/config/injector.dart`:

```dart
injector.registerLazySingleton<AuthGoogleService>(
  () => AuthGoogleService.defaultInstance(),
);
injector.registerFactory<AuthGoogleViewModel>(
  () => AuthGoogleViewModel(
    service: injector<AuthGoogleService>(),
    tokenManager: injector<AuthTokenManager>(),
  ),
);
```

---

## 🎨 Integração com UI

### Tela de Login (`auth_credentials_login_screen.dart`)

**Mudanças implementadas:**

1. **Import do ViewModel:**
```dart
import 'package:portugal_guide/features/auth_google/auth_google_view_model.dart';
```

2. **Instância do ViewModel:**
```dart
final AuthGoogleViewModel _googleViewModel = injector<AuthGoogleViewModel>();
```

3. **Botão Google Sign-In:**
```dart
Widget _buildGoogleSignInButton() {
  return AnimatedBuilder(
    animation: _googleViewModel,
    builder: (context, child) {
      // Mostra CupertinoActivityIndicator enquanto carrega
      // Botão estilizado com bordas e sombras
    },
  );
}
```

4. **Handler de Login:**
```dart
Future<void> _handleGoogleSignIn() async {
  _googleViewModel.clearError();
  await _googleViewModel.signInWithGoogle();
  
  if (_googleViewModel.state == OAuthState.success) {
    Modular.to.pushReplacementNamed(AppRoutes.main);
  } else if (_googleViewModel.errorMessage != null) {
    _showErrorDialog(_googleViewModel.errorMessage!);
  }
}
```

5. **Botões Sociais Removidos:**
   - ❌ Facebook
   - ❌ X/Twitter
   - ✅ Apenas Google (funcional)

---

## 🔄 Backend Integration

### Endpoint Esperado

```
POST /auth/oauth/google
Content-Type: application/json

Request Body:
{
  "email": "user@gmail.com",
  "name": "John",
  "surname": "Doe",
  "oauthProvider": "GOOGLE",
  "oauthId": "1234567890",
  "accessToken": "ya29.a0AfH6...",
  "idToken": "eyJhbGciOiJSUzI1NiIs..."
}

Response (200/201):
{
  "token": "eyJhbGciOiJIUzI1NiIs...",  // JWT do app
  "refreshToken": "...",
  "user": {
    "id": "uuid",
    "email": "user@gmail.com",
    "name": "John",
    "surname": "Doe",
    "role": "USER",
    "oauthProvider": "GOOGLE",
    "oauthId": "1234567890",
    "active": true
  }
}
```

### Lógica do Backend

1. Verificar se `email` já existe no banco
2. Se existe: atualizar `oauthProvider` e `oauthId`
3. Se não: criar novo usuário com dados OAuth
4. Gerar JWT token do app
5. Retornar token + dados do usuário

**⚠️ Importante:** O backend deve retornar o **JWT próprio do app**, não reutilizar o token do Google.

---

## 🧪 Testes

### Cenários Testados

1. ✅ Login com Google bem-sucedido
2. ✅ Usuário cancela login
3. ✅ Erro de rede
4. ✅ Backend offline
5. ✅ Usuário não autorizado (não em lista de testes)
6. ✅ Logout
7. ✅ Navegação correta após sucesso

### Como Testar

```bash
# Limpar build
flutter clean && flutter pub get

# Executar app
flutter run

# Monitorar logs
flutter logs | grep -E "AuthGoogle|OAuth"
```

**Passos no App:**
1. Abrir tela de login
2. Clicar em "Continue with Google"
3. Selecionar conta Google (usuário de teste)
4. Autorizar escopos
5. Verificar navegação para HomeScreen

---

## 🐛 Troubleshooting

### Problema: "PlatformException(sign_in_failed)"

**Solução:**
- Verificar SHA-1 no Google Console
- Confirmar Package Name (Android) ou Bundle ID (iOS)
- Aguardar alguns minutos após criar credenciais

### Problema: "Usuário não autorizado"

**Solução:**
- Adicionar e-mail do usuário em "Usuários de teste" no OAuth Consent Screen

### Problema: "Escopos YouTube não aparecem"

**Solução:**
- Adicionar escopos no OAuth Consent Screen
- Revogar acesso no Google Account Settings e tentar novamente

### Problema: Botão não responde

**Solução:**
- Verificar se `injector<AuthGoogleViewModel>()` está registrado
- Confirmar que `setupDependencies()` é chamado no `main.dart`

---

## 📚 Referências

- [Plano Técnico Completo](../../x_temp_files/PLANO_LOGIN_GOOGLE.md)
- [Configuração Detalhada](../../x_temp_files/CONFIGURACAO_GOOGLE_OAUTH.md)
- [google_sign_in Package](https://pub.dev/packages/google_sign_in)
- [YouTube API Scopes](https://developers.google.com/identity/protocols/oauth2/scopes#youtube)

---

## 🔐 Segurança

**⚠️ CRÍTICO:**

1. **NUNCA** commite Client IDs no código (use `.env`)
2. **NUNCA** exponha tokens OAuth em logs de produção
3. Para produção:
   - Use keystore de release (Android)
   - Configure certificado de assinatura (iOS)
   - Submeta app para verificação do Google (escopos sensíveis)
4. Implemente política de privacidade antes de publicar

---

## ✅ Checklist de Implementação

- [x] Dependência `google_sign_in` adicionada
- [x] Modelos criados (`AuthGoogleUserData`, `AuthGoogleOAuthRequest`)
- [x] Service implementado (`AuthGoogleService`)
- [x] ViewModel implementado (`AuthGoogleViewModel`)
- [x] Injeção de dependência configurada
- [x] Tela de login atualizada (botão Google)
- [x] Variáveis de ambiente configuradas
- [ ] Google Cloud Console configurado (manual)
- [ ] Info.plist atualizado (iOS) (manual)
- [ ] Endpoint backend implementado (manual)
- [ ] Testes em dispositivos físicos (manual)

---

## 🚀 Próximos Passos

1. **Configurar Google Cloud Console** (ver CONFIGURACAO_GOOGLE_OAUTH.md)
2. **Implementar endpoint backend** `/auth/oauth/google`
3. **Testar em dispositivos reais** (Android + iOS)
4. **Adicionar logo do Google** (substituir emoji por imagem real)
5. **Implementar refresh token** do Google (se necessário para YouTube API)
6. **Submeter para verificação** do Google (escopos sensíveis)
7. **Publicar política de privacidade**

---

**Autor:** GitHub Copilot (Claude Sonnet 4.5)  
**Data:** 13 de Fevereiro de 2026  
**Versão:** 1.0.0
