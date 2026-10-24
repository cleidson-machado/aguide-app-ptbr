import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:portugal_guide/features/user_verified_content/user_verified_content_model.dart';
import 'package:portugal_guide/features/user_verified_content/user_verified_content_repository_interface.dart';
import 'package:portugal_guide/util/error_messages.dart';

/// ViewModel para gerenciamento de estado do wizard de verificação de conteúdo
/// Segue o princípio de Inversão de Dependência (SOLID)
class UserVerifiedContentViewModel extends ChangeNotifier {
  final UserVerifiedContentRepositoryInterface _repository;
  final logger = Logger();

  UserVerifiedContentViewModel({
    required this._repository,
  });

  // Estado do wizard
  int _currentStep = 0;
  bool _isLoading = false;
  String? _error;
  bool _isSubmitted = false;

  // Dados do formulário - Etapa 1
  String _contentTitle = '';
  String _contentUrl = '';
  String _contentType = 'video';

  // Dados do formulário - Etapa 2
  String _proofType = 'youtube_channel';
  String _proofValue = '';

  // Dados do formulário - Etapa 3
  String _description = '';
  String _contactEmail = '';

  // Getters
  int get currentStep => _currentStep;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isSubmitted => _isSubmitted;
  int get totalSteps => 3;
  bool get canGoNext => _validateCurrentStep();
  bool get isFirstStep => _currentStep == 0;
  bool get isLastStep => _currentStep == totalSteps - 1;

  // Getters dos campos do formulário
  String get contentTitle => _contentTitle;
  String get contentUrl => _contentUrl;
  String get contentType => _contentType;
  String get proofType => _proofType;
  String get proofValue => _proofValue;
  String get description => _description;
  String get contactEmail => _contactEmail;

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

  void _setError(String? value) {
    _error = value;
    notifyListeners();
  }

  /// Atualiza campos da Etapa 1
  void updateContentInfo({String? title, String? url, String? type}) {
    if (title != null) _contentTitle = title;
    if (url != null) _contentUrl = url;
    if (type != null) _contentType = type;
    notifyListeners();
  }

  /// Atualiza campos da Etapa 2
  void updateProofInfo({String? type, String? value}) {
    if (type != null) _proofType = type;
    if (value != null) _proofValue = value;
    notifyListeners();
  }

  /// Atualiza campos da Etapa 3
  void updateAdditionalInfo({String? description, String? email}) {
    if (description != null) _description = description;
    if (email != null) _contactEmail = email;
    notifyListeners();
  }

  /// Valida a etapa atual
  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0: // Etapa 1: Informações do Conteúdo
        return _contentTitle.trim().isNotEmpty &&
            _contentUrl.trim().isNotEmpty &&
            _contentType.isNotEmpty;
      case 1: // Etapa 2: Prova de Propriedade
        return _proofType.isNotEmpty && _proofValue.trim().isNotEmpty;
      case 2: // Etapa 3: Informações Adicionais
        return _description.trim().isNotEmpty &&
            _contactEmail.trim().isNotEmpty;
      default:
        return false;
    }
  }

  /// Avança para próxima etapa
  void nextStep() {
    if (!canGoNext) {
      _setError('Por favor, preencha todos os campos obrigatórios');
      return;
    }

    if (_currentStep < totalSteps - 1) {
      _currentStep++;
      _setError(null);
      notifyListeners();

      if (kDebugMode) {
        debugPrint(
          '📋 [UserVerifiedContentViewModel] Avançou para etapa $_currentStep',
        );
      }
    }
  }

  /// Volta para etapa anterior
  void previousStep() {
    if (_currentStep > 0) {
      _currentStep--;
      _setError(null);
      notifyListeners();

      if (kDebugMode) {
        debugPrint(
          '📋 [UserVerifiedContentViewModel] Voltou para etapa $_currentStep',
        );
      }
    }
  }

  /// Reseta o wizard para o estado inicial
  void resetWizard() {
    _currentStep = 0;
    _isLoading = false;
    _error = null;
    _isSubmitted = false;
    _contentTitle = '';
    _contentUrl = '';
    _contentType = 'video';
    _proofType = 'youtube_channel';
    _proofValue = '';
    _description = '';
    _contactEmail = '';
    notifyListeners();

    if (kDebugMode) {
      debugPrint('🔄 [UserVerifiedContentViewModel] Wizard resetado');
    }
  }

  /// Submete a solicitação de verificação
  Future<bool> submitRequest() async {
    if (!_validateCurrentStep()) {
      _setError('Por favor, preencha todos os campos obrigatórios');
      return false;
    }

    _setLoading(true);
    _setError(null);

    try {
      // Verifica se já existe solicitação para esta URL
      final hasExisting = await _repository.hasExistingRequestForUrl(
        _contentUrl,
      );
      if (hasExisting) {
        _setError('Já existe uma solicitação para este conteúdo');
        _setLoading(false);
        return false;
      }

      // Cria modelo de dados
      final request = UserVerifiedContentModel(
        id: '', // Será gerado pelo repository
        contentTitle: _contentTitle,
        contentUrl: _contentUrl,
        contentType: _contentType,
        proofType: _proofType,
        proofValue: _proofValue,
        description: _description,
        contactEmail: _contactEmail,
        createdAt: DateTime.now(),
      );

      // Submete ao repository
      final result = await _repository.submitVerificationRequest(request);

      _isSubmitted = true;
      _setLoading(false);

      if (kDebugMode) {
        debugPrint(
          '✅ [UserVerifiedContentViewModel] Solicitação enviada: ${result.id}',
        );
      }

      return true;
    } catch (err, stackTrace) {
      _logError('submitRequest METHOD', err, stackTrace);
      _setError(ErrorMessages.defaultMsnFailedToSaveData);
      _setLoading(false);
      return false;
    }
  }

  @override
  void dispose() {
    if (kDebugMode) {
      debugPrint('🗑️ [UserVerifiedContentViewModel] Disposing...');
    }
    super.dispose();
  }
}
