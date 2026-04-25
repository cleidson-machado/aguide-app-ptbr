import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:portugal_guide/features/user/user_details_model.dart';

/// Extension para UserDetailsModel com lógica de classificação de perfil
/// 
/// Determina se o usuário é CRIADOR (Produtor) ou CONSUMIDOR de conteúdo
/// baseado na presença de youtubeUserId e youtubeChannelId.
/// 
/// Também fornece métodos auxiliares para exibição (initials, avatar color)
extension UserDetailsModelExtensions on UserDetailsModel {
  /// Gera iniciais do usuário baseado no nome completo
  /// 
  /// Exemplo: "João Silva" → "JS"
  String getInitials() {
    final parts = fullName.trim().split(' ');
    if (parts.isEmpty) return '??';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  /// Gera cor consistente para o avatar baseado no hash do ID
  /// 
  /// Garante que o mesmo usuário sempre tenha a mesma cor
  Color getAvatarColor() {
    final hash = id.hashCode;
    final colors = [
      CupertinoColors.systemBlue,
      CupertinoColors.systemGreen,
      CupertinoColors.systemOrange,
      CupertinoColors.systemPurple,
      CupertinoColors.systemTeal,
      CupertinoColors.systemIndigo,
      CupertinoColors.systemPink,
    ];
    return colors[hash.abs() % colors.length];
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
      debugPrint('🔍 [UserDetailsModelExtensions.isContentCreator] Verificação:');
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
  
  /// Retorna o label completo usado na tela principal (para referência)
  /// 
  /// Este formato NÃO será usado na lista de usuários (muito longo),
  /// apenas mantido para compatibilidade com a tela principal
  String get topicHeaderLabel {
    return isContentCreator 
        ? '| TEMAS - Perfil CRIADOR de Conteúdo |' 
        : '| TEMAS - Perfil CONSUMIDOR de Conteúdo |';
  }
}
