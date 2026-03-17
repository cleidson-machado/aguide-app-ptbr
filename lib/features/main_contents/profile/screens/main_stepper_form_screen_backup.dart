import 'package:flutter/cupertino.dart';
import 'package:portugal_guide/features/home_content/screens/home_content_tab_screen.dart';

/// Tela de formulário stepper com 10 perguntas (MOCK)
/// Usa design Cupertino com esquema de cores azul padrão iOS
class MainStepperFormScreen extends StatefulWidget {
  const MainStepperFormScreen({super.key});

  @override
  State<MainStepperFormScreen> createState() => _MainStepperFormScreenState();
}

class _MainStepperFormScreenState extends State<MainStepperFormScreen> {

  int _currentStep = 0;
  final int _totalSteps = 10;

  // Controllers para os campos (10 perguntas)
  final List<TextEditingController> _controllers = List.generate(
    10,
    (index) => TextEditingController(),
  );

  // Dados mockados para as perguntas
  final List<Map<String, dynamic>> _questions = [
    {
      'title': '👤 Personal Information',
      'subtitle': 'Tell us about yourself',
      'question': 'What is your full name?',
      'placeholder': 'Enter your full name',
      'icon': CupertinoIcons.person,
    },
    {
      'title': '🎂 Age Information',
      'subtitle': 'How old are you?',
      'question': 'What is your age?',
      'placeholder': 'Enter your age',
      'icon': CupertinoIcons.calendar,
    },
    {
      'title': '📧 Contact Details',
      'subtitle': 'How can we reach you?',
      'question': 'What is your email address?',
      'placeholder': 'your.email@example.com',
      'icon': CupertinoIcons.mail,
    },
    {
      'title': '📱 Phone Number',
      'subtitle': 'Alternative contact method',
      'question': 'What is your phone number?',
      'placeholder': '+1 (555) 123-4567',
      'icon': CupertinoIcons.phone,
    },
    {
      'title': '🏢 Company Information',
      'subtitle': 'Where do you work?',
      'question': 'What is your company name?',
      'placeholder': 'Enter company name',
      'icon': CupertinoIcons.building_2_fill,
    },
    {
      'title': '💼 Job Role',
      'subtitle': 'Your position',
      'question': 'What is your job title?',
      'placeholder': 'e.g., Software Engineer',
      'icon': CupertinoIcons.briefcase,
    },
    {
      'title': '🎓 Education',
      'subtitle': 'Your academic background',
      'question': 'What is your highest level of education?',
      'placeholder': 'e.g., Bachelor\'s Degree',
      'icon': CupertinoIcons.book,
    },
    {
      'title': '🌍 Location',
      'subtitle': 'Where are you based?',
      'question': 'What is your city/country?',
      'placeholder': 'City, Country',
      'icon': CupertinoIcons.location,
    },
    {
      'title': '💡 Experience',
      'subtitle': 'Years in your field',
      'question': 'How many years of experience do you have?',
      'placeholder': 'e.g., 5 years',
      'icon': CupertinoIcons.star,
    },
    {
      'title': '✅ Complete',
      'subtitle': 'Final confirmation',
      'question': 'Any additional comments?',
      'placeholder': 'Optional feedback or notes',
      'icon': CupertinoIcons.checkmark_alt,
    },
  ];

  // Respostas armazenadas (para exibição na última etapa)
  Map<int, String> _answers = {};

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  /// Avança para próxima etapa
  void _handleNext() {
    if (_currentStep < _totalSteps - 1) {
      // Salva resposta atual
      _answers[_currentStep] = _controllers[_currentStep].text;

      setState(() {
        _currentStep++;
      });
    } else {
      // Última etapa - confirmar
      _handleConfirm();
    }
  }

  /// Volta para etapa anterior
  void _handleBack() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  /// Confirmação final
  Future<void> _handleConfirm() async {
    // Salva última resposta
    _answers[_currentStep] = _controllers[_currentStep].text;

    await showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('🎉 Survey Complete!'),
        content: Text(
          'Thank you for completing the survey!\n\n'
          'Total answers: ${_answers.length}',
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              Navigator.of(context).pop();
              _resetForm();
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  /// Cancela e volta
  Future<void> _handleCancel() async {
    final result = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Cancel Survey?'),
        content: const Text(
          'All your progress will be lost. Continue?',
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      // Reseta o formulário
      _resetForm();
      
      // Busca o HomeContentTabScreen na árvore de widgets e reseta para a primeira tab
      final homeState = context.findAncestorStateOfType<HomeContentTabScreenState>();
      homeState?.resetToFirstTab();
    }
  }

  /// Reseta o formulário
  void _resetForm() {
    setState(() {
      _currentStep = 0;
      _answers.clear();
      for (var controller in _controllers) {
        controller.clear();
      }
    });
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
        middle: const Text(
          'Survey Form',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _handleCancel,
          child: const Text(
            'Cancel',
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

  /// Conteúdo da etapa atual
  Widget _buildCurrentStepContent() {
    final question = _questions[_currentStep];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Emoji e Título
        Text(
          question['title'],
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),

        // Subtítulo
        Text(
          question['subtitle'],
          style: const TextStyle(
            fontSize: 16,
            color: CupertinoColors.systemGrey,
          ),
        ),
        const SizedBox(height: 32),

        // Pergunta
        _buildLabel(question['question']),

        // Campo de texto
        _buildStyledTextField(
          controller: _controllers[_currentStep],
          placeholder: question['placeholder'],
          icon: question['icon'],
        ),
        const SizedBox(height: 24),

        // Preview de respostas anteriores (apenas na última etapa)
        if (_currentStep == _totalSteps - 1) _buildAnswersSummary(),
      ],
    );
  }

  /// Resumo de respostas (exibido na última etapa)
  Widget _buildAnswersSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey.withValues(alpha: 0.12),
            offset: const Offset(0, 1),
            blurRadius: 3,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📋 Your Answers',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(
            _totalSteps - 1,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${index + 1}. ',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: CupertinoColors.activeBlue,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _questions[index]['question'],
                          style: const TextStyle(
                            fontSize: 13,
                            color: CupertinoColors.systemGrey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _answers[index]?.isEmpty ?? true
                              ? 'Not Specified'
                              : _answers[index]!,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: _answers[index]?.isEmpty ?? true
                                ? CupertinoColors.systemRed
                                : CupertinoColors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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
            // Botão Back (sempre visível)
            Expanded(
              child: CupertinoButton(
                padding: const EdgeInsets.symmetric(vertical: 16),
                borderRadius: BorderRadius.circular(12),
                color: CupertinoColors.systemGrey5,
                onPressed: _currentStep == 0 ? _handleCancel : _handleBack,
                child: Text(
                  _currentStep == 0 ? 'Cancel' : 'Back',
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
                  _currentStep == _totalSteps - 1 ? 'Confirm' : 'Next',
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

  // Widgets auxiliares

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

  /// Campo de texto estilizado com ícone e sombreamento
  Widget _buildStyledTextField({
    required TextEditingController controller,
    required String placeholder,
    required IconData icon,
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
      child: Container(
        decoration: BoxDecoration(
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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 14),
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
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: const BoxDecoration(),
                style: const TextStyle(
                  fontSize: 16,
                  color: CupertinoColors.black,
                ),
                placeholderStyle: TextStyle(
                  color: CupertinoColors.systemGrey2.withValues(alpha: 0.8),
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
