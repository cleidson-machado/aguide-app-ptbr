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
/// - Seção "Temas em Destaque" (grid vertical)
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
          'Guia - PORTUGAL - Relações',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: CupertinoColors.systemGroupedBackground.resolveFrom(context),
        border: null,
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

                // Linha divisória com ponto
                SliverToBoxAdapter(
                  child: _buildDividerWithDot(),
                ),

                // Seção "Minhas Conexões"
                SliverToBoxAdapter(
                  child: _buildSectionTitle('Minhas Conexões'),
                ),
                _buildConnectionsSection(),

                // Linha divisória com ponto
                SliverToBoxAdapter(
                  child: _buildDividerWithDot(),
                ),

                // Seção "Sugestões"
                SliverToBoxAdapter(
                  child: _buildSectionTitle('Sugestões'),
                ),
                _buildSuggestionsSection(),

                // Linha divisória com ponto
                SliverToBoxAdapter(
                  child: _buildDividerWithDot(),
                ),

                // Seção "Temas em Destaque"
                SliverToBoxAdapter(
                  child: _buildSectionTitle('Temas em Destaque'),
                ),
                _buildTemasDestaqueSection(),

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

  /// Título de seção com chevron
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.label.resolveFrom(context),
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            CupertinoIcons.chevron_right,
            size: 18,
            color: CupertinoColors.systemGrey.resolveFrom(context),
          ),
        ],
      ),
    );
  }

  /// Linha divisória com ponto central
  Widget _buildDividerWithDot() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Linha horizontal mais visível
          Container(
            height: 2,
            color: CupertinoColors.systemGrey3.resolveFrom(context),
          ),
          // Ponto central
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey2.resolveFrom(context),
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  /// Seção "Meus Vídeos" - Scroll horizontal
  Widget _buildMeusVideosSection() {
    final profiles = _viewModel.getFilteredProfiles(_viewModel.featuredProfiles);

    return SliverToBoxAdapter(
      child: Container(
        height: 120,
        margin: const EdgeInsets.only(bottom: 16),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: profiles.length,
          itemBuilder: (context, index) {
            final profile = profiles[index];
            return Container(
              width: 100,
              margin: const EdgeInsets.only(right: 12),
              child: _buildMeusVideosProfileCard(profile),
            );
          },
        ),
      ),
    );
  }

  /// Seção "Minhas Conexões" - Scroll horizontal
  Widget _buildConnectionsSection() {
    final profiles = _viewModel.getFilteredProfiles(_viewModel.myConnections);

    return SliverToBoxAdapter(
      child: Container(
        height: 120,
        margin: const EdgeInsets.only(bottom: 16),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: profiles.length,
          itemBuilder: (context, index) {
            final profile = profiles[index];
            return Container(
              width: 100,
              margin: const EdgeInsets.only(right: 12),
              child: _buildConnectionProfileCard(profile),
            );
          },
        ),
      ),
    );
  }

  /// Seção "Sugestões" - Scroll horizontal
  Widget _buildSuggestionsSection() {
    final profiles = _viewModel.getFilteredProfiles(_viewModel.suggestions);

    return SliverToBoxAdapter(
      child: Container(
        height: 120,
        margin: const EdgeInsets.only(bottom: 16),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: profiles.length,
          itemBuilder: (context, index) {
            final profile = profiles[index];
            return Container(
              width: 100,
              margin: const EdgeInsets.only(right: 12),
              child: _buildSuggestionProfileCard(profile),
            );
          },
        ),
      ),
    );
  }

  /// Seção "Temas em Destaque" - Scroll vertical independente
  Widget _buildTemasDestaqueSection() {
    final profiles = _viewModel.getFilteredProfiles(_viewModel.temasDestaque);

    return SliverToBoxAdapter(
      child: Container(
        height: 400, // Altura fixa para scroll independente
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: (profiles.length / 3).ceil(),
          itemBuilder: (context, rowIndex) {
            final startIndex = rowIndex * 3;
            final rowProfiles = <ConnectionProfileModel>[];
            
            for (int i = 0; i < 3; i++) {
              final profileIndex = startIndex + i;
              if (profileIndex < profiles.length) {
                rowProfiles.add(profiles[profileIndex]);
              }
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: rowProfiles.map((profile) {
                  return Expanded(
                    child: _buildTemasDestaqueProfileCard(profile),
                  );
                }).toList(),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Card de perfil quadrado (para "Meus Vídeos")
  Widget _buildMeusVideosProfileCard(ConnectionProfileModel profile) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
          // Avatar quadrado com bordas arredondadas
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: profile.avatarUrl,
              width: 70,
              height: 70,
              fit: BoxFit.cover,
              placeholder: (context, url) => const CupertinoActivityIndicator(),
              errorWidget: (context, url, error) => Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey5,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(CupertinoIcons.play_rectangle_fill, size: 35),
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

  /// Card de perfil circular (para "Temas em Destaque")
  Widget _buildTemasDestaqueProfileCard(ConnectionProfileModel profile) {
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