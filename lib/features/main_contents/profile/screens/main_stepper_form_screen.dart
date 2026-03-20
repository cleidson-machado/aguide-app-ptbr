// ignore_for_file: avoid_print, use_build_context_synchronously

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:portugal_guide/app/core/auth/auth_token_manager.dart';
import 'package:portugal_guide/app/core/config/injector.dart';
import 'package:portugal_guide/features/home_content/screens/home_content_tab_screen.dart';
import 'package:portugal_guide/features/user_choice/user_choice_model.dart';
import 'package:portugal_guide/features/user_choice/user_choice_view_model.dart';

/// Tela de formulário stepper com 10 perguntas CREATOR
/// Integração completa com API REST /api/v1/user-choices
class MainStepperFormScreen extends StatefulWidget {
  const MainStepperFormScreen({super.key});

  @override
  State<MainStepperFormScreen> createState() => _MainStepperFormScreenState();
}

class _MainStepperFormScreenState extends State<MainStepperFormScreen> {
  // ViewModels e Services
  late final UserChoiceViewModel _viewModel;
  late final AuthTokenManager _authManager;

  int _currentStep = 0;
  final int _totalSteps = 10;

  // Controllers para campos de texto (5 campos)
  final TextEditingController _channelNameController = TextEditingController();
  final TextEditingController _channelHandleController = TextEditingController();
  final TextEditingController _mainNicheController = TextEditingController();
  final TextEditingController _offeredServiceController = TextEditingController();
  final TextEditingController _contentDifferentialController = TextEditingController();

  // Variáveis para seleções enum
  String? _selectedChannelAgeRange;
  String? _selectedSubscriberRange;
  String? _selectedMonetizationStatus;
  List<String> _selectedContentFormats = [];
  String? _selectedCommercialIntent;
  String? _selectedPublishingFrequency;

  // Controle de perfil existente
  String? _existingProfileId;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    _viewModel = injector<UserChoiceViewModel>();
    _authManager = injector<AuthTokenManager>();
    _checkExistingProfile();
  }

  /// Verifica se usuário já possui perfil existente
  Future<void> _checkExistingProfile() async {
    final userId = _authManager.getUserId();
    if (userId == null) {
      if (kDebugMode) print('⚠️ [MainStepperForm] Usuário não autenticado');
      return;
    }

    await _viewModel.fetchUserActiveProfile(userId);

    if (_viewModel.userChoice != null) {
      _populateFormWithData(_viewModel.userChoice!);
    }
  }

  /// Preenche formulário com dados existentes (modo edição)
  void _populateFormWithData(UserChoiceModel model) {
    if (kDebugMode) print('📝 [MainStepperForm] Preenchendo formulário com perfil existente');
    
    setState(() {
      _existingProfileId = model.id;
      _isEditMode = true;

      // Campos de texto
      _channelNameController.text = model.channelName ?? '';
      _channelHandleController.text = model.channelHandle ?? '';
      _mainNicheController.text = model.mainNiche ?? '';
      _offeredServiceController.text = model.offeredService ?? '';
      _contentDifferentialController.text = model.contentDifferential ?? '';

      // Enums
      _selectedChannelAgeRange = model.channelAgeRange;
      _selectedSubscriberRange = model.subscriberRange;
      _selectedMonetizationStatus = model.monetizationStatus;
      _selectedContentFormats = model.contentFormats ?? [];
      _selectedCommercialIntent = model.commercialIntent;
      _selectedPublishingFrequency = model.publishingFrequency;
    });
  }

  @override
  void dispose() {
    _channelNameController.dispose();
    _channelHandleController.dispose();
    _mainNicheController.dispose();
    _offeredServiceController.dispose();
    _contentDifferentialController.dispose();
    super.dispose();
  }

  /// Avança para próxima etapa com validação
  void _handleNext() {
    // Validar campos obrigatórios da etapa atual
    final errorMessage = _validateCurrentStep();
    if (errorMessage != null) {
      _showError(errorMessage);
      return;
    }

    if (_currentStep < _totalSteps - 1) {
      setState(() {
        _currentStep++;
      });
    } else {
      // Última etapa - validar tudo e confirmar
      final allFieldsError = _validateAllSteps();
      if (allFieldsError != null) {
        _showError(allFieldsError);
        return;
      }
      _handleConfirm();
    }
  }

  /// Valida campos obrigatórios da etapa atual
  String? _validateCurrentStep() {
    switch (_currentStep) {
      case 0: // Nome do canal + Handle
        if (_channelNameController.text.trim().isEmpty) {
          return 'Por favor, insira o nome do seu canal';
        }
        if (_channelHandleController.text.trim().isEmpty) {
          return 'Por favor, insira o @handle ou link do canal';
        }
        break;
      case 1: // Tempo de atividade
        if (_selectedChannelAgeRange == null) {
          return 'Por favor, selecione há quanto tempo publica';
        }
        break;
      case 2: // Inscritos
        if (_selectedSubscriberRange == null) {
          return 'Por favor, selecione a faixa de inscritos';
        }
        break;
      case 3: // Monetização
        if (_selectedMonetizationStatus == null) {
          return 'Por favor, selecione o status de monetização';
        }
        break;
      case 4: // Nicho
        if (_mainNicheController.text.trim().isEmpty) {
          return 'Por favor, descreva o tema central do seu conteúdo';
        }
        break;
      case 5: // Formatos (multi-select)
        if (_selectedContentFormats.isEmpty) {
          return 'Por favor, selecione pelo menos um formato de conteúdo';
        }
        break;
      case 6: // Intenção comercial
        if (_selectedCommercialIntent == null) {
          return 'Por favor, selecione sua intenção ao divulgar o canal';
        }
        break;
      case 7: // Serviço oferecido (OPCIONAL)
        break;
      case 8: // Frequência de publicação
        if (_selectedPublishingFrequency == null) {
          return 'Por favor, selecione a frequência de publicação';
        }
        break;
      case 9: // Diferenciais (OPCIONAL)
        break;
    }
    return null;
  }

  /// Valida todos os campos obrigatórios
  String? _validateAllSteps() {
    if (_channelNameController.text.trim().isEmpty) return 'Nome do canal é obrigatório';
    if (_channelHandleController.text.trim().isEmpty) return '@handle é obrigatório';
    if (_selectedChannelAgeRange == null) return 'Tempo de atividade é obrigatório';
    if (_selectedSubscriberRange == null) return 'Faixa de inscritos é obrigatória';
    if (_selectedMonetizationStatus == null) return 'Status de monetização é obrigatório';
    if (_mainNicheController.text.trim().isEmpty) return 'Nicho principal é obrigatório';
    if (_selectedContentFormats.isEmpty) return 'Selecione pelo menos um formato';
    if (_selectedCommercialIntent == null) return 'Intenção comercial é obrigatória';
    if (_selectedPublishingFrequency == null) return 'Frequência de publicação é obrigatória';
    return null;
  }

  /// Volta para etapa anterior
  void _handleBack() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  /// Confirmação final - cria/atualiza perfil na API
  Future<void> _handleConfirm() async {
    final userId = _authManager.getUserId();
    if (userId == null) {
      _showError('Usuário não autenticado. Faça login novamente.');
      return;
    }

    // Mostrar loading
    _showLoadingDialog();

    try {
      // Criar modelo
      final model = UserChoiceModel(
        id: _existingProfileId ?? '', // Vazio para novo perfil
        userId: userId,
        profileType: 'CREATOR',
        nicheContext: 'PORTUGAL_IMMIGRATION', // Contexto fixo da plataforma
        channelName: _channelNameController.text.trim(),
        channelHandle: _channelHandleController.text.trim(),
        channelAgeRange: _selectedChannelAgeRange,
        subscriberRange: _selectedSubscriberRange,
        monetizationStatus: _selectedMonetizationStatus,
        mainNiche: _mainNicheController.text.trim(),
        contentFormats: _selectedContentFormats,
        commercialIntent: _selectedCommercialIntent,
        offeredService: _offeredServiceController.text.trim().isNotEmpty
            ? _offeredServiceController.text.trim()
            : null,
        publishingFrequency: _selectedPublishingFrequency,
        contentDifferential: _contentDifferentialController.text.trim().isNotEmpty
            ? _contentDifferentialController.text.trim()
            : null,
      );

      // Salvar na API
      bool success;
      if (_isEditMode && _existingProfileId != null) {
        if (kDebugMode) print('🔄 [MainStepperForm] Atualizando perfil...');
        success = await _viewModel.updateUserChoice(model);
      } else {
        if (kDebugMode) print('➕ [MainStepperForm] Criando novo perfil...');
        success = await _viewModel.createUserChoice(model);
      }

      // Fechar loading
      if (mounted) Navigator.of(context).pop();

      if (success) {
        _showSuccessDialog();
      } else {
        _showError(_viewModel.error ?? 'Erro desconhecido ao salvar perfil');
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop(); // Fechar loading
      _showError('Erro: $e');
    }
  }

  /// Cancela e volta para MainProfileWelcomeScreen com sinalização
  Future<void> _handleCancel() async {
    final result = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Cancelar Cadastro?'),
        content: const Text(
          'Todo o seu progresso será perdido. Deseja continuar?',
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Não'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sim, Cancelar'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      _resetForm();
      
      // ✅ Volta para MainProfileWelcomeScreen com sinalização 'cancelled'
      // A tela receberá isso e mudará para modo EXIT automaticamente
      Navigator.of(context).pop('cancelled');
    }
  }

  /// Reseta o formulário
  void _resetForm() {
    setState(() {
      _currentStep = 0;
      _existingProfileId = null;
      _isEditMode = false;

      // Limpar controllers
      _channelNameController.clear();
      _channelHandleController.clear();
      _mainNicheController.clear();
      _offeredServiceController.clear();
      _contentDifferentialController.clear();

      // Limpar seleções
      _selectedChannelAgeRange = null;
      _selectedSubscriberRange = null;
      _selectedMonetizationStatus = null;
      _selectedContentFormats = [];
      _selectedCommercialIntent = null;
      _selectedPublishingFrequency = null;
    });
  }

  /// Dialogs

  void _showLoadingDialog() {
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const CupertinoAlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoActivityIndicator(radius: 14),
            SizedBox(height: 16),
            Text('Salvando perfil...'),
          ],
        ),
      ),
    );
  }

  void _showSuccessDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('🎉 Sucesso!'),
        content: Text(
          _isEditMode
              ? 'Seu perfil foi atualizado com sucesso!'
              : 'Seu perfil CREATOR foi criado com sucesso!',
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              Navigator.of(context).pop();
              _resetForm();
              // Voltar para primeira tab
              final homeState = context.findAncestorStateOfType<HomeContentTabScreenState>();
              homeState?.resetToFirstTab();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('❌ Erro'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _currentStep == 0 ? _handleCancel : _handleBack,
          child: Icon(
            _currentStep == 0
                ? CupertinoIcons.xmark
                : CupertinoIcons.chevron_back,
          ),
        ),
        middle: Text(
          _isEditMode ? 'Editar Perfil Creator' : 'Cadastro Creator',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _handleCancel,
          child: const Text(
            'Cancelar',
            style: TextStyle(color: CupertinoColors.destructiveRed),
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            _buildProgressIndicator(),

            // Conteúdo da etapa atual
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: _buildCurrentStepContent(),
              ),
            ),

            // Botões de navegação
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  /// Indicador de progresso horizontal com círculos numerados
  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_totalSteps, (index) {
            final isActive = index == _currentStep;
            final isCompleted = index < _currentStep;

            return Row(
              children: [
                // Círculo numerado
                Column(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isActive
                            ? CupertinoColors.activeBlue
                            : (isCompleted
                                ? CupertinoColors.activeBlue.withValues(alpha: 0.2)
                                : CupertinoColors.white),
                        border: Border.all(
                          color: isActive || isCompleted
                              ? CupertinoColors.activeBlue
                              : CupertinoColors.systemGrey3,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: isCompleted
                            ? const Icon(
                                CupertinoIcons.check_mark,
                                color: CupertinoColors.activeBlue,
                                size: 20,
                              )
                            : Text(
                                '${index + 1}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: isActive
                                      ? CupertinoColors.white
                                      : CupertinoColors.systemGrey,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Step ${index + 1}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                        color: isActive ? CupertinoColors.activeBlue : CupertinoColors.systemGrey,
                      ),
                    ),
                  ],
                ),

                // Linha conectora
                if (index < _totalSteps - 1)
                  Container(
                    width: 30,
                    height: 2,
                    margin: const EdgeInsets.only(bottom: 22, left: 4, right: 4),
                    color: isCompleted
                        ? CupertinoColors.activeBlue
                        : CupertinoColors.systemGrey4,
                  ),
              ],
            );
          }),
        ),
      ),
    );
  }

  /// Conteúdo da etapa atual com as 10 perguntas CREATOR
  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStep1ChannelInfo();
      case 1:
        return _buildStep2ChannelAge();
      case 2:
        return _buildStep3Subscribers();
      case 3:
        return _buildStep4Monetization();
      case 4:
        return _buildStep5Niche();
      case 5:
        return _buildStep6Formats();
      case 6:
        return _buildStep7CommercialIntent();
      case 7:
        return _buildStep8OfferedService();
      case 8:
        return _buildStep9PublishingFrequency();
      case 9:
        return _buildStep10Differential();
      default:
        return const SizedBox();
    }
  }

  // ========== AS 10 PERGUNTAS ==========

  /// Pergunta 1: Nome do canal + @handle
  Widget _buildStep1ChannelInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📺 Identificação do Canal',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Nos conte sobre seu canal',
          style: TextStyle(fontSize: 16, color: CupertinoColors.systemGrey),
        ),
        const SizedBox(height: 32),
        _buildLabel('Qual é o nome do seu canal no YouTube?'),
        _buildTextField(
          controller: _channelNameController,
          placeholder: 'Nome do canal',
          icon: CupertinoIcons.play_rectangle,
        ),
        const SizedBox(height: 20),
        _buildLabel('@handle ou link do canal'),
        _buildTextField(
          controller: _channelHandleController,
          placeholder: '@seuhandle ou youtube.com/c/...',
          icon: CupertinoIcons.link,
        ),
      ],
    );
  }

  /// Pergunta 2: Tempo de atividade
  Widget _buildStep2ChannelAge() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '⏱️ Tempo de Atividade',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Experiência no YouTube',
          style: TextStyle(fontSize: 16, color: CupertinoColors.systemGrey),
        ),
        const SizedBox(height: 32),
        _buildLabel('Há quanto tempo você publica conteúdo nesse canal?'),
        _buildEnumSingleSelect(
          options: const [
            ('Menos de 6 meses', 'LESS_THAN_6_MONTHS'),
            ('6 meses a 1 ano', 'SIX_MONTHS_TO_1_YEAR'),
            ('1 a 3 anos', 'ONE_TO_3_YEARS'),
            ('Mais de 3 anos', 'MORE_THAN_3_YEARS'),
          ],
          selectedValue: _selectedChannelAgeRange,
          onSelected: (value) => setState(() => _selectedChannelAgeRange = value),
        ),
      ],
    );
  }

  /// Pergunta 3: Inscritos
  Widget _buildStep3Subscribers() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '👥 Tamanho da Audiência',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Alcance atual do canal',
          style: TextStyle(fontSize: 16, color: CupertinoColors.systemGrey),
        ),
        const SizedBox(height: 32),
        _buildLabel('Quantos inscritos seu canal possui atualmente?'),
        _buildEnumSingleSelect(
          options: const [
            ('Menos de 1.000', 'LESS_THAN_1K'),
            ('1.000 a 10.000', 'ONE_K_TO_10K'),
            ('10.000 a 100.000', 'TEN_K_TO_100K'),
            ('Mais de 100.000', 'MORE_THAN_100K'),
          ],
          selectedValue: _selectedSubscriberRange,
          onSelected: (value) => setState(() => _selectedSubscriberRange = value),
        ),
      ],
    );
  }

  /// Pergunta 4: Monetização
  Widget _buildStep4Monetization() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '💰 Monetização',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Status do Programa de Parcerias',
          style: TextStyle(fontSize: 16, color: CupertinoColors.systemGrey),
        ),
        const SizedBox(height: 32),
        _buildLabel('Seu canal já está monetizado pelo YouTube (YPP)?'),
        _buildEnumSingleSelect(
          options: const [
            ('Sim, já monetizado', 'MONETIZED'),
            ('Não monetizado', 'NOT_MONETIZED'),
            ('Em processo de aprovação', 'IN_PROGRESS'),
          ],
          selectedValue: _selectedMonetizationStatus,
          onSelected: (value) => setState(() => _selectedMonetizationStatus = value),
        ),
      ],
    );
  }

  /// Pergunta 5: Nicho
  Widget _buildStep5Niche() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '🎯 Nicho Principal',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Tema central do conteúdo',
          style: TextStyle(fontSize: 16, color: CupertinoColors.systemGrey),
        ),
        const SizedBox(height: 32),
        _buildLabel('Qual é o tema central do seu conteúdo?'),
        const Text(
          'Exemplos: "Vistos para Portugal", "Vida de imigrante", "Trabalho no exterior"',
          style: TextStyle(fontSize: 13, color: CupertinoColors.systemGrey2),
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _mainNicheController,
          placeholder: 'Descreva o tema principal',
          icon: CupertinoIcons.sparkles,
        ),
      ],
    );
  }

  /// Pergunta 6: Formatos (Multi-Select)
  Widget _buildStep6Formats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '🎬 Formato de Conteúdo',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Tipos de vídeos que você produz',
          style: TextStyle(fontSize: 16, color: CupertinoColors.systemGrey),
        ),
        const SizedBox(height: 32),
        _buildLabel('Quais formatos você mais produz? (selecione todos que se aplicam)'),
        _buildEnumMultiSelect(
          options: const [
            ('Vlogs', 'VLOG'),
            ('Tutoriais', 'TUTORIAL'),
            ('Entrevistas', 'INTERVIEW'),
            ('Notícias/Análises', 'NEWS_ANALYSIS'),
            ('Shorts', 'SHORTS'),
            ('Outros', 'OTHER'),
          ],
          selectedValues: _selectedContentFormats,
          onToggle: (value) {
            setState(() {
              if (_selectedContentFormats.contains(value)) {
                _selectedContentFormats.remove(value);
              } else {
                _selectedContentFormats.add(value);
              }
            });
          },
        ),
      ],
    );
  }

  /// Pergunta 7: Intenção comercial
  Widget _buildStep7CommercialIntent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '💼 Intenção Comercial',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Seu objetivo na plataforma',
          style: TextStyle(fontSize: 16, color: CupertinoColors.systemGrey),
        ),
        const SizedBox(height: 32),
        _buildLabel('O que você busca ao divulgar seu canal nesta plataforma?'),
        _buildEnumSingleSelect(
          options: const [
            ('Parcerias com marcas', 'BRAND_PARTNERSHIP'),
            ('Vender serviços próprios', 'SELL_OWN_SERVICES'),
            ('Captar audiência', 'AUDIENCE_GROWTH'),
            ('Consultoria', 'CONSULTING'),
            ('Outros', 'OTHER'),
          ],
          selectedValue: _selectedCommercialIntent,
          onSelected: (value) => setState(() => _selectedCommercialIntent = value),
        ),
      ],
    );
  }

  /// Pergunta 8: Serviço oferecido (OPCIONAL)
  Widget _buildStep8OfferedService() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '🛍️ Serviço ou Produto',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'O que você oferece (opcional)',
          style: TextStyle(fontSize: 16, color: CupertinoColors.systemGrey),
        ),
        const SizedBox(height: 32),
        _buildLabel('Você oferece algum serviço ou produto relacionado ao seu conteúdo?'),
        const Text(
          'Exemplos: "Consultoria de visto", "Mentoria", "E-book", "Grupo VIP"',
          style: TextStyle(fontSize: 13, color: CupertinoColors.systemGrey2),
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _offeredServiceController,
          placeholder: 'Descreva seu serviço/produto (opcional)',
          icon: CupertinoIcons.bag,
        ),
      ],
    );
  }

  /// Pergunta 9: Frequência de publicação
  Widget _buildStep9PublishingFrequency() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📅 Frequência de Publicação',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Ritmo de produção de conteúdo',
          style: TextStyle(fontSize: 16, color: CupertinoColors.systemGrey),
        ),
        const SizedBox(height: 32),
        _buildLabel('Com que frequência você publica novos vídeos?'),
        _buildEnumSingleSelect(
          options: const [
            ('Diariamente', 'DAILY'),
            ('Semanalmente', 'WEEKLY'),
            ('Quinzenalmente', 'BIWEEKLY'),
            ('Mensalmente', 'MONTHLY'),
            ('Irregular', 'IRREGULAR'),
          ],
          selectedValue: _selectedPublishingFrequency,
          onSelected: (value) => setState(() => _selectedPublishingFrequency = value),
        ),
      ],
    );
  }

  /// Pergunta 10: Diferenciais (OPCIONAL)
  Widget _buildStep10Differential() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '✨ Diferenciais',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'O que torna seu conteúdo único',
          style: TextStyle(fontSize: 16, color: CupertinoColors.systemGrey),
        ),
        const SizedBox(height: 32),
        _buildLabel('Em até 2 frases, o que torna seu conteúdo único dentro do seu nicho?'),
        const Text(
          'Opcional - máximo 500 caracteres',
          style: TextStyle(fontSize: 13, color: CupertinoColors.systemGrey2),
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _contentDifferentialController,
          placeholder: 'Descreva seus diferenciais (opcional)',
          icon: CupertinoIcons.star,
          maxLines: 4,
        ),
      ],
    );
  }

  /// Botões de navegação (Back e Confirm/Next)
  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: CupertinoColors.systemGrey6,
        border: Border(
          top: BorderSide(color: CupertinoColors.systemGrey4, width: 0.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Botão Back
            Expanded(
              child: CupertinoButton(
                padding: const EdgeInsets.symmetric(vertical: 16),
                borderRadius: BorderRadius.circular(12),
                color: CupertinoColors.systemGrey5,
                onPressed: _currentStep == 0 ? _handleCancel : _handleBack,
                child: Text(
                  _currentStep == 0 ? 'Cancelar' : 'Voltar',
                  style: const TextStyle(
                    color: CupertinoColors.black,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Botão Confirm/Next
            Expanded(
              child: CupertinoButton(
                padding: const EdgeInsets.symmetric(vertical: 16),
                borderRadius: BorderRadius.circular(12),
                color: CupertinoColors.activeBlue,
                onPressed: _handleNext,
                child: Text(
                  _currentStep == _totalSteps - 1 ? 'Confirmar' : 'Próximo',
                  style: const TextStyle(
                    color: CupertinoColors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========== WIDGETS AUXILIARES ==========

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: CupertinoColors.black,
        ),
      ),
    );
  }

  /// Campo de texto estilizado
  Widget _buildTextField({
    required TextEditingController controller,
    required String placeholder,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey.withValues(alpha: 0.15),
            offset: const Offset(0, 1),
            blurRadius: 3,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 14, top: maxLines > 1 ? 14 : 0),
            child: Icon(
              icon,
              color: CupertinoColors.activeBlue,
              size: 22,
            ),
          ),
          Expanded(
            child: CupertinoTextField(
              controller: controller,
              placeholder: placeholder,
              maxLines: maxLines,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: const BoxDecoration(),
              style: const TextStyle(fontSize: 16, color: CupertinoColors.black),
              placeholderStyle: TextStyle(
                color: CupertinoColors.systemGrey2.withValues(alpha: 0.8),
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Radio buttons estilo iOS (Seleção única)
  Widget _buildEnumSingleSelect({
    required List<(String, String)> options, // (Label, EnumValue)
    required String? selectedValue,
    required  ValueChanged<String> onSelected,
  }) {
    return Column(
      children: options.map((option) {
        final label = option.$1;
        final value = option.$2;
        final isSelected = selectedValue == value;

        return GestureDetector(
          onTap: () => onSelected(value),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected
                  ? CupertinoColors.activeBlue.withValues(alpha: 0.1)
                  : CupertinoColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? CupertinoColors.activeBlue
                    : CupertinoColors.systemGrey4,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: CupertinoColors.systemGrey.withValues(alpha: 0.1),
                  offset: const Offset(0, 1),
                  blurRadius: 2,
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  isSelected
                      ? CupertinoIcons.check_mark_circled_solid
                      : CupertinoIcons.circle,
                  color: isSelected
                      ? CupertinoColors.activeBlue
                      : CupertinoColors.systemGrey3,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected
                          ? CupertinoColors.activeBlue
                          : CupertinoColors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Checkboxes estilo iOS (Seleção múltipla)
  Widget _buildEnumMultiSelect({
    required List<(String, String)> options, // (Label, EnumValue)
    required List<String> selectedValues,
    required ValueChanged<String> onToggle,
  }) {
    return Column(
      children: options.map((option) {
        final label = option.$1;
        final value = option.$2;
        final isSelected = selectedValues.contains(value);

        return GestureDetector(
          onTap: () => onToggle(value),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected
                  ? CupertinoColors.activeBlue.withValues(alpha: 0.1)
                  : CupertinoColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? CupertinoColors.activeBlue
                    : CupertinoColors.systemGrey4,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: CupertinoColors.systemGrey.withValues(alpha: 0.1),
                  offset: const Offset(0, 1),
                  blurRadius: 2,
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  isSelected
                      ? CupertinoIcons.checkmark_circle_fill
                      : CupertinoIcons.circle,
                  color: isSelected
                      ? CupertinoColors.activeBlue
                      : CupertinoColors.systemGrey3,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected
                          ? CupertinoColors.activeBlue
                          : CupertinoColors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
