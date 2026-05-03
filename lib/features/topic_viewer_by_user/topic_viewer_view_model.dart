import 'package:flutter/cupertino.dart';
import 'package:portugal_guide/app/core/config/injector.dart';
import 'package:portugal_guide/features/user/user_details_model.dart';
import 'package:portugal_guide/features/user/user_repository_interface.dart';

class TopicViewerViewModel extends ChangeNotifier {
  final UserRepositoryInterface _userRepository;

  TopicViewerViewModel({
    UserRepositoryInterface? userRepository,
  }) : _userRepository = userRepository ?? injector<UserRepositoryInterface>();

  UserDetailsModel? _userDetails;
  bool _isLoadingUserDetails = false;

  UserDetailsModel? get userDetails => _userDetails;
  bool get isLoadingUserDetails => _isLoadingUserDetails;

  bool get isContentCreator {
    if (_userDetails == null) return false;

    final hasYoutubeUserId = _userDetails!.youtubeUserId != null &&
        _userDetails!.youtubeUserId!.isNotEmpty;
    final hasYoutubeChannelId = _userDetails!.youtubeChannelId != null &&
        _userDetails!.youtubeChannelId!.isNotEmpty;

    return hasYoutubeUserId && hasYoutubeChannelId;
  }

  String get dinamicTitle =>
      isContentCreator ? 'Meus Vídeos - Criados' : 'Conteúdo que Já Assisti';

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
}