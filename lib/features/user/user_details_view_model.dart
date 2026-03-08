import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:portugal_guide/features/user/user_repository_interface.dart';
import 'package:portugal_guide/features/user/user_details_model.dart';
import 'package:portugal_guide/util/error_messages.dart';

/// ViewModel para gerenciar detalhes do usuário
/// Segue o princípio de Inversão de Dependência (SOLID)
class UserDetailsViewModel extends ChangeNotifier {
  final UserRepositoryInterface _repository;
  final logger = Logger();

  UserDetailsViewModel({required UserRepositoryInterface repository})
      : _repository = repository;

  UserDetailsModel? _userDetails;
  String? error;
  bool _isLoading = false;

  UserDetailsModel? get userDetails => _userDetails;
  bool get isLoading => _isLoading;
  bool get hasData => _userDetails != null;

  void _logError(String action, Object err, StackTrace stackTrace) {
    final className = runtimeType.toString();
    logger.e(
      '$className - ERROR: "$action"',
      error: err,
      stackTrace: stackTrace,
    );
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Carrega os detalhes do usuário
  Future<void> loadUserDetails(String userId) async {
    _setLoading(true);
    try {
      error = null;
      _userDetails = await _repository.getUserDetails(userId);
      
      if (kDebugMode) {
        print('✅ [UserDetailsViewModel] Detalhes carregados: ${_userDetails?.fullName}');
      }
    } catch (err, stackTrace) {
      _logError('loadUserDetails METHOD', err, stackTrace);
      error = ErrorMessages.defaultMsnFailedToLoadData;
      _userDetails = null;
    } finally {
      _setLoading(false);
    }
  }

  /// Limpa os dados do usuário
  void clearUserDetails() {
    _userDetails = null;
    error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
