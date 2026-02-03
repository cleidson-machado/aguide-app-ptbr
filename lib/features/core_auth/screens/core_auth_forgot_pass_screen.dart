// ignore_for_file: library_private_types_in_public_api, sort_child_properties_last

import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';

class CoreAuthForgotPassScreen extends StatefulWidget {
  const CoreAuthForgotPassScreen({super.key});

  @override
  _CoreAuthForgotPassScreenState createState() =>
      _CoreAuthForgotPassScreenState();
}

class _CoreAuthForgotPassScreenState extends State<CoreAuthForgotPassScreen> {
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  bool _codeSent = false;
  bool _isValidInput = false;

  // Método para validar entrada
  void _validateInput(String value) {
    setState(() {
      _isValidInput = value.contains('@') || value.length >= 10;
    });
  }

  // Método para enviar código
  void _sendCode() {
    if (_isValidInput) {
      setState(() {
        _codeSent = true;
      });
      // Aqui você implementaria o envio de código via SMS ou Email
    }
  }

  // Método para validar PIN inserido
  void _verifyPin() {
    if (_pinController.text.length == 6) {
      // Implementar verificação do código aqui
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          "Forgot Password - Plus",
          style: GoogleFonts.lato(fontWeight: FontWeight.bold),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título
            Text(
              "Enter your email or phone number to reset your password",
              style: GoogleFonts.lato(
                fontSize: 16,
                color: CupertinoColors.systemGrey,
              ),
            ),
            const SizedBox(height: 20),

            // Campo de entrada
            CupertinoTextField(
              controller: _inputController,
              placeholder: "Email or Phone Number",
              padding: const EdgeInsets.all(16),
              onChanged: _validateInput,
              keyboardType: TextInputType.emailAddress,
              decoration: BoxDecoration(
                color: CupertinoColors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: CupertinoColors.systemGrey3),
              ),
            ),
            const SizedBox(height: 16),

            // Botão para enviar código
            SizedBox(
              width: double.infinity,
              child: CupertinoButton.filled(
                borderRadius: BorderRadius.circular(8),
                child: const Text("Send Code"),
                onPressed: _isValidInput ? _sendCode : null,
              ),
            ),

            // Seção de código PIN após envio
            if (_codeSent) ...[
              const SizedBox(height: 24),
              Text(
                "Enter the 6-digit code sent to your email or phone",
                style: GoogleFonts.lato(
                  fontSize: 16,
                  color: CupertinoColors.systemGrey,
                ),
              ),
              const SizedBox(height: 16),

              // Campo de entrada do PIN
              CupertinoTextField(
                controller: _pinController,
                placeholder: "Enter PIN",
                padding: const EdgeInsets.all(16),
                maxLength: 6,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                onChanged: (value) {
                  if (value.length == 6) _verifyPin();
                },
                decoration: BoxDecoration(
                  color: CupertinoColors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: CupertinoColors.systemGrey3),
                ),
              ),
              const SizedBox(height: 16),

              // Botão para reenviar código
              Align(
                alignment: Alignment.centerRight,
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: Text(
                    "Resend Code",
                    style: GoogleFonts.lato(
                      fontSize: 14,
                      color: CupertinoColors.activeBlue,
                    ),
                  ),
                  onPressed: _sendCode,
                ),
              ),

              const SizedBox(height: 20),

              // Botão para verificar código
              SizedBox(
                width: double.infinity,
                child: CupertinoButton.filled(
                  borderRadius: BorderRadius.circular(8),
                  child: const Text("Verify"),
                  onPressed:
                      _pinController.text.length == 6 ? _verifyPin : null,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
