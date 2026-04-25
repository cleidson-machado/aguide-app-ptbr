import 'package:flutter/foundation.dart';
import 'package:portugal_guide/features/user/user_model.dart';
import 'package:portugal_guide/features/user/user_details_model.dart';

/// Modelo híbrido que combina UserModel + UserDetailsModel
/// 
/// Específico para feature user_message_flow - permite exibir
/// informações básicas de usuário + role designation (PRODUTOR/CONSUMIDOR)
/// sem depender de mudanças intrusivas em feature core 'user'.
/// 
/// Princípio DDD: Features devem ser independentes - este modelo
/// encapsula dependências externas e mantém user_message_flow desacoplada.
class MessageUserData {
  final String id;
  final String name;
  final String surname;
  final String email;
  final String fullName;
  final String? youtubeUserId;
  final String? youtubeChannelId;

  /// Conversation metadata (only present if user has an existing DIRECT conversation)
  final String? conversationId;
  final DateTime? lastMessageAt;
  final String? lastMessagePreview;
  final int unreadCount;

  const MessageUserData({
    required this.id,
    required this.name,
    required this.surname,
    required this.email,
    required this.fullName,
    this.youtubeUserId,
    this.youtubeChannelId,
    this.conversationId,
    this.lastMessageAt,
    this.lastMessagePreview,
    this.unreadCount = 0,
  });

  MessageUserData copyWith({
    String? conversationId,
    DateTime? lastMessageAt,
    String? lastMessagePreview,
    int? unreadCount,
  }) {
    return MessageUserData(
      id: id,
      name: name,
      surname: surname,
      email: email,
      fullName: fullName,
      youtubeUserId: youtubeUserId,
      youtubeChannelId: youtubeChannelId,
      conversationId: conversationId ?? this.conversationId,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  /// Returns human-readable relative timestamp (e.g. "Just Now", "4h ago", "26 Jun 2023")
  /// Returns null if user has no last message.
  String? get formattedLastMessageAt {
    final ts = lastMessageAt;
    if (ts == null) return null;
    final now = DateTime.now();
    final diff = now.difference(ts);

    if (diff.inSeconds < 60) return 'Agora';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min';
    if (diff.inHours < 24) return '${diff.inHours} h';
    if (diff.inDays == 1) return 'Ontem';
    if (diff.inDays < 7) return '${diff.inDays} d';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} sem';
    // Older: show date "26 Jun 2023"
    const months = [
      'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
      'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez',
    ];
    return '${ts.day} ${months[ts.month - 1]} ${ts.year}';
  }

  /// Factory constructor: combina UserModel + UserDetailsModel
  /// 
  /// Uso: MessageUserData.fromUserAndDetails(userModel, userDetailsModel)
  factory MessageUserData.fromUserAndDetails(
    UserModel user,
    UserDetailsModel details,
  ) {
    return MessageUserData(
      id: user.id,
      name: user.name,
      surname: user.surname,
      email: user.email,
      fullName: '${user.name} ${user.surname}',
      youtubeUserId: details.youtubeUserId,
      youtubeChannelId: details.youtubeChannelId,
    );
  }

  /// Determina se o usuário é CRIADOR (Produtor de Conteúdo)
  /// 
  /// Lógica: Se ambos youtubeUserId E youtubeChannelId são não-nulos → CRIADOR
  /// Qualquer outra combinação → CONSUMIDOR
  bool get isContentCreator {
    final hasYoutubeUserId = youtubeUserId != null && youtubeUserId!.isNotEmpty;
    final hasYoutubeChannelId = youtubeChannelId != null && youtubeChannelId!.isNotEmpty;
    
    final isCriador = hasYoutubeUserId && hasYoutubeChannelId;
    
    if (kDebugMode) {
      debugPrint('🔍 [MessageUserData.isContentCreator] Verificação para $fullName:');
      debugPrint('   youtubeUserId: ${youtubeUserId ?? "NULL"}');
      debugPrint('   youtubeChannelId: ${youtubeChannelId ?? "NULL"}');
      debugPrint('   Resultado: ${isCriador ? "CRIADOR" : "CONSUMIDOR"}');
    }
    
    return isCriador;
  }
  
  /// Retorna o label de role para exibição na UI
  /// 
  /// Retorna "PRODUTOR" ou "CONSUMIDOR" baseado na classificação
  String get roleLabel {
    return isContentCreator ? 'PRODUTOR' : 'CONSUMIDOR';
  }

  /// Gera iniciais do usuário baseado no nome completo
  /// 
  /// Exemplo: "João Silva" → "JS"
  String getInitials() {
    final parts = fullName.trim().split(' ');
    if (parts.isEmpty) return '??';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  @override
  String toString() {
    return 'MessageUserData(id: $id, fullName: $fullName, role: $roleLabel)';
  }
}
