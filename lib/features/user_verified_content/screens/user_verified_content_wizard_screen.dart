import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:portugal_guide/app/core/config/injector.dart';
import 'package:portugal_guide/app/core/auth/auth_token_manager.dart';
import 'package:portugal_guide/app/routing/app_routes.dart';
import 'package:portugal_guide/features/user_verified_content/user_verified_content_view_model.dart';
import 'package:portugal_guide/features/user_tracking_data/user_tracking_data_service.dart';
import 'package:portugal_guide/features/user_tracking_data/enums/points_reason_enum.dart';

/// Tela do wizard de verificação de conteúdo com 3 etapas
/// Ocupa tela inteira, fora do padrão de navegação por Tabs
class UserVerifiedContentWizardScreen extends StatefulWidget {
  const UserVerifiedContentWizardScreen({super.key});

  @override
  State<UserVerifiedContentWizardScreen> createState() =>
      _UserVerifiedContentWizardScreenState();
}

class _UserVerifiedContentWizardScreenState
    extends State<UserVerifiedContentWizardScreen> {
  final UserVerifiedContentViewModel viewModel =
      injector<UserVerifiedContentViewModel>();
  final UserTrackingDataService _trackingService = injector<UserTrackingDataService>(); // 🆕 PHASE B
  final AuthTokenManager _tokenManager = injector<AuthTokenManager>(); // 🆕 PHASE B

  // Controllers para os campos de texto
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _proofValueController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  
  bool _hasTrackedEntry = false; // 🆕 PHASE B: Flag para evitar tracking duplicado

  @override
  void initState() {
    super.initState();
    
    // 🆕 PHASE B: Rastrear entrada no wizard (wizardEntry +2 pontos)
    _trackWizardEntry();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 🆕 PHASE B: WIZARD TRACKING METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Rastreia entrada no wizard (uma vez apenas)
  /// Pontos: +2 (PointsReason.wizardEntry)
  Future<void> _trackWizardEntry() async {
    if (_hasTrackedEntry) return; // Evitar tracking duplicado

    final userId = _tokenManager.getUserId();
    if (userId == null || userId.isEmpty) {
      if (kDebugMode) {
        debugPrint('⚠️  [WizardTracking] UserId não disponível para tracking de entrada');
      }
      return;
    }

    try {
      await _trackingService.addPointsWithReason(
        userId: userId,
        points: 2,
        reason: PointsReason.wizardEntry,
      );

      _hasTrackedEntry = true;

      if (kDebugMode) {
        debugPrint('✅ [WizardTracking] Entrada no wizard rastreada (+2 pontos)');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [WizardTracking] Erro ao rastrear entrada: $e');
      }
    }
  }

  /// Rastreia conclusão de um step do wizard
  /// Pontos: +2 por step (wizardStep1/2/3)
  Future<void> _trackStepCompletion(int stepNumber) async {
    final userId = _tokenManager.getUserId();
    if (userId == null || userId.isEmpty) return;

    // Mapear step number para PointsReason
    PointsReason? reason;
    switch (stepNumber) {
      case 1:
        reason = PointsReason.wizardStep1;
        break;
      case 2:
        reason = PointsReason.wizardStep2;
        break;
      case 3:
        reason = PointsReason.wizardStep3;
        break;
      default:
        return; // Step inválido
    }

    try {
      await _trackingService.addPointsWithReason(
        userId: userId,
        points: 2,
        reason: reason,
      );

      if (kDebugMode) {
        debugPrint('✅ [WizardTracking] Step $stepNumber completado (+2 pontos)');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [WizardTracking] Erro ao rastrear step $stepNumber: $e');
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════

  @override
  void dispose() {
    _titleController.dispose();
    _urlController.dispose();
    _proofValueController.dispose();
    _descriptionController.dispose();
    _emailController.dispose();
    viewModel.dispose();
    super.dispose();
  }

  /// Exibe diálogo de confirmação para cancelar
  Future<void> _showCancelConfirmation() async {
    final result = await showCupertinoDialog<bool>(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: const Text('Cancelar Solicitação?'),
            content: const Text(
              'Todos os dados preenchidos serão perdidos. Deseja continuar?',
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
      viewModel.resetWizard();
      Modular.to.navigate(AppRoutes.main);
    }
  }

  /// Avança para próxima etapa
  void _handleNext() {
    if (viewModel.isLastStep) {
      _handleSubmit();
    } else {
      // 🆕 PHASE B: Captura step atual ANTES de avançar
      final completedStep = viewModel.currentStep + 1; // Step que acabou de ser completado (1-based)
      
      viewModel.nextStep();
      
      // 🆕 PHASE B: Rastreia conclusão do step após avançar (non-blocking)
      _trackStepCompletion(completedStep);
    }
  }

  /// Submete a solicitação
  Future<void> _handleSubmit() async {
    final success = await viewModel.submitRequest();

    if (!mounted) return;

    if (success) {
      // 🆕 PHASE B: Rastreia conclusão do step 3 (último step) após submit bem sucedido
      _trackStepCompletion(3);
      
      await showCupertinoDialog(
        context: context,
        builder:
            (context) => CupertinoAlertDialog(
              title: const Text('✅ Solicitação Enviada!'),
              content: const Text(
                'Sua solicitação de verificação foi enviada com sucesso. '
                'Você receberá uma resposta em até 48 horas no e-mail cadastrado.',
              ),
              actions: [
                CupertinoDialogAction(
                  isDefaultAction: true,
                  onPressed: () {
                    Navigator.of(context).pop();
                    viewModel.resetWizard();
                    Modular.to.navigate(AppRoutes.main);
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed:
              viewModel.isFirstStep
                  ? _showCancelConfirmation
                  : viewModel.previousStep,
          child: Icon(
            viewModel.isFirstStep
                ? CupertinoIcons.xmark
                : CupertinoIcons.chevron_back,
          ),
        ),
        middle: const Text('Verificação de Conteúdo'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _showCancelConfirmation,
          child: const Text(
            'Cancelar',
            style: TextStyle(color: CupertinoColors.destructiveRed),
          ),
        ),
      ),
      child: SafeArea(
        child: ListenableBuilder(
          listenable: viewModel,
          builder: (context, child) {
            return Column(
              children: [
                // Progress indicator
                _buildProgressIndicator(),

                // Conteúdo da etapa atual
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: _buildCurrentStep(),
                  ),
                ),

                // Botões de navegação
                _buildNavigationButtons(),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Indicador de progresso visual com círculos numerados
  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(viewModel.totalSteps, (index) {
          final isActive = index == viewModel.currentStep;
          final isCompleted = index < viewModel.currentStep;

          return Row(
            children: [
              // Círculo numerado
              Column(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          isActive
                              ? CupertinoColors.activeBlue
                              : (isCompleted
                                  ? CupertinoColors.activeBlue.withOpacity(0.2)
                                  : CupertinoColors.white),
                      border: Border.all(
                        color:
                            isActive || isCompleted
                                ? CupertinoColors.activeBlue
                                : CupertinoColors.systemGrey3,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color:
                              isActive
                                  ? CupertinoColors.white
                                  : (isCompleted
                                      ? CupertinoColors.activeBlue
                                      : CupertinoColors.systemGrey),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Etapa ${index + 1}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          isActive ? FontWeight.w600 : FontWeight.normal,
                      color:
                          isActive
                              ? CupertinoColors.activeBlue
                              : CupertinoColors.systemGrey,
                    ),
                  ),
                ],
              ),

              // Linha conectora
              if (index < viewModel.totalSteps - 1)
                Container(
                  width: 60,
                  height: 2,
                  margin: const EdgeInsets.only(bottom: 30),
                  color:
                      isCompleted
                          ? CupertinoColors.activeBlue
                          : CupertinoColors.systemGrey4,
                ),
            ],
          );
        }),
      ),
    );
  }

  /// Retorna o widget da etapa atual
  Widget _buildCurrentStep() {
    switch (viewModel.currentStep) {
      case 0:
        return _buildStep1();
      case 1:
        return _buildStep2();
      case 2:
        return _buildStep3();
      default:
        return const SizedBox.shrink();
    }
  }

  /// Etapa 1: Informações do Conteúdo
  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📋 Informações do Conteúdo',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Informe os dados básicos do conteúdo que você deseja vincular.',
          style: TextStyle(fontSize: 16, color: CupertinoColors.systemGrey),
        ),
        const SizedBox(height: 32),

        // Título do conteúdo
        _buildLabel('Título do Conteúdo *'),
        _buildStyledTextField(
          controller: _titleController,
          placeholder: 'Ex: Guia Completo de Portugal',
          icon: CupertinoIcons.doc_text,
          onChanged: (value) => viewModel.updateContentInfo(title: value),
        ),
        const SizedBox(height: 20),

        // URL do conteúdo
        _buildLabel('URL do Conteúdo *'),
        _buildStyledTextField(
          controller: _urlController,
          placeholder: 'Ex: https://youtube.com/watch?v=...',
          icon: CupertinoIcons.link,
          keyboardType: TextInputType.url,
          onChanged: (value) => viewModel.updateContentInfo(url: value),
        ),
        const SizedBox(height: 20),

        // Tipo de conteúdo
        _buildLabel('Tipo de Conteúdo *'),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: CupertinoColors.systemGrey.withValues(alpha: 0.15),
                offset: const Offset(0, 1),
                blurRadius: 3,
                spreadRadius: 0,
              ),
              BoxShadow(
                color: CupertinoColors.black.withValues(alpha: 0.05),
                offset: const Offset(0, 2),
                blurRadius: 4,
                spreadRadius: -1,
              ),
            ],
          ),
          child: CupertinoSlidingSegmentedControl<String>(
            groupValue: viewModel.contentType,
            onValueChanged: (value) => viewModel.updateContentInfo(type: value),
            backgroundColor: CupertinoColors.systemGrey6,
            thumbColor: CupertinoColors.white,
            padding: const EdgeInsets.all(4),
            children: const {
              'video': Padding(
                padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                child: Text('Vídeo', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
              ),
              'article': Padding(
                padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                child: Text('Artigo', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
              ),
              'course': Padding(
                padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                child: Text('Curso', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
              ),
            },
          ),
        ),
        const SizedBox(height: 20),

        if (viewModel.error != null) _buildErrorMessage(viewModel.error!),
      ],
    );
  }

  /// Etapa 2: Prova de Propriedade
  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '🔐 Prova de Propriedade',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Comprove que você é o proprietário deste conteúdo.',
          style: TextStyle(fontSize: 16, color: CupertinoColors.systemGrey),
        ),
        const SizedBox(height: 32),

        // Tipo de prova
        _buildLabel('Tipo de Comprovação *'),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: CupertinoColors.systemGrey.withValues(alpha: 0.15),
                offset: const Offset(0, 1),
                blurRadius: 3,
                spreadRadius: 0,
              ),
              BoxShadow(
                color: CupertinoColors.black.withValues(alpha: 0.05),
                offset: const Offset(0, 2),
                blurRadius: 4,
                spreadRadius: -1,
              ),
            ],
          ),
          child: CupertinoSlidingSegmentedControl<String>(
            groupValue: viewModel.proofType,
            onValueChanged: (value) => viewModel.updateProofInfo(type: value),
            backgroundColor: CupertinoColors.systemGrey6,
            thumbColor: CupertinoColors.white,
            padding: const EdgeInsets.all(4),
            children: const {
              'youtube_channel': Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Text('Canal YouTube', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              ),
              'domain_ownership': Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Text('Domínio', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              ),
              'social_media': Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Text('Rede Social', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              ),
            },
          ),
        ),
        const SizedBox(height: 20),

        // Valor da prova
        _buildLabel(_getProofValueLabel()),
        _buildStyledTextField(
          controller: _proofValueController,
          placeholder: _getProofValuePlaceholder(),
          icon: _getProofIcon(),
          onChanged: (value) => viewModel.updateProofInfo(value: value),
        ),
        const SizedBox(height: 20),

        // Dica de ajuda
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: CupertinoColors.systemGrey6,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: CupertinoColors.systemGrey.withOpacity(0.12),
                offset: const Offset(0, 1),
                blurRadius: 3,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(
                CupertinoIcons.info_circle,
                color: CupertinoColors.activeBlue,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _getProofHint(),
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        ),

        if (viewModel.error != null) ...[
          const SizedBox(height: 20),
          _buildErrorMessage(viewModel.error!),
        ],
      ],
    );
  }

  /// Etapa 3: Informações Adicionais
  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📝 Informações Adicionais',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Finalize sua solicitação com algumas informações complementares.',
          style: TextStyle(fontSize: 16, color: CupertinoColors.systemGrey),
        ),
        const SizedBox(height: 32),

        // Descrição
        _buildLabel('Descrição do Conteúdo *'),
        _buildStyledTextField(
          controller: _descriptionController,
          placeholder:
              'Descreva brevemente seu conteúdo e por que deseja verificá-lo',
          icon: CupertinoIcons.text_alignleft,
          maxLines: 5,
          onChanged:
              (value) => viewModel.updateAdditionalInfo(description: value),
        ),
        const SizedBox(height: 20),

        // E-mail de contato
        _buildLabel('E-mail de Contato *'),
        _buildStyledTextField(
          controller: _emailController,
          placeholder: 'seu.email@exemplo.com',
          icon: CupertinoIcons.mail,
          keyboardType: TextInputType.emailAddress,
          onChanged: (value) => viewModel.updateAdditionalInfo(email: value),
        ),
        const SizedBox(height: 20),

        // Informações sobre o processo
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: CupertinoColors.systemGreen.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: CupertinoColors.systemGreen.withOpacity(0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: CupertinoColors.systemGreen.withOpacity(0.15),
                offset: const Offset(0, 2),
                blurRadius: 4,
                spreadRadius: 0,
              ),
            ],
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    CupertinoIcons.checkmark_shield,
                    color: CupertinoColors.systemGreen,
                    size: 24,
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Próximos Passos',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Text(
                '• Análise em até 48 horas\n'
                '• Notificação por e-mail\n'
                '• Benefícios de criador verificado\n'
                '• Suporte prioritário',
                style: TextStyle(fontSize: 14, height: 1.5),
              ),
            ],
          ),
        ),

        if (viewModel.error != null) ...[
          const SizedBox(height: 20),
          _buildErrorMessage(viewModel.error!),
        ],
      ],
    );
  }

  /// Botões de navegação
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
            // Botão Voltar (apenas se não for primeira etapa)
            if (!viewModel.isFirstStep) ...[
              Expanded(
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  borderRadius: BorderRadius.circular(12),
                  color: CupertinoColors.systemGrey5,
                  onPressed:
                      viewModel.isLoading ? null : viewModel.previousStep,
                  child: const Text(
                    'Voltar',
                    style: TextStyle(
                      color: CupertinoColors.black,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],

            // Botão Próximo/Enviar
            Expanded(
              flex: viewModel.isFirstStep ? 1 : 1,
              child: CupertinoButton(
                padding: const EdgeInsets.symmetric(vertical: 16),
                borderRadius: BorderRadius.circular(12),
                color:
                    viewModel.isLoading || !viewModel.canGoNext
                        ? CupertinoColors.systemGrey3
                        : CupertinoColors.activeBlue,
                onPressed:
                    viewModel.isLoading || !viewModel.canGoNext
                        ? null
                        : _handleNext,
                child:
                    viewModel.isLoading
                        ? const CupertinoActivityIndicator(
                          color: CupertinoColors.white,
                        )
                        : Text(
                          viewModel.isLastStep
                              ? 'Enviar Solicitação'
                              : 'Próximo',
                          style: TextStyle(
                            color:
                                viewModel.isLoading || !viewModel.canGoNext
                                    ? CupertinoColors.systemGrey
                                    : CupertinoColors.white,
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

  // Helpers para labels e placeholders dinâmicos

  String _getProofValueLabel() {
    switch (viewModel.proofType) {
      case 'youtube_channel':
        return 'ID do Canal YouTube *';
      case 'domain_ownership':
        return 'Domínio do Site *';
      case 'social_media':
        return 'Usuário da Rede Social *';
      default:
        return 'Valor da Prova *';
    }
  }

  String _getProofValuePlaceholder() {
    switch (viewModel.proofType) {
      case 'youtube_channel':
        return 'Ex: UC1234567890abcdef';
      case 'domain_ownership':
        return 'Ex: meusite.com';
      case 'social_media':
        return 'Ex: @meuusuario';
      default:
        return '';
    }
  }

  String _getProofHint() {
    switch (viewModel.proofType) {
      case 'youtube_channel':
        return 'Você receberá um código para inserir na descrição do seu canal.';
      case 'domain_ownership':
        return 'Você receberá um arquivo TXT para adicionar ao DNS do seu domínio.';
      case 'social_media':
        return 'Você receberá um código para publicar em uma postagem pública.';
      default:
        return '';
    }
  }

  IconData _getProofIcon() {
    switch (viewModel.proofType) {
      case 'youtube_channel':
        return CupertinoIcons.play_rectangle;
      case 'domain_ownership':
        return CupertinoIcons.globe;
      case 'social_media':
        return CupertinoIcons.at;
      default:
        return CupertinoIcons.checkmark_shield;
    }
  }

  // Widgets auxiliares

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildErrorMessage(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CupertinoColors.systemRed.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CupertinoColors.systemRed.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            CupertinoIcons.exclamationmark_triangle,
            color: CupertinoColors.systemRed,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: CupertinoColors.systemRed,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Widget de campo de texto estilizado com ícone e sombreamento interno
  Widget _buildStyledTextField({
    required TextEditingController controller,
    required String placeholder,
    required IconData icon,
    required ValueChanged<String> onChanged,
    TextInputType? keyboardType,
    int? maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          // Sombra superior interna (simula profundidade)
          BoxShadow(
            color: CupertinoColors.systemGrey.withValues(alpha: 0.15),
            offset: const Offset(0, 1),
            blurRadius: 3,
            spreadRadius: 0,
          ),
          // Sombra interna sutil para dar efeito "afundado"
          BoxShadow(
            color: CupertinoColors.black.withValues(alpha: 0.05),
            offset: const Offset(0, 2),
            blurRadius: 4,
            spreadRadius: -1,
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          // Gradiente sutil para simular inner shadow
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              CupertinoColors.systemGrey6.withValues(alpha: 0.3),
              CupertinoColors.systemGrey6.withValues(alpha: 0.1),
              CupertinoColors.white.withValues(alpha: 0.5),
            ],
            stops: const [0.0, 0.15, 1.0],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment:
              maxLines != null && maxLines > 1
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.center,
          children: [
            Padding(
              padding: EdgeInsets.only(
                left: 14,
                top: maxLines != null && maxLines > 1 ? 14 : 0,
              ),
              child: Icon(
                icon,
                color: CupertinoColors.systemGrey2,
                size: 22,
              ),
            ),
            Expanded(
              child: CupertinoTextField(
                controller: controller,
                placeholder: placeholder,
                keyboardType: keyboardType,
                maxLines: maxLines,
                onChanged: onChanged,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: const BoxDecoration(),
                style: const TextStyle(
                  fontSize: 16,
                  color: CupertinoColors.black,
                ),
                placeholderStyle: TextStyle(
                  color: CupertinoColors.systemGrey2.withOpacity(0.8),
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
