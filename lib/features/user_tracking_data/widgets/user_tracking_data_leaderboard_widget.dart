import 'package:flutter/cupertino.dart';
import 'package:portugal_guide/features/user_tracking_data/user_tracking_data_model.dart';
import 'package:portugal_guide/features/user_tracking_data/user_tracking_data_view_model.dart';

/// Widget para exibir leaderboard (ranking global de usuários)
/// 
/// Documentação: .local_knowledge/FLUTTER_USER_TRACKING_MVP_GUIDE.md
/// 
/// 🎯 Responsabilidade: Exibir top N usuários ordenados por pontuação
/// 
/// Features:
/// - Top 10 usuários (configurável)
/// - Medalhas para top 3 (🥇🥈🥉)
/// - Destaque para usuário atual
/// - Loading/Error states
/// - Pull-to-refresh
/// 
/// Quando usar:
/// - Tela de ranking/leaderboard
/// - Modal de conquistas
/// - Seção de gamificação na home
/// 
/// Exemplo de uso:
/// ```dart
/// UserTrackingDataLeaderboardWidget(
///   viewModel: injector<UserTrackingDataViewModel>(),
///   currentUserId: currentUserId,
///   limit: 10,
/// )
/// ```
class UserTrackingDataLeaderboardWidget extends StatefulWidget {
  final UserTrackingDataViewModel viewModel;
  final String? currentUserId;
  final int limit;
  final bool scrollable;
  final EdgeInsetsGeometry? padding;

  const UserTrackingDataLeaderboardWidget({
    super.key,
    required this.viewModel,
    this.currentUserId,
    this.limit = 10,
    this.scrollable = true,
    this.padding,
  });

  @override
  State<UserTrackingDataLeaderboardWidget> createState() =>
      _UserTrackingDataLeaderboardWidgetState();
}

class _UserTrackingDataLeaderboardWidgetState
    extends State<UserTrackingDataLeaderboardWidget> {
  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    await widget.viewModel.loadTopUsers(limit: widget.limit);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, child) {
        if (widget.viewModel.isLoading && widget.viewModel.topUsers.isEmpty) {
          return _buildLoadingState();
        }

        if (widget.viewModel.topUsers.isEmpty) {
          return _buildEmptyState();
        }

        return _buildLeaderboard();
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 🎨 BUILD METHODS - DIFERENTES ESTADOS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildLoadingState() {
    return Container(
      padding: widget.padding ?? const EdgeInsets.all(16),
      child: const Center(
        child: CupertinoActivityIndicator(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: widget.padding ?? const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            CupertinoIcons.chart_bar,
            size: 64,
            color: CupertinoColors.systemGrey,
          ),
          const SizedBox(height: 16),
          const Text(
            'Nenhum ranking disponível',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.systemGrey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Seja o primeiro a pontuar!',
            style: TextStyle(
              fontSize: 14,
              color: CupertinoColors.systemGrey,
            ),
          ),
          const SizedBox(height: 24),
          CupertinoButton(
            color: CupertinoColors.systemBlue,
            onPressed: _loadLeaderboard,
            child: const Text('Atualizar'),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboard() {
    final topUsers = widget.viewModel.topUsers;

    if (widget.scrollable) {
      return CustomScrollView(
        slivers: [
          CupertinoSliverRefreshControl(
            onRefresh: _loadLeaderboard,
          ),
          SliverPadding(
            padding: widget.padding ?? const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index == 0) {
                    return _buildHeader();
                  }

                  final user = topUsers[index - 1];
                  final position = index; // 1-based position

                  return _buildLeaderboardItem(
                    ranking: user,
                    position: position,
                    isCurrentUser:
                        widget.currentUserId != null && user.userId == widget.currentUserId,
                  );
                },
                childCount: topUsers.length + 1, // +1 para header
              ),
            ),
          ),
        ],
      );
    } else {
      // Non-scrollable (usada dentro de outra ScrollView)
      return Padding(
        padding: widget.padding ?? const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            ...topUsers.asMap().entries.map((entry) {
              final index = entry.key;
              final user = entry.value;
              final position = index + 1;

              return _buildLeaderboardItem(
                ranking: user,
                position: position,
                isCurrentUser:
                    widget.currentUserId != null && user.userId == widget.currentUserId,
              );
            }),
          ],
        ),
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 🎨 COMPONENTES INTERNOS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          const Icon(
            CupertinoIcons.chart_bar_alt_fill,
            color: CupertinoColors.systemBlue,
            size: 28,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ranking Global',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: CupertinoColors.label,
                  ),
                ),
                Text(
                  'Top usuários mais engajados',
                  style: TextStyle(
                    fontSize: 14,
                    color: CupertinoColors.systemGrey,
                  ),
                ),
              ],
            ),
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _loadLeaderboard,
            child: const Icon(
              CupertinoIcons.refresh,
              color: CupertinoColors.systemBlue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardItem({
    required UserTrackingDataModel ranking,
    required int position,
    required bool isCurrentUser,
  }) {
    final level = UserEngagementLevel.fromString(ranking.engagementLevel);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? CupertinoColors.systemBlue.withOpacity(0.1)
            : CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentUser
              ? CupertinoColors.systemBlue
              : CupertinoColors.systemGrey5,
          width: isCurrentUser ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          // Posição + Medalha
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Text(
                  _getPositionEmoji(position),
                  style: const TextStyle(fontSize: 24),
                ),
                Text(
                  '$positionº',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isCurrentUser
                        ? CupertinoColors.systemBlue
                        : CupertinoColors.systemGrey,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Emoji do Nível
          Text(
            level.emoji,
            style: const TextStyle(fontSize: 32),
          ),

          const SizedBox(width: 12),

          // Informações do usuário
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCurrentUser ? 'Você' : 'Usuário ${ranking.userId.substring(0, 8)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isCurrentUser
                        ? CupertinoColors.systemBlue
                        : CupertinoColors.label,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      CupertinoIcons.flame_fill,
                      size: 14,
                      color: CupertinoColors.systemOrange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${ranking.consecutiveDaysStreak} dias',
                      style: const TextStyle(
                        fontSize: 12,
                        color: CupertinoColors.systemGrey,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      CupertinoIcons.calendar,
                      size: 14,
                      color: CupertinoColors.systemGreen,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${ranking.totalActiveDays} ativos',
                      style: const TextStyle(
                        fontSize: 12,
                        color: CupertinoColors.systemGrey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Score
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getScoreColor(position).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.star_fill,
                  color: _getScoreColor(position),
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  '${ranking.totalScore}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _getScoreColor(position),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 🔧 HELPER METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  String _getPositionEmoji(int position) {
    switch (position) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '🏅';
    }
  }

  Color _getScoreColor(int position) {
    switch (position) {
      case 1:
        return CupertinoColors.systemYellow;
      case 2:
        return CupertinoColors.systemGrey;
      case 3:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return CupertinoColors.systemBlue;
    }
  }
}
