import 'package:flutter_test/flutter_test.dart';
import 'package:portugal_guide/features/main_contents/topic/ownership_repository_interface.dart';
import 'package:portugal_guide/features/user/user_details_model.dart';
import 'package:portugal_guide/features/user/user_repository_interface.dart';
import 'package:portugal_guide/features/user_relation_network/featured_content_models.dart';
import 'package:portugal_guide/features/user_relation_network/featured_theme_data.dart';
import 'package:portugal_guide/features/user_relation_network/user_ranking_summary_model.dart';
import 'package:portugal_guide/features/user_relation_network/user_relation_featured_content_repository_interface.dart';
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

class _FakeFeaturedContentRepository
    implements UserRelationFeaturedContentRepositoryInterface {
  _FakeFeaturedContentRepository({
    this.catalog = const [],
    this.topContents = const [],
    this.recordsById = const {},
    this.catalogError,
    this.topContentsError,
  });

  final List<FeaturedContentRecord> catalog;
  final List<UserTopContent> topContents;
  final Map<String, FeaturedContentRecord> recordsById;
  final Object? catalogError;
  final Object? topContentsError;
  final List<String> requestedIds = [];
  String? lastTopContentsUserId;

  @override
  Future<List<FeaturedContentRecord>> getLatestContents({int size = 30}) async {
    if (catalogError != null) throw catalogError!;
    return catalog;
  }

  @override
  Future<List<UserTopContent>> getUserTopContents({
    required String userId,
    int limit = 12,
  }) async {
    lastTopContentsUserId = userId;
    if (topContentsError != null) throw topContentsError!;
    return topContents;
  }

  @override
  Future<FeaturedContentRecord> getContentById(String contentId) async {
    requestedIds.add(contentId);
    final FeaturedContentRecord? record = recordsById[contentId];
    if (record == null) throw Exception('404');
    return record;
  }
}

FeaturedContentRecord _record(
  String id, {
  String categoryId = '',
  String categoryName = '',
  int viewCount = 0,
}) => FeaturedContentRecord(
  id: id,
  title: 'Título $id',
  videoThumbnailUrl: 'https://img.example.com/$id.jpg',
  channelName: 'Canal $id',
  categoryId: categoryId,
  categoryName: categoryName,
  viewCount: viewCount,
);

UserTopContent _top(String contentId) => UserTopContent(
  contentId: contentId,
  contentTitle: 'Top $contentId',
  thumbnailUrl: 'https://img.example.com/top-$contentId.jpg',
  totalInteractions: 5,
);

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

UserRankingSummaryModel _ranking(String userId, int score) =>
    UserRankingSummaryModel(
      id: 'r-$userId',
      userId: userId,
      totalScore: score,
      engagementLevel: 'HIGH',
    );

UserDetailsModel _details(String id, String name, {bool active = true}) =>
    UserDetailsModel(
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
    _FakeRankingRepository? rankingRepository,
    _FakeFeaturedContentRepository? featuredContentRepository,
    Map<String, UserDetailsModel> details = const {},
    String? currentUserId = 'me',
  }) {
    final viewModel = UserRelationNetworkViewModel(
      userRepository: _FakeUserRepository(details),
      ownershipRepository: _FakeOwnershipRepository(),
      rankingRepository: rankingRepository ?? _FakeRankingRepository(const []),
      featuredContentRepository:
          featuredContentRepository ?? _FakeFeaturedContentRepository(),
      currentUserIdProvider: () => currentUserId,
    );
    addTearDown(viewModel.dispose);
    return viewModel;
  }

  test(
    'loadSuggestions mantém a ordem do leaderboard e deriva a posição',
    () async {
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
    },
  );

  test('loadSuggestions expõe erro quando o ranking falha', () async {
    final viewModel = buildViewModel(
      rankingRepository: _FakeRankingRepository(
        const [],
        error: Exception('500'),
      ),
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
      details: {'u1': _details('u1', 'Ana'), 'u2': _details('u2', 'Bruno')},
    );

    await viewModel.loadSuggestions();
    viewModel.setSearchQuery('bru');

    expect(viewModel.filteredSuggestions.map((s) => s.userId), ['u2']);
    expect(viewModel.filteredSuggestions.single.rankPosition, 2);
  });

  group('loadFeaturedThemes', () {
    test('agrupa o catálogo por categoria usando o item mais visto', () async {
      final viewModel = buildViewModel(
        featuredContentRepository: _FakeFeaturedContentRepository(
          catalog: [
            _record(
              'c1',
              categoryId: '28',
              categoryName: 'Science & Technology',
              viewCount: 10,
            ),
            _record(
              'c2',
              categoryId: '22',
              categoryName: 'People & Blogs',
              viewCount: 5,
            ),
            _record(
              'c3',
              categoryId: '28',
              categoryName: 'Science & Technology',
              viewCount: 99,
            ),
            _record('c4', viewCount: 1),
          ],
        ),
      );

      await viewModel.loadFeaturedThemes();

      final themes = viewModel.filteredFeaturedThemes;
      expect(viewModel.featuredThemesError, isNull);
      expect(viewModel.isLoadingFeaturedThemes, isFalse);
      expect(themes.map((t) => t.contentId), ['c3', 'c2', 'c4']);
      expect(themes.map((t) => t.label), [
        'Science & Technology',
        'People & Blogs',
        'Canal c4',
      ]);
      expect(
        themes.every((t) => t.source == FeaturedThemeSource.catalog),
        isTrue,
      );
    });

    test(
      'prioriza top-contents do usuário e resolve categoria fora do catálogo',
      () async {
        final repository = _FakeFeaturedContentRepository(
          catalog: [
            _record(
              'c1',
              categoryId: '28',
              categoryName: 'Tech',
              viewCount: 10,
            ),
            _record(
              'c2',
              categoryId: '10',
              categoryName: 'Music',
              viewCount: 5,
            ),
          ],
          topContents: [_top('x9'), _top('c2'), _top('gone')],
          recordsById: {
            'x9': _record('x9', categoryId: '28', categoryName: 'Tech'),
          },
        );
        final viewModel = buildViewModel(featuredContentRepository: repository);

        await viewModel.loadFeaturedThemes();

        final themes = viewModel.filteredFeaturedThemes;
        expect(repository.lastTopContentsUserId, 'me');
        expect(repository.requestedIds, unorderedEquals(['x9', 'gone']));
        expect(themes.map((t) => t.contentId), ['x9', 'c2']);
        expect(themes.first.imageUrl, 'https://img.example.com/top-x9.jpg');
        expect(
          themes.every((t) => t.source == FeaturedThemeSource.personalized),
          isTrue,
        );
      },
    );

    test('usa só o catálogo quando top-contents falha', () async {
      final viewModel = buildViewModel(
        featuredContentRepository: _FakeFeaturedContentRepository(
          catalog: [_record('c1', categoryId: '28', categoryName: 'Tech')],
          topContentsError: Exception('401'),
        ),
      );

      await viewModel.loadFeaturedThemes();

      expect(viewModel.featuredThemesError, isNull);
      expect(viewModel.filteredFeaturedThemes.single.contentId, 'c1');
    });

    test('expõe erro quando o catálogo falha', () async {
      final viewModel = buildViewModel(
        featuredContentRepository: _FakeFeaturedContentRepository(
          catalogError: Exception('500'),
        ),
      );

      await viewModel.loadFeaturedThemes();

      expect(viewModel.featuredThemesError, isNotNull);
      expect(viewModel.filteredFeaturedThemes, isEmpty);
    });

    test('limita a 12 temas e filtra pela busca', () async {
      final viewModel = buildViewModel(
        featuredContentRepository: _FakeFeaturedContentRepository(
          catalog: [
            for (int i = 0; i < 15; i++)
              _record('c$i', categoryId: '$i', categoryName: 'Tema $i'),
          ],
        ),
      );

      await viewModel.loadFeaturedThemes();
      expect(viewModel.filteredFeaturedThemes, hasLength(12));

      viewModel.setSearchQuery('tema 1');
      expect(viewModel.filteredFeaturedThemes.map((t) => t.label), [
        'Tema 1',
        'Tema 10',
        'Tema 11',
      ]);
    });
  });
}
