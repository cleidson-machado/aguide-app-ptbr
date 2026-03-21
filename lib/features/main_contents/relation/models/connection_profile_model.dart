/// Modelo para representar perfis de conexões na rede
/// Usado na tela ConnectionsNetworkScreen (dados mockados)
class ConnectionProfileModel {
  final String id;
  final String name;
  final String avatarUrl;
  final bool isOnline;
  final ConnectionStatus status;

  const ConnectionProfileModel({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.isOnline,
    required this.status,
  });

  ConnectionProfileModel copyWith({
    String? id,
    String? name,
    String? avatarUrl,
    bool? isOnline,
    ConnectionStatus? status,
  }) {
    return ConnectionProfileModel(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isOnline: isOnline ?? this.isOnline,
      status: status ?? this.status,
    );
  }
}

/// Status da conexão com outro usuário
enum ConnectionStatus {
  connected,    // Conectado (mútuo)
  following,    // Seguindo (unilateral)
  suggested,    // Sugestão de conexão
}

extension ConnectionStatusExtension on ConnectionStatus {
  String get displayName {
    switch (this) {
      case ConnectionStatus.connected:
        return 'Conectado';
      case ConnectionStatus.following:
        return 'Seguindo';
      case ConnectionStatus.suggested:
        return 'Conectar';
    }
  }
}
