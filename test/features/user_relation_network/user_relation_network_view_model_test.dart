import 'package:flutter_test/flutter_test.dart';
import 'package:portugal_guide/features/main_contents/topic/ownership_repository_interface.dart';
import 'package:portugal_guide/features/user/user_details_model.dart';
import 'package:portugal_guide/features/user/user_repository_interface.dart';
import 'package:portugal_guide/features/user_relation_network/user_ranking_summary_model.dart';
import 'package:portugal_guide/features/user_relation_network/user_relation_network_view_model.dart';
import 'package:portugal_guide/features/user_relation_network/user_relation_ranking_repository_interface.dart';

class _FakeRankingRepository implements UserRelationRankingRepositoryInterface {
  _FakeRankingRepository(this.rankings, {this.error});

  final List<UserRankingSummaryModel> rankings;
  final Object? error;
  int? lastLimit;

  @override
  Future<List<UserRankingSummaryModel>> getTopRankings({int limit = 10}) async {
    lastLimit = limit;
    if (error != null) throw error!;
    return rankings;
  }
}

class _FakeUserRepository implements UserRepositoryInterface {
  _FakeUserRepository(this.detailsById);

  final Map<String, UserDetailsModel> detailsById;

  @override
  Future<UserDetailsModel> getUserDetails(String userId) async {
    final UserDetailsModel? details = detailsById[userId];
    if (details == null) throw Exception('404');
    return details;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeOwnershipRepository implements OwnershipRepositoryInterface {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

UserRankingSummaryModel _ranking(String userId, int score) => UserRankingSummaryModel(
      id: 'r-$userId',
      userId: userId,
      totalScore: score,
      engagementLevel: 'HIGH',
    );

UserDetailsModel _details(String id, String name, {bool active = true}) => UserDetailsModel(
      id: id,
      name: name,
      surname: 'Teste',
      email: '$id@example.com',
      role: 'USER',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      active: active,
      fullName: '$name Teste',
      phones: const [],
    );

void main() {
  UserRelationNetworkViewModel buildViewModel({
    required _FakeRankingRepository rankingRepository,
    Map<String, UserDetailsModel> details = const {},
    String? currentUserId = 'me',
  }) {
    final viewModel = UserRelationNetworkViewModel(
      userRepository: _FakeUserRepository(details),
      ownershipRepository: _FakeOwnershipRepository(),
      rankingRepository: rankingRepository,
      currentUserIdProvider: () => currentUserId,
    );
    addTearDown(viewModel.dispose);
    return viewModel;
  }

  test('loadSuggestions mantém a ordem do leaderboard e deriva a posição', () async {
    final rankingRepository = _FakeRankingRepository([
      _ranking('u1', 300),
      _ranking('me', 200),
      _ranking('u2', 100),
      _ranking('u3', 50),
    ]);
    final viewModel = buildViewModel(
      rankingRepository: rankingRepository,
      details: {
        'u1': _details('u1', 'Ana'),
        'me': _details('me', 'Eu'),
        'u2': _details('u2', 'Bia', active: false),
        // u3 sem detalhes (404) é descartado
      },
    );

    await viewModel.loadSuggestions();

    expect(rankingRepository.lastLimit, 21);
    expect(viewModel.suggestionsError, isNull);
    expect(viewModel.isLoadingSuggestions, isFalse);
    expect(viewModel.filteredSuggestions.map((s) => s.userId), ['u1']);
    expect(viewModel.filteredSuggestions.single.rankPosition, 1);
    expect(viewModel.filteredSuggestions.single.fullName, 'Ana Teste');
  });

  test('loadSuggestions expõe erro quando o ranking falha', () async {
    final viewModel = buildViewModel(
      rankingRepository: _FakeRankingRepository(const [], error: Exception('500')),
    );

    await viewModel.loadSuggestions();

    expect(viewModel.suggestionsError, isNotNull);
    expect(viewModel.filteredSuggestions, isEmpty);
  });

  test('filteredSuggestions respeita a busca', () async {
    final viewModel = buildViewModel(
      rankingRepository: _FakeRankingRepository([
        _ranking('u1', 300),
        _ranking('u2', 100),
      ]),
      details: {
        'u1': _details('u1', 'Ana'),
        'u2': _details('u2', 'Bruno'),
      },
    );

    await viewModel.loadSuggestions();
    viewModel.setSearchQuery('bru');

    expect(viewModel.filteredSuggestions.map((s) => s.userId), ['u2']);
    expect(viewModel.filteredSuggestions.single.rankPosition, 2);
  });
}
