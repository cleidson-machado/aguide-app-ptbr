import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:portugal_guide/app/core/config/injector.dart';
import 'package:portugal_guide/app/core/auth/auth_token_manager.dart';
import 'package:portugal_guide/features/user_tracking_data/points_history_model.dart';
import 'package:portugal_guide/features/user_tracking_data/user_tracking_data_service.dart';
import 'package:intl/intl.dart';

/// Tela de histórico de pontos do usuário (auditoria de gamificação)
/// 
/// Exibe timeline de todas as adições de pontos com:
/// - Data/hora
/// - Quantidade de pontos
/// - Motivo (login, bônus, interação, etc.)
/// - Ícone visual baseado no tipo
/// 
/// Referência: .local_knowledge/FRONTEND_INTEGRATION_USER_RANKING_SECURITY.md
class UserPointsHistoryScreen extends StatefulWidget {
  const UserPointsHistoryScreen({super.key});

  @override
  State<UserPointsHistoryScreen> createState() =>
      _UserPointsHistoryScreenState();
}

class _UserPointsHistoryScreenState extends State<UserPointsHistoryScreen> {
  final UserTrackingDataService _trackingService =
      injector<UserTrackingDataService>();
  final AuthTokenManager _authTokenManager = injector<AuthTokenManager>();

  List<PointsHistoryModel> _history = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _currentLimit = 10; // Quantidade de registros carregados

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  /// Carrega histórico de pontos do usuário logado
  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userId = _authTokenManager.getUserId();

      if (userId == null) {
        setState(() {
          _errorMessage = 'Usuário não autenticado';
          _isLoading = false;
        });
        return;
      }

      if (kDebugMode) {
        print('📜 [UserPointsHistoryScreen] Carregando histórico');
        print('   - userId: $userId');
        print('   - limit: $_currentLimit');
      }

      final history = await _trackingService.getPointsHistory(
        userId,
        limit: _currentLimit,
      );

      setState(() {
        _history = history;
        _isLoading = false;
      });

      if (kDebugMode) {
        print('✅ [UserPointsHistoryScreen] ${history.length} registros carregados');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [UserPointsHistoryScreen] Erro ao carregar histórico: $e');
      }

      setState(() {
        _errorMessage = 'Erro ao carregar histórico';
        _isLoading = false;
      });
    }
  }

  /// Carrega mais registros (paginação)
  Future<void> _loadMore() async {
    if (_currentLimit >= 100) {
      // Backend limita em 100 registros
      if (kDebugMode) {
        print('⚠️  [UserPointsHistoryScreen] Limite máximo atingido (100)');
      }
      return;
    }

    setState(() {
      _currentLimit += 10;
    });

    await _loadHistory();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        leading: CupertinoNavigationBarBackButton(
          onPressed: () => Navigator.of(context).pop(),
        ),
        middle: const Text('Histórico de Pontos'),
      ),
      child: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _history.isEmpty) {
      return const Center(
        child: CupertinoActivityIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                CupertinoIcons.exclamationmark_triangle,
                size: 64,
                color: CupertinoColors.systemRed,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              CupertinoButton(
                onPressed: _loadHistory,
                child: const Text('Tentar Novamente'),
              ),
            ],
          ),
        ),
      );
    }

    if (_history.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                CupertinoIcons.chart_bar,
                size: 64,
                color: CupertinoColors.systemGrey,
              ),
              SizedBox(height: 16),
              Text(
                'Nenhum registro de pontos ainda',
                style: TextStyle(
                  fontSize: 16,
                  color: CupertinoColors.systemGrey,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                'Continue interagindo com o app para ganhar pontos!',
                style: TextStyle(
                  fontSize: 14,
                  color: CupertinoColors.systemGrey2,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        CupertinoSliverRefreshControl(
          onRefresh: () async {
            setState(() {
              _currentLimit = 10;
            });
            await _loadHistory();
          },
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index == _history.length) {
                  // Botão "Carregar mais" no final da lista
                  return _buildLoadMoreButton();
                }

                final entry = _history[index];
                return _buildHistoryCard(entry);
              },
              childCount: _history.length + 1, // +1 para botão "Carregar mais"
            ),
          ),
        ),
      ],
    );
  }

  /// Card individual de histórico
  Widget _buildHistoryCard(PointsHistoryModel entry) {
    final dateFormatter = DateFormat('dd/MM/yyyy HH:mm');
    final formattedDate = dateFormatter.format(entry.date.toLocal());

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: CupertinoColors.systemGrey5,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Ícone do motivo
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _getReasonColor(entry.reason).withOpacity(0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Center(
              child: Text(
                entry.getReasonIcon(),
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Descrição e data
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.getReasonDescription(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formattedDate,
                  style: const TextStyle(
                    fontSize: 14,
                    color: CupertinoColors.systemGrey,
                  ),
                ),
              ],
            ),
          ),

          // Pontos
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: CupertinoColors.systemGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '+${entry.points}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: CupertinoColors.systemGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Botão "Carregar mais" no final da lista
  Widget _buildLoadMoreButton() {
    if (_currentLimit >= 100) {
      // Limite máximo atingido
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Text(
            'Todos os registros carregados',
            style: TextStyle(
              fontSize: 14,
              color: CupertinoColors.systemGrey,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: CupertinoButton(
          onPressed: _isLoading ? null : _loadMore,
          child: _isLoading
              ? const CupertinoActivityIndicator()
              : const Text('Carregar Mais'),
        ),
      ),
    );
  }

  /// Retorna cor baseada no tipo de motivo
  Color _getReasonColor(String reason) {
    switch (reason) {
      case 'daily_login':
        return CupertinoColors.systemBlue;
      case '7day_bonus':
        return CupertinoColors.systemOrange;
      case '30day_bonus':
        return CupertinoColors.systemPurple;
      case 'content_interaction':
        return CupertinoColors.systemGreen;
      case 'message_sent':
        return CupertinoColors.systemTeal;
      default:
        return CupertinoColors.systemGrey;
    }
  }
}
