import 'package:flutter/cupertino.dart';
import 'package:portugal_guide/features/user_tracking_data/user_tracking_data_view_model.dart';

/// Widget para exibir estatisticas de gamificacao do usuario
/// 
/// Documentacao: .local_knowledge/FLUTTER_USER_TRACKING_MVP_GUIDE.md
/// 
/// Responsabilidade: Exibir card com estatisticas de ranking/pontuacao
/// 
/// Campos exibidos:
/// - Total de pontos (totalScore)
/// - Nivel de engajamento (engagementLevel)
/// - Dias consecutivos (consecutiveDaysStreak)
/// - Total de dias ativos (totalActiveDays)
/// - Posicao no ranking global (opcional)
/// - Barra de progresso ate proximo nivel
/// 
/// Quando usar:
/// - Tela de perfil do usuario
/// - Dashboard/home (widget resumido)
/// - Modal de conquistas
/// 
/// Exemplo de uso:
/// ```dart
/// UserTrackingDataStatsWidget(
///   viewModel: injector<UserTrackingDataViewModel>(),
///   userId: currentUserId,
///   showRankPosition: true,
/// )
/// ```
class UserTrackingDataStatsWidget extends StatefulWidget {
  final UserTrackingDataViewModel viewModel;
  final String userId;
  final bool showRankPosition;
  final bool showProgressBar;
  final EdgeInsetsGeometry? padding;

  const UserTrackingDataStatsWidget({
    super.key,
    required this.viewModel,
    required this.userId,
    this.showRankPosition = false,
    this.showProgressBar = true,
    this.padding,
  });

  @override
  State<UserTrackingDataStatsWidget> createState() =>
      _UserTrackingDataStatsWidgetState();
}

class _UserTrackingDataStatsWidgetState
    extends State<UserTrackingDataStatsWidget> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (widget.showRankPosition) {
      await widget.viewModel.loadComplete(widget.userId);
    } else {
      await widget.viewModel.loadUserStats(widget.userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, child) {
        // Loading state
        if (widget.viewModel.isLoading) {
          return _buildLoadingCard();
        }

        // Error state
        if (widget.viewModel.hasError) {
          return _buildErrorCard();
        }

        // No data state
        if (!widget.viewModel.hasData) {
          return _buildNoDataCard();
        }

        // Loaded state
        return _buildStatsCard();
      },
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      padding: widget.padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: CupertinoColors.systemGrey5,
          width: 1,
        ),
      ),
      child: const Center(
        child: CupertinoActivityIndicator(),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: widget.padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: CupertinoColors.systemRed,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            CupertinoIcons.exclamationmark_triangle,
            color: CupertinoColors.systemRed,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            widget.viewModel.errorMessage ?? 'Erro ao carregar dados',
            style: const TextStyle(
              color: CupertinoColors.systemRed,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: CupertinoColors.systemBlue,
            onPressed: _loadData,
            child: const Text('Tentar Novamente'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoDataCard() {
    return Container(
      padding: widget.padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: CupertinoColors.systemGrey5,
          width: 1,
        ),
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            CupertinoIcons.chart_bar,
            color: CupertinoColors.systemGrey,
            size: 32,
          ),
          SizedBox(height: 8),
          Text(
            'Nenhum dado de ranking disponivel',
            style: TextStyle(
              color: CupertinoColors.systemGrey,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    final stats = widget.viewModel.userStats!;

    return Container(
      padding: widget.padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: CupertinoColors.systemGrey5,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header: Titulo + Emoji do Nivel
          Row(
            children: [
              Text(
                widget.viewModel.levelEmoji ?? '🌱',
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Seu Ranking',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.label,
                      ),
                    ),
                    Text(
                      widget.viewModel.levelDisplayName ?? 'Iniciante',
                      style: const TextStyle(
                        fontSize: 14,
                        color: CupertinoColors.systemGrey,
                      ),
                    ),
                  ],
                ),
              ),
              // Score em destaque
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      CupertinoIcons.star_fill,
                      color: CupertinoColors.systemYellow,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${stats.totalScore}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: CupertinoColors.systemBlue,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Barra de progresso (se habilitado)
          if (widget.showProgressBar) ...[
            _buildProgressBar(),
            const SizedBox(height: 16),
          ],

          // Grid de estatisticas
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: CupertinoIcons.flame,
                  label: 'Streak',
                  value: '${stats.consecutiveDaysStreak}',
                  color: CupertinoColors.systemOrange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatItem(
                  icon: CupertinoIcons.calendar,
                  label: 'Dias Ativos',
                  value: '${stats.totalActiveDays}',
                  color: CupertinoColors.systemGreen,
                ),
              ),
            ],
          ),

          // Posicao no ranking (se habilitado)
          if (widget.showRankPosition &&
              widget.viewModel.userRankPosition != null) ...[
            const SizedBox(height: 12),
            _buildRankPosition(),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: CupertinoColors.systemGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    final progress = widget.viewModel.progressToNextLevel ?? 0.0;
    final pointsToNext = widget.viewModel.pointsToNextLevel ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Progresso para proximo nivel',
              style: TextStyle(
                fontSize: 12,
                color: CupertinoColors.systemGrey,
              ),
            ),
            Text(
              'Faltam $pointsToNext pts',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.systemBlue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Barra de progresso customizada (Cupertino-style)
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 8,
            child: Stack(
              children: [
                // Background da barra
                Container(
                  width: double.infinity,
                  color: CupertinoColors.systemGrey5,
                ),
                // Progresso preenchido
                FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(
                    color: CupertinoColors.systemBlue,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRankPosition() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CupertinoColors.systemPurple.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            CupertinoIcons.chart_bar_alt_fill,
            color: CupertinoColors.systemPurple,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            widget.viewModel.rankPositionText ?? 'Carregando...',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.systemPurple,
            ),
          ),
        ],
      ),
    );
  }
}
