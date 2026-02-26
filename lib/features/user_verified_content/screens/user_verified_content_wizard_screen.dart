import 'package:flutter/cupertino.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:portugal_guide/app/core/config/injector.dart';
import 'package:portugal_guide/app/routing/app_routes.dart';
import 'package:portugal_guide/features/user_verified_content/user_verified_content_view_model.dart';

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

  // Controllers para os campos de texto
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _proofValueController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

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
      viewModel.nextStep();
    }
  }

  /// Submete a solicitação
  Future<void> _handleSubmit() async {
    final success = await viewModel.submitRequest();

    if (!mounted) return;

    if (success) {
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

  /// Indicador de progresso visual
  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      child: Row(
        children: List.generate(viewModel.totalSteps, (index) {
          final isActive = index == viewModel.currentStep;
          final isCompleted = index < viewModel.currentStep;

          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: index < viewModel.totalSteps - 1 ? 8 : 0,
              ),
              child: Column(
                children: [
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color:
                          isCompleted || isActive
                              ? CupertinoColors.activeBlue
                              : CupertinoColors.systemGrey4,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Etapa ${index + 1}',
                    style: TextStyle(
                      fontSize: 12,
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
            ),
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
        CupertinoTextField(
          controller: _titleController,
          placeholder: 'Ex: Guia Completo de Portugal',
          onChanged: (value) => viewModel.updateContentInfo(title: value),
          padding: const EdgeInsets.all(12),
        ),
        const SizedBox(height: 20),

        // URL do conteúdo
        _buildLabel('URL do Conteúdo *'),
        CupertinoTextField(
          controller: _urlController,
          placeholder: 'Ex: https://youtube.com/watch?v=...',
          keyboardType: TextInputType.url,
          onChanged: (value) => viewModel.updateContentInfo(url: value),
          padding: const EdgeInsets.all(12),
        ),
        const SizedBox(height: 20),

        // Tipo de conteúdo
        _buildLabel('Tipo de Conteúdo *'),
        CupertinoSlidingSegmentedControl<String>(
          groupValue: viewModel.contentType,
          onValueChanged: (value) => viewModel.updateContentInfo(type: value),
          children: const {
            'video': Text('Vídeo'),
            'article': Text('Artigo'),
            'course': Text('Curso'),
          },
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
        CupertinoSlidingSegmentedControl<String>(
          groupValue: viewModel.proofType,
          onValueChanged: (value) => viewModel.updateProofInfo(type: value),
          children: const {
            'youtube_channel': Text('Canal YouTube'),
            'domain_ownership': Text('Domínio'),
            'social_media': Text('Rede Social'),
          },
        ),
        const SizedBox(height: 20),

        // Valor da prova
        _buildLabel(_getProofValueLabel()),
        CupertinoTextField(
          controller: _proofValueController,
          placeholder: _getProofValuePlaceholder(),
          onChanged: (value) => viewModel.updateProofInfo(value: value),
          padding: const EdgeInsets.all(12),
        ),
        const SizedBox(height: 20),

        // Dica de ajuda
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: CupertinoColors.systemGrey6,
            borderRadius: BorderRadius.circular(8),
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
        CupertinoTextField(
          controller: _descriptionController,
          placeholder:
              'Descreva brevemente seu conteúdo e por que deseja verificá-lo',
          maxLines: 5,
          onChanged:
              (value) => viewModel.updateAdditionalInfo(description: value),
          padding: const EdgeInsets.all(12),
        ),
        const SizedBox(height: 20),

        // E-mail de contato
        _buildLabel('E-mail de Contato *'),
        CupertinoTextField(
          controller: _emailController,
          placeholder: 'seu.email@exemplo.com',
          keyboardType: TextInputType.emailAddress,
          onChanged: (value) => viewModel.updateAdditionalInfo(email: value),
          padding: const EdgeInsets.all(12),
        ),
        const SizedBox(height: 20),

        // Informações sobre o processo
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: CupertinoColors.systemGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: CupertinoColors.systemGreen.withOpacity(0.3),
            ),
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
                  color: CupertinoColors.systemGrey4,
                  onPressed:
                      viewModel.isLoading ? null : viewModel.previousStep,
                  child: const Text(
                    'Voltar',
                    style: TextStyle(
                      color: CupertinoColors.black,
                      fontWeight: FontWeight.w600,
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
                color: CupertinoColors.activeBlue,
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
}
