import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:portugal_guide/features/user/user_repository_interface.dart';
import 'package:portugal_guide/features/user/user_details_model.dart';
import 'package:portugal_guide/features/user_tracking_data/user_tracking_data_service.dart';
import 'package:portugal_guide/util/error_messages.dart';

/// ViewModel para gerenciar detalhes do usuário
/// Segue o princípio de Inversão de Dependência (SOLID)
class UserDetailsViewModel extends ChangeNotifier {
  final UserRepositoryInterface _repository;
  final UserTrackingDataService _trackingService;
  final logger = Logger();

  UserDetailsViewModel({
    required UserRepositoryInterface repository,
    required UserTrackingDataService trackingService,
  })  : _repository = repository,
        _trackingService = trackingService;

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

      // Após carregar com sucesso, calcular e rastrear profile completion
      if (_userDetails != null) {
        try {
          await _trackingService.calculateAndTrackProfileCompletion(
            userId: userId,
            userDetails: _userDetails!,
          );
          if (kDebugMode) {
            print('✅ [UserDetailsViewModel] Profile completion tracking executado');
          }
        } catch (trackingErr) {
          // Tracking failure é non-blocking
          if (kDebugMode) {
            print('⚠️ [UserDetailsViewModel] Erro ao rastrear profile completion: $trackingErr');
          }
        }
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

  /// Define uma mensagem de erro e notifica os listeners
  void setError(String errorMessage) {
    error = errorMessage;
    _userDetails = null;
    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
