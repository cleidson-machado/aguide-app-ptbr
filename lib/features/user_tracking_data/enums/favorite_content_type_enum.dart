/// Enum para tipos de conteúdo favorito do usuário
/// 
/// Usado para rastrear preferências de conteúdo no sistema de ranking
/// Backend valida que apenas estes valores sejam aceitos
/// 
/// Referência: .local_knowledge/add-user-tracking-phase-b/RESPONSE_FRONTEND_PHASE_B_IMPLEMENTATION.md
enum FavoriteContentType {
  /// Vídeos (YouTube, Vimeo, etc.)
  video,
  
  /// Artigos e posts de blog
  article,
  
  /// Cursos estruturados
  course,
  
  /// Tutoriais passo-a-passo
  tutorial,
  
  /// Guias e documentação
  guide;

  /// Converte enum para string lowercase (formato API)
  /// 
  /// Exemplo: FavoriteContentType.video.toJson() → "video"
  String toJson() => name;

  /// Converte string lowercase para enum
  /// 
  /// Retorna null se valor não reconhecido
  /// 
  /// Exemplo:
  /// ```dart
  /// FavoriteContentType.fromString("video") → FavoriteContentType.video
  /// FavoriteContentType.fromString("podcast") → null
  /// ```
  static FavoriteContentType? fromString(String? value) {
    if (value == null) return null;
    
    try {
      return FavoriteContentType.values.firstWhere(
        (e) => e.name == value.toLowerCase(),
      );
    } catch (_) {
      return null; // Valor não reconhecido
    }
  }
}
