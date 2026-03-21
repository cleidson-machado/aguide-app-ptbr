import 'package:flutter/foundation.dart';
import '../models/connection_profile_model.dart';

/// ViewModel para gerenciar dados da tela UserRelationNetworkScreen
/// MOCKADO - dados temporários para desenvolvimento da UI
class UserRelationNetworkViewModel extends ChangeNotifier {
  // Query de busca
  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  // ========== DADOS MOCKADOS ==========

  /// Meus Vídeos (horizontal scroll) - 12 itens
  List<ConnectionProfileModel> get featuredProfiles => [
        const ConnectionProfileModel(
          id: '1',
          name: 'Canal Tech',
          avatarUrl: 'https://i.pravatar.cc/150?img=1',
          isOnline: true,
          status: ConnectionStatus.connected,
        ),
        const ConnectionProfileModel(
          id: '2',
          name: 'Vlog Viagens',
          avatarUrl: 'https://i.pravatar.cc/150?img=12',
          isOnline: true,
          status: ConnectionStatus.following,
        ),
        const ConnectionProfileModel(
          id: '3',
          name: 'Receitas Fit',
          avatarUrl: 'https://i.pravatar.cc/150?img=5',
          isOnline: false,
          status: ConnectionStatus.connected,
        ),
        const ConnectionProfileModel(
          id: '100',
          name: 'Gaming Pro',
          avatarUrl: 'https://i.pravatar.cc/150?img=70',
          isOnline: true,
          status: ConnectionStatus.connected,
        ),
        const ConnectionProfileModel(
          id: '101',
          name: 'DIY Criativo',
          avatarUrl: 'https://i.pravatar.cc/150?img=8',
          isOnline: false,
          status: ConnectionStatus.following,
        ),
        const ConnectionProfileModel(
          id: '102',
          name: 'Fitness Zone',
          avatarUrl: 'https://i.pravatar.cc/150?img=18',
          isOnline: true,
          status: ConnectionStatus.connected,
        ),
        const ConnectionProfileModel(
          id: '103',
          name: 'Música Live',
          avatarUrl: 'https://i.pravatar.cc/150?img=28',
          isOnline: true,
          status: ConnectionStatus.following,
        ),
        const ConnectionProfileModel(
          id: '104',
          name: 'Arte Digital',
          avatarUrl: 'https://i.pravatar.cc/150?img=38',
          isOnline: false,
          status: ConnectionStatus.connected,
        ),
        const ConnectionProfileModel(
          id: '105',
          name: 'Idiomas',
          avatarUrl: 'https://i.pravatar.cc/150?img=48',
          isOnline: true,
          status: ConnectionStatus.connected,
        ),
        const ConnectionProfileModel(
          id: '106',
          name: 'Ciência Cool',
          avatarUrl: 'https://i.pravatar.cc/150?img=58',
          isOnline: false,
          status: ConnectionStatus.following,
        ),
        const ConnectionProfileModel(
          id: '107',
          name: 'História',
          avatarUrl: 'https://i.pravatar.cc/150?img=63',
          isOnline: true,
          status: ConnectionStatus.connected,
        ),
        const ConnectionProfileModel(
          id: '108',
          name: 'Pets Fun',
          avatarUrl: 'https://i.pravatar.cc/150?img=69',
          isOnline: false,
          status: ConnectionStatus.following,
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

  /// Sugestões de conexão (horizontal scroll) - 12 itens
  List<ConnectionProfileModel> get suggestions => [
        const ConnectionProfileModel(
          id: '7',
          name: 'Amanda Silva',
          avatarUrl: 'https://i.pravatar.cc/150?img=29',
          isOnline: false,
          status: ConnectionStatus.suggested,
        ),
        const ConnectionProfileModel(
          id: '8',
          name: 'Bruno Castro',
          avatarUrl: 'https://i.pravatar.cc/150?img=33',
          isOnline: false,
          status: ConnectionStatus.suggested,
        ),
        const ConnectionProfileModel(
          id: '9',
          name: 'Carla Souza',
          avatarUrl: 'https://i.pravatar.cc/150?img=68',
          isOnline: false,
          status: ConnectionStatus.suggested,
        ),
        const ConnectionProfileModel(
          id: '200',
          name: 'Diego Alves',
          avatarUrl: 'https://i.pravatar.cc/150?img=3',
          isOnline: true,
          status: ConnectionStatus.suggested,
        ),
        const ConnectionProfileModel(
          id: '201',
          name: 'Elena Rodrigues',
          avatarUrl: 'https://i.pravatar.cc/150?img=23',
          isOnline: false,
          status: ConnectionStatus.suggested,
        ),
        const ConnectionProfileModel(
          id: '202',
          name: 'Fernando Lima',
          avatarUrl: 'https://i.pravatar.cc/150?img=43',
          isOnline: true,
          status: ConnectionStatus.suggested,
        ),
        const ConnectionProfileModel(
          id: '203',
          name: 'Gabriela Martins',
          avatarUrl: 'https://i.pravatar.cc/150?img=53',
          isOnline: false,
          status: ConnectionStatus.suggested,
        ),
        const ConnectionProfileModel(
          id: '204',
          name: 'Henrique Dias',
          avatarUrl: 'https://i.pravatar.cc/150?img=7',
          isOnline: true,
          status: ConnectionStatus.suggested,
        ),
        const ConnectionProfileModel(
          id: '205',
          name: 'Isabela Rocha',
          avatarUrl: 'https://i.pravatar.cc/150?img=17',
          isOnline: false,
          status: ConnectionStatus.suggested,
        ),
        const ConnectionProfileModel(
          id: '206',
          name: 'Jorge Santos',
          avatarUrl: 'https://i.pravatar.cc/150?img=27',
          isOnline: true,
          status: ConnectionStatus.suggested,
        ),
        const ConnectionProfileModel(
          id: '207',
          name: 'Karina Ferreira',
          avatarUrl: 'https://i.pravatar.cc/150?img=37',
          isOnline: false,
          status: ConnectionStatus.suggested,
        ),
        const ConnectionProfileModel(
          id: '208',
          name: 'Leonardo Costa',
          avatarUrl: 'https://i.pravatar.cc/150?img=67',
          isOnline: true,
          status: ConnectionStatus.suggested,
        ),
      ];

  /// Temas em Destaque (scroll vertical independente)
  List<ConnectionProfileModel> get temasDestaque => [
        const ConnectionProfileModel(
          id: '20',
          name: 'Tecnologia',
          avatarUrl: 'https://i.pravatar.cc/150?img=11',
          isOnline: true,
          status: ConnectionStatus.connected,
        ),
        const ConnectionProfileModel(
          id: '21',
          name: 'Design',
          avatarUrl: 'https://i.pravatar.cc/150?img=22',
          isOnline: false,
          status: ConnectionStatus.suggested,
        ),
        const ConnectionProfileModel(
          id: '22',
          name: 'Marketing',
          avatarUrl: 'https://i.pravatar.cc/150?img=31',
          isOnline: true,
          status: ConnectionStatus.following,
        ),
        const ConnectionProfileModel(
          id: '23',
          name: 'Negócios',
          avatarUrl: 'https://i.pravatar.cc/150?img=41',
          isOnline: false,
          status: ConnectionStatus.connected,
        ),
        const ConnectionProfileModel(
          id: '24',
          name: 'Educação',
          avatarUrl: 'https://i.pravatar.cc/150?img=51',
          isOnline: true,
          status: ConnectionStatus.suggested,
        ),
        const ConnectionProfileModel(
          id: '25',
          name: 'Saúde',
          avatarUrl: 'https://i.pravatar.cc/150?img=61',
          isOnline: false,
          status: ConnectionStatus.connected,
        ),
        const ConnectionProfileModel(
          id: '26',
          name: 'Finanças',
          avatarUrl: 'https://i.pravatar.cc/150?img=14',
          isOnline: true,
          status: ConnectionStatus.following,
        ),
        const ConnectionProfileModel(
          id: '27',
          name: 'Artes',
          avatarUrl: 'https://i.pravatar.cc/150?img=24',
          isOnline: false,
          status: ConnectionStatus.suggested,
        ),
        const ConnectionProfileModel(
          id: '28',
          name: 'Música',
          avatarUrl: 'https://i.pravatar.cc/150?img=34',
          isOnline: true,
          status: ConnectionStatus.connected,
        ),
        const ConnectionProfileModel(
          id: '29',
          name: 'Esportes',
          avatarUrl: 'https://i.pravatar.cc/150?img=44',
          isOnline: false,
          status: ConnectionStatus.following,
        ),
        const ConnectionProfileModel(
          id: '30',
          name: 'Viagens',
          avatarUrl: 'https://i.pravatar.cc/150?img=54',
          isOnline: true,
          status: ConnectionStatus.suggested,
        ),
        const ConnectionProfileModel(
          id: '31',
          name: 'Fotografia',
          avatarUrl: 'https://i.pravatar.cc/150?img=64',
          isOnline: false,
          status: ConnectionStatus.connected,
        ),
        const ConnectionProfileModel(
          id: '32',
          name: 'Cinema',
          avatarUrl: 'https://i.pravatar.cc/150?img=16',
          isOnline: true,
          status: ConnectionStatus.following,
        ),
        const ConnectionProfileModel(
          id: '33',
          name: 'Literatura',
          avatarUrl: 'https://i.pravatar.cc/150?img=26',
          isOnline: false,
          status: ConnectionStatus.suggested,
        ),
        const ConnectionProfileModel(
          id: '34',
          name: 'Gastronomia',
          avatarUrl: 'https://i.pravatar.cc/150?img=36',
          isOnline: true,
          status: ConnectionStatus.connected,
        ),
        const ConnectionProfileModel(
          id: '35',
          name: 'Moda',
          avatarUrl: 'https://i.pravatar.cc/150?img=46',
          isOnline: false,
          status: ConnectionStatus.following,
        ),
        const ConnectionProfileModel(
          id: '36',
          name: 'Sustentabilidade',
          avatarUrl: 'https://i.pravatar.cc/150?img=56',
          isOnline: true,
          status: ConnectionStatus.suggested,
        ),
        const ConnectionProfileModel(
          id: '37',
          name: 'Inovação',
          avatarUrl: 'https://i.pravatar.cc/150?img=66',
          isOnline: false,
          status: ConnectionStatus.connected,
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
