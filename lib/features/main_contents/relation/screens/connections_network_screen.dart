import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import '../models/connection_profile_model.dart';
import '../viewmodels/connections_network_view_model.dart';

/// Tela de Rede de Conexões (Connections Network)
/// Navegação horizontal com 3 segmentos:
/// 1. Meus Videos
/// 2. Minhas Conexões
/// 3. Sugestões
/// 
/// Dados mockados para desenvolvimento da UI
class ConnectionsNetworkScreen extends StatefulWidget {
  const ConnectionsNetworkScreen({super.key});

  @override
  State<ConnectionsNetworkScreen> createState() => _ConnectionsNetworkScreenState();
}

class _ConnectionsNetworkScreenState extends State<ConnectionsNetworkScreen> {
  late final ConnectionsNetworkViewModel _viewModel;
  late final PageController _pageController;
  late final TextEditingController _searchController;

  final List<String> _segmentTitles = [
    'Meus Videos',
    'Minhas Conexões',
    'Sugestões',
  ];

  @override
  void initState() {
    super.initState();
    _viewModel = ConnectionsNetworkViewModel();
    _pageController = PageController();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _searchController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    _viewModel.setActiveSegment(index);
  }

  void _onSegmentTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text(
          'Connections Network',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: CupertinoColors.systemBackground.resolveFrom(context),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Campo de busca
            _buildSearchBar(),

            // Segmentos personalizados (horizontal tabs)
            _buildCustomSegmentedControl(),

            // Cards destacados no topo (horizontal scroll)
            _buildFeaturedSection(),

            // Conteúdo das páginas (PageView)
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                children: [
                  _buildMeusVideosPage(),
                  _buildMinhasConexoesPage(),
                  _buildSugestoesPage(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Campo de busca
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: CupertinoSearchTextField(
        controller: _searchController,
        placeholder: 'Buscar',
        onChanged: (value) => _viewModel.setSearchQuery(value),
        style: const TextStyle(fontSize: 16),
      ),
    );
  }

  /// Segmentos personalizados (como tabs horizontais)
  Widget _buildCustomSegmentedControl() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: AnimatedBuilder(
        animation: _viewModel,
        builder: (context, child) {
          return Row(
            children: List.generate(_segmentTitles.length, (index) {
              final isActive = _viewModel.activeSegment == index;
              return Expanded(
                child: GestureDetector(
                  onTap: () => _onSegmentTapped(index),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: isActive
                              ? CupertinoColors.activeBlue
                              : CupertinoColors.systemGrey5,
                          width: isActive ? 3 : 1,
                        ),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _segmentTitles[index],
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                          color: isActive
                              ? CupertinoColors.activeBlue
                              : CupertinoColors.systemGrey,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }

  /// Seção de perfis destacados (horizontal scroll no topo)
  Widget _buildFeaturedSection() {
    return Container(
      height: 130,
      margin: const EdgeInsets.only(top: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _viewModel.featuredProfiles.length,
        itemBuilder: (context, index) {
          final profile = _viewModel.featuredProfiles[index];
          return _buildFeaturedCard(profile);
        },
      ),
    );
  }

  /// Card de perfil destacado (horizontal)
  Widget _buildFeaturedCard(ConnectionProfileModel profile) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          // Avatar com indicador online
          Stack(
            children: [
              ClipOval(
                child: CachedNetworkImage(
                  imageUrl: profile.avatarUrl,
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const CupertinoActivityIndicator(),
                  errorWidget: (context, url, error) => Container(
                    width: 70,
                    height: 70,
                    color: CupertinoColors.systemGrey5,
                    child: const Icon(CupertinoIcons.person_fill),
                  ),
                ),
              ),
              if (profile.isOnline)
                Positioned(
                  right: 2,
                  bottom: 2,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGreen,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: CupertinoColors.systemBackground.resolveFrom(context),
                        width: 2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          // Nome
          Text(
            profile.name,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          // Status
          Text(
            profile.status.displayName,
            style: TextStyle(
              fontSize: 11,
              color: profile.status == ConnectionStatus.connected
                  ? CupertinoColors.systemGreen
                  : CupertinoColors.systemGrey,
            ),
          ),
        ],
      ),
    );
  }

  // ========== PÁGINAS DO PAGEVIEW ==========

  /// Página 1: Meus Videos (mockado vazio)
  Widget _buildMeusVideosPage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.play_rectangle,
            size: 64,
            color: CupertinoColors.systemGrey3.resolveFrom(context),
          ),
          const SizedBox(height: 16),
          Text(
            'Meus Videos',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.systemGrey.resolveFrom(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Seus vídeos aparecerão aqui',
            style: TextStyle(
              fontSize: 14,
              color: CupertinoColors.systemGrey2.resolveFrom(context),
            ),
          ),
        ],
      ),
    );
  }

  /// Página 2: Minhas Conexões
  Widget _buildMinhasConexoesPage() {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, child) {
        final profiles = _viewModel.getFilteredProfiles(_viewModel.myConnections);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Minhas Conexões',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.label.resolveFrom(context),
                ),
              ),
              const SizedBox(height: 16),
              ...profiles.map((profile) => _buildConnectionCard(profile)).toList(),
            ],
          ),
        );
      },
    );
  }

  /// Página 3: Sugestões
  Widget _buildSugestoesPage() {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, child) {
        final profiles = _viewModel.getFilteredProfiles(_viewModel.suggestions);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sugestões',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.label.resolveFrom(context),
                ),
              ),
              const SizedBox(height: 16),
              ...profiles.map((profile) => _buildSuggestionCard(profile)).toList(),
            ],
          ),
        );
      },
    );
  }

  /// Card de conexão (para "Minhas Conexões")
  Widget _buildConnectionCard(ConnectionProfileModel profile) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: CupertinoColors.systemGrey5.resolveFrom(context),
        ),
      ),
      child: Row(
        children: [
          // Avatar com indicador online
          Stack(
            children: [
              ClipOval(
                child: CachedNetworkImage(
                  imageUrl: profile.avatarUrl,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const CupertinoActivityIndicator(),
                  errorWidget: (context, url, error) => Container(
                    width: 60,
                    height: 60,
                    color: CupertinoColors.systemGrey5,
                    child: const Icon(CupertinoIcons.person_fill),
                  ),
                ),
              ),
              if (profile.isOnline)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGreen,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: CupertinoColors.systemBackground.resolveFrom(context),
                        width: 2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          // Nome e status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  profile.status.displayName,
                  style: TextStyle(
                    fontSize: 13,
                    color: profile.status == ConnectionStatus.connected
                        ? CupertinoColors.systemGreen
                        : CupertinoColors.systemGrey,
                  ),
                ),
              ],
            ),
          ),
          // Botões de ação
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => _viewModel.viewProfile(profile),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: CupertinoColors.systemGrey4),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Ver Perfil',
                    style: TextStyle(fontSize: 13, color: CupertinoColors.label),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => _viewModel.sendMessage(profile),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: CupertinoColors.activeBlue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Enviar Mensagem',
                    style: TextStyle(fontSize: 13, color: CupertinoColors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Card de sugestão (para "Sugestões")
  Widget _buildSuggestionCard(ConnectionProfileModel profile) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: CupertinoColors.systemGrey5.resolveFrom(context),
        ),
      ),
      child: Row(
        children: [
          // Avatar
          ClipOval(
            child: CachedNetworkImage(
              imageUrl: profile.avatarUrl,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              placeholder: (context, url) => const CupertinoActivityIndicator(),
              errorWidget: (context, url, error) => Container(
                width: 60,
                height: 60,
                color: CupertinoColors.systemGrey5,
                child: const Icon(CupertinoIcons.person_fill),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Nome e status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  profile.status.displayName,
                  style: const TextStyle(
                    fontSize: 13,
                    color: CupertinoColors.systemGrey,
                  ),
                ),
              ],
            ),
          ),
          // Botão conectar
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () {
              _viewModel.connect(profile);
              // Mock: mostrar feedback
              if (kDebugMode) {
                showCupertinoDialog(
                  context: context,
                  builder: (context) => CupertinoAlertDialog(
                    title: const Text('Solicitação Enviada'),
                    content: Text('Você enviou uma solicitação de conexão para ${profile.name}'),
                    actions: [
                      CupertinoDialogAction(
                        isDefaultAction: true,
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: CupertinoColors.activeBlue,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Conectar',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
