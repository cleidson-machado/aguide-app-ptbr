import 'package:flutter/foundation.dart';
import 'package:portugal_guide/app/core/config/injector.dart';
import 'package:portugal_guide/features/user/user_details_model.dart';
import 'package:portugal_guide/features/user/user_repository_interface.dart';
import 'package:portugal_guide/features/main_contents/topic/ownership_repository_interface.dart';
import 'package:portugal_guide/features/main_contents/topic/ownership_model.dart';
import 'package:portugal_guide/features/main_contents/topic/main_content_topic_view_model.dart';
import 'package:portugal_guide/features/main_contents/topic/main_content_topic_model.dart';

class TopicViewerViewModel extends ChangeNotifier {
  final UserRepositoryInterface _userRepository;
  final OwnershipRepositoryInterface _ownershipRepository;
  final MainContentTopicViewModel _contentViewModel;

  TopicViewerViewModel({
    UserRepositoryInterface? userRepository,
    OwnershipRepositoryInterface? ownershipRepository,
    MainContentTopicViewModel? contentViewModel,
  })  : _userRepository = userRepository ?? injector<UserRepositoryInterface>(),
        _ownershipRepository = ownershipRepository ?? injector<OwnershipRepositoryInterface>(),
        _contentViewModel = contentViewModel ?? injector<MainContentTopicViewModel>();

  UserDetailsModel? _userDetails;
  bool _isLoadingUserDetails = false;

  List<OwnershipContentModel> _ownershipContents = [];
  bool _isLoadingOwnership = false;
  String? _ownershipError;

  final Map<String, MainContentTopicModel> _enrichedContents = {};
  bool _isEnrichingMetrics = false;

  UserDetailsModel? get userDetails => _userDetails;
  bool get isLoadingUserDetails => _isLoadingUserDetails;

  List<OwnershipContentModel> get ownershipContents => _ownershipContents;
  bool get isLoadingOwnership => _isLoadingOwnership;
  String? get ownershipError => _ownershipError;
  bool get hasOwnershipContents => _ownershipContents.isNotEmpty;

  Map<String, MainContentTopicModel> get enrichedContents => _enrichedContents;
  bool get isEnrichingMetrics => _isEnrichingMetrics;

  MainContentTopicModel? getEnrichedContent(String contentId) {
    return _enrichedContents[contentId];
  }

  bool get isContentCreator {
    if (_userDetails == null) return false;

    final hasYoutubeUserId = _userDetails!.youtubeUserId != null &&
        _userDetails!.youtubeUserId!.isNotEmpty;
    final hasYoutubeChannelId = _userDetails!.youtubeChannelId != null &&
        _userDetails!.youtubeChannelId!.isNotEmpty;

    return hasYoutubeUserId && hasYoutubeChannelId;
  }

  String get dinamicTitle {
    return isContentCreator
        ? 'Meus Vídeos - Criados'
        : 'Conteúdo que Já Assisti';
  }

  Future<void> loadUserDetails(String userId) async {
    _isLoadingUserDetails = true;
    notifyListeners();

    try {
      _userDetails = await _userRepository.getUserDetails(userId);
    } catch (e) {
      _userDetails = null;
    } finally {
      _isLoadingUserDetails = false;
      notifyListeners();
    }
  }

  Future<void> loadOwnershipContents(String userId) async {
    _isLoadingOwnership = true;
    _ownershipError = null;
    notifyListeners();

    try {
      final result = await _ownershipRepository.getUserVerifiedContents(
        userId: userId,
      );

      if (result.isOwner && result.contents != null) {
        _ownershipContents = result.contents!;
        await _enrichContentsWithMetrics();
      } else {
        _ownershipContents = [];
      }
    } catch (e) {
      _ownershipContents = [];
      _ownershipError = 'Erro ao carregar conteúdos verificados';
    } finally {
      _isLoadingOwnership = false;
      notifyListeners();
    }
  }

  void sortByTitleAscending() {
    if (_ownershipContents.isEmpty) return;
    _ownershipContents.sort((a, b) => 
      a.title.toLowerCase().compareTo(b.title.toLowerCase())
    );
    notifyListeners();
  }

  void sortByTitleDescending() {
    if (_ownershipContents.isEmpty) return;
    _ownershipContents.sort((a, b) => 
      b.title.toLowerCase().compareTo(a.title.toLowerCase())
    );
    notifyListeners();
  }

  void sortByNewestPublished() {
    if (_ownershipContents.isEmpty) return;
    _ownershipContents.sort((a, b) {
      final dateA = DateTime.tryParse(a.publishedAt) ?? DateTime(1970);
      final dateB = DateTime.tryParse(b.publishedAt) ?? DateTime(1970);
      return dateB.compareTo(dateA);
    });
    notifyListeners();
  }

  void sortByOldestPublished() {
    if (_ownershipContents.isEmpty) return;
    _ownershipContents.sort((a, b) {
      final dateA = DateTime.tryParse(a.publishedAt) ?? DateTime(1970);
      final dateB = DateTime.tryParse(b.publishedAt) ?? DateTime(1970);
      return dateA.compareTo(dateB);
    });
    notifyListeners();
  }

  void sortByChannelNameAscending() {
    if (_ownershipContents.isEmpty) return;
    _ownershipContents.sort((a, b) => 
      a.channelName.toLowerCase().compareTo(b.channelName.toLowerCase())
    );
    notifyListeners();
  }

  void sortByRecentlyAdded() {
    if (_ownershipContents.isEmpty) return;
    _ownershipContents.sort((a, b) {
      final dateA = DateTime.tryParse(a.verifiedAt) ?? DateTime(1970);
      final dateB = DateTime.tryParse(b.verifiedAt) ?? DateTime(1970);
      return dateB.compareTo(dateA);
    });
    notifyListeners();
  }

  void shuffleContents() {
    if (_ownershipContents.isEmpty) return;
    _ownershipContents.shuffle();
    notifyListeners();
  }

  Future<void> _enrichContentsWithMetrics() async {
    if (_ownershipContents.isEmpty) return;

    _isEnrichingMetrics = true;
    notifyListeners();

    if (_contentViewModel.contents.isEmpty) {
      try {
        await _contentViewModel.loadPagedContents();
      } catch (e) {
        _isEnrichingMetrics = false;
        notifyListeners();
        return;
      }
    }

    final Map<String, MainContentTopicModel> contentCache = {
      for (var content in _contentViewModel.contents) content.id: content,
    };

    for (final ownershipContent in _ownershipContents) {
      try {
        final fullContent = contentCache[ownershipContent.contentId];
        if (fullContent != null) {
          _enrichedContents[ownershipContent.contentId] = fullContent;
        }
      } catch (e) {
        continue;
      }
    }

    _isEnrichingMetrics = false;
    notifyListeners();
  }
}