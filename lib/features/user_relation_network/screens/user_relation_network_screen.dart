import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import '../models/connection_profile_model.dart';
import '../viewmodels/user_relation_network_view_model.dart';

/// Tela de Rede de Conexões (Connections Network)
/// Layout vertical com scroll contínuo:
/// - Campo de busca
/// - Seção "Meus Vídeos" (grid vertical)
/// - Seção "Minhas Conexões" (grid vertical)
/// - Seção "Sugestões" (grid vertical)
/// 
/// Dados mockados para desenvolvimento da UI
class UserRelationNetworkScreen extends StatefulWidget {
  const UserRelationNetworkScreen({super.key});

  @override
  State<UserRelationNetworkScreen> createState() => _UserRelationNetworkScreenState();
}

class _UserRelationNetworkScreenState extends State<UserRelationNetworkScreen> {
  late final UserRelationNetworkViewModel _viewModel;
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _viewModel = UserRelationNetworkViewModel();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _viewModel.dispose();
    super.dispose();
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
        child: AnimatedBuilder(
          animation: _viewModel,
          builder: (context, child) {
            return CustomScrollView(
              slivers: [
                // Campo de busca
                SliverToBoxAdapter(
                  child: _buildSearchBar(),
                ),

                // Seção "Meus Vídeos"
                SliverToBoxAdapter(
                  child: _buildSectionTitle('Meus Vídeos'),
                ),
                _buildMeusVideosSection(),

                // Seção "Minhas Conexões"
                SliverToBoxAdapter(
                  child: _buildSectionTitle('Minhas Conexões'),
                ),
                _buildConnectionsSection(),

                // Seção "Sugestões"
                SliverToBoxAdapter(
                  child: _buildSectionTitle('Sugestões'),
                ),
                _buildSuggestionsSection(),

                // Espaçamento final
                const SliverToBoxAdapter(
                  child: SizedBox(height: 40),
                ),
              ],
            );
          },
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

  /// Título de seção
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: CupertinoColors.label.resolveFrom(context),
        ),
      ),
    );
  }

  /// Seção "Meus Vídeos" - Grid de avatares circulares
  Widget _buildMeusVideosSection() {
    final profiles = _viewModel.getFilteredProfiles(_viewModel.featuredProfiles);

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 16,
          crossAxisSpacing: 12,
          childAspectRatio: 0.95, // Mais compacto sem status
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final profile = profiles[index];
            return _buildMeusVideosProfileCard(profile);
          },
          childCount: profiles.length,
        ),
      ),
    );
  }

  /// Seção "Minhas Conexões" - Grid de avatares circulares
  Widget _buildConnectionsSection() {
    final profiles = _viewModel.getFilteredProfiles(_viewModel.myConnections);

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 16,
          crossAxisSpacing: 12,
          childAspectRatio: 0.95, // Mais compacto sem status
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final profile = profiles[index];
            return _buildConnectionProfileCard(profile);
          },
          childCount: profiles.length,
        ),
      ),
    );
  }

  /// Seção "Sugestões" - Grid de avatares circulares
  Widget _buildSuggestionsSection() {
    final profiles = _viewModel.getFilteredProfiles(_viewModel.suggestions);

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 16,
          crossAxisSpacing: 12,
          childAspectRatio: 0.95, // Mais compacto sem status
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final profile = profiles[index];
            return _buildSuggestionProfileCard(profile);
          },
          childCount: profiles.length,
        ),
      ),
    );
  }

  /// Card de perfil circular (para "Meus Vídeos")
  Widget _buildMeusVideosProfileCard(ConnectionProfileModel profile) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
          // Avatar
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
                child: const Icon(CupertinoIcons.person_fill, size: 35),
              ),
            ),
          ),
          const SizedBox(height: 6),
          // Nome
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(
              profile.name,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      );
  }

  /// Card de perfil circular (para "Minhas Conexões")
  Widget _buildConnectionProfileCard(ConnectionProfileModel profile) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
          // Avatar
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
                child: const Icon(CupertinoIcons.person_fill, size: 35),
              ),
            ),
          ),
          const SizedBox(height: 6),
          // Nome
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(
              profile.name,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      );
  }

  /// Card de perfil circular (para "Sugestões")
  Widget _buildSuggestionProfileCard(ConnectionProfileModel profile) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
          // Avatar
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
                child: const Icon(CupertinoIcons.person_fill, size: 35),
              ),
            ),
          ),
          const SizedBox(height: 6),
          // Nome
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(
              profile.name,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      );
  }
}