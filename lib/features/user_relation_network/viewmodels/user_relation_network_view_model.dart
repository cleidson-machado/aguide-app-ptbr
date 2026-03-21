import 'package:flutter/foundation.dart';
import '../models/connection_profile_model.dart';

/// ViewModel para gerenciar dados da tela UserRelationNetworkScreen
/// MOCKADO - dados temporários para desenvolvimento da UI
class UserRelationNetworkViewModel extends ChangeNotifier {
  // Query de busca
  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  // ========== DADOS MOCKADOS ==========

  /// Perfis destacados no topo (horizontal scroll)
  List<ConnectionProfileModel> get featuredProfiles => [
        const ConnectionProfileModel(
          id: '1',
          name: 'Suzane Jobs',
          avatarUrl: 'https://i.pravatar.cc/150?img=1',
          isOnline: true,
          status: ConnectionStatus.connected,
        ),
        const ConnectionProfileModel(
          id: '2',
          name: 'João Silva',
          avatarUrl: 'https://i.pravatar.cc/150?img=12',
          isOnline: true,
          status: ConnectionStatus.following,
        ),
        const ConnectionProfileModel(
          id: '3',
          name: 'Suzane Costa',
          avatarUrl: 'https://i.pravatar.cc/150?img=5',
          isOnline: false,
          status: ConnectionStatus.connected,
        ),
      ];

  /// Minhas Conexões (conectados)
  List<ConnectionProfileModel> get myConnections => [
        const ConnectionProfileModel(
          id: '4',
          name: 'Suzanie Jobs',
          avatarUrl: 'https://i.pravatar.cc/150?img=47',
          isOnline: true,
          status: ConnectionStatus.connected,
        ),
        const ConnectionProfileModel(
          id: '5',
          name: 'João Silva',
          avatarUrl: 'https://i.pravatar.cc/150?img=13',
          isOnline: false,
          status: ConnectionStatus.following,
        ),
        const ConnectionProfileModel(
          id: '6',
          name: 'Suzane Alves',
          avatarUrl: 'https://i.pravatar.cc/150?img=9',
          isOnline: true,
          status: ConnectionStatus.connected,
        ),
        const ConnectionProfileModel(
          id: '10',
          name: 'Maria Santos',
          avatarUrl: 'https://i.pravatar.cc/150?img=20',
          isOnline: true,
          status: ConnectionStatus.connected,
        ),
        const ConnectionProfileModel(
          id: '11',
          name: 'Pedro Costa',
          avatarUrl: 'https://i.pravatar.cc/150?img=15',
          isOnline: false,
          status: ConnectionStatus.connected,
        ),
        const ConnectionProfileModel(
          id: '12',
          name: 'Ana Lima',
          avatarUrl: 'https://i.pravatar.cc/150?img=25',
          isOnline: true,
          status: ConnectionStatus.following,
        ),
        const ConnectionProfileModel(
          id: '13',
          name: 'Carlos Mendes',
          avatarUrl: 'https://i.pravatar.cc/150?img=30',
          isOnline: false,
          status: ConnectionStatus.connected,
        ),
        const ConnectionProfileModel(
          id: '14',
          name: 'Julia Rocha',
          avatarUrl: 'https://i.pravatar.cc/150?img=40',
          isOnline: true,
          status: ConnectionStatus.following,
        ),
        const ConnectionProfileModel(
          id: '15',
          name: 'Lucas Ferreira',
          avatarUrl: 'https://i.pravatar.cc/150?img=52',
          isOnline: false,
          status: ConnectionStatus.connected,
        ),
        const ConnectionProfileModel(
          id: '16',
          name: 'Beatriz Souza',
          avatarUrl: 'https://i.pravatar.cc/150?img=35',
          isOnline: true,
          status: ConnectionStatus.connected,
        ),
        const ConnectionProfileModel(
          id: '17',
          name: 'Rafael Dias',
          avatarUrl: 'https://i.pravatar.cc/150?img=60',
          isOnline: false,
          status: ConnectionStatus.following,
        ),
        const ConnectionProfileModel(
          id: '18',
          name: 'Camila Martins',
          avatarUrl: 'https://i.pravatar.cc/150?img=45',
          isOnline: true,
          status: ConnectionStatus.connected,
        ),
      ];

  /// Sugestões de conexão
  List<ConnectionProfileModel> get suggestions => [
        const ConnectionProfileModel(
          id: '7',
          name: 'Suzane Jobs',
          avatarUrl: 'https://i.pravatar.cc/150?img=29',
          isOnline: false,
          status: ConnectionStatus.suggested,
        ),
        const ConnectionProfileModel(
          id: '8',
          name: 'João Silva',
          avatarUrl: 'https://i.pravatar.cc/150?img=33',
          isOnline: false,
          status: ConnectionStatus.suggested,
        ),
        const ConnectionProfileModel(
          id: '9',
          name: 'Aleson Costa',
          avatarUrl: 'https://i.pravatar.cc/150?img=68',
          isOnline: false,
          status: ConnectionStatus.suggested,
        ),
      ];

  /// Atualiza a query de busca
  void setSearchQuery(String query) {
    if (_searchQuery != query) {
      _searchQuery = query;
      notifyListeners();
    }
  }

  /// Filtra perfis baseado na busca
  List<ConnectionProfileModel> getFilteredProfiles(List<ConnectionProfileModel> profiles) {
    if (_searchQuery.trim().isEmpty) {
      return profiles;
    }

    final query = _searchQuery.toLowerCase();
    return profiles.where((profile) {
      return profile.name.toLowerCase().contains(query);
    }).toList();
  }

  /// Ações mockadas (apenas prints para debug)
  void viewProfile(ConnectionProfileModel profile) {
    if (kDebugMode) {
      debugPrint('🔍 [UserRelationNetwork] Ver perfil: ${profile.name}');
    }
  }

  void sendMessage(ConnectionProfileModel profile) {
    if (kDebugMode) {
      debugPrint('💬 [UserRelationNetwork] Enviar mensagem para: ${profile.name}');
    }
  }

  void connect(ConnectionProfileModel profile) {
    if (kDebugMode) {
      debugPrint('🤝 [UserRelationNetwork] Conectar com: ${profile.name}');
    }
  }

  void disconnect(ConnectionProfileModel profile) {
    if (kDebugMode) {
      debugPrint('❌ [UserRelationNetwork] Desconectar de: ${profile.name}');
    }
  }
}
