import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';

class AuthCredentialsRegisterScreen extends StatefulWidget {
  const AuthCredentialsRegisterScreen({super.key});

  @override
  State<AuthCredentialsRegisterScreen> createState() => _AuthCredentialsRegisterScreenState();
}

class _AuthCredentialsRegisterScreenState extends State<AuthCredentialsRegisterScreen> {
  bool _agreeTerms = false;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          "Sign up - Plus",
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
              "Create an account to get started",
              style: GoogleFonts.lato(
                fontSize: 16,
                color: CupertinoColors.systemGrey,
              ),
            ),
            const SizedBox(height: 20),

            // Campo Nome
            _buildLabel("Name"),
            _buildInputField("Enter your name"),
            const SizedBox(height: 16),

            // Campo Email
            _buildLabel("Email Address"),
            _buildInputField("name@email.com"),
            const SizedBox(height: 16),

            // Campo Senha
            _buildLabel("Password"),
            _buildInputField("Create a password", obscureText: true),
            const SizedBox(height: 16),

            // Campo Confirmar Senha
            _buildInputField("Confirm password", obscureText: true),
            const SizedBox(height: 16),

            // Checkbox de Termos e Condições
            Row(
              children: [
                CupertinoCheckbox(
                  value: _agreeTerms,
                  onChanged: (value) {
                    setState(() {
                      _agreeTerms = value!;
                    });
                  },
                ),
                Expanded(
                  child: Wrap(
                    children: [
                      Text(
                        "I've read and agree with the ",
                        style: GoogleFonts.lato(fontSize: 14),
                      ),
                      GestureDetector(
                        onTap: () {}, // Ação de abrir termos
                        child: Text(
                          "Terms and Conditions",
                          style: GoogleFonts.lato(
                            fontSize: 14,
                            color: CupertinoColors.activeBlue,
                          ),
                        ),
                      ),
                      Text(" and the ", style: GoogleFonts.lato(fontSize: 14)),
                      GestureDetector(
                        onTap: () {}, // Ação de abrir política
                        child: Text(
                          "Privacy Policy.",
                          style: GoogleFonts.lato(
                            fontSize: 14,
                            color: CupertinoColors.activeBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Botão de Cadastro
            SizedBox(
              width: double.infinity,
              child: CupertinoButton.filled(
                borderRadius: BorderRadius.circular(8),
                onPressed:
                    _agreeTerms
                        ? () {
                          // Ação de cadastro
                        }
                        : null,
                child: const Text("Sign up"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Método para criar rótulos dos campos
  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.lato(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: CupertinoColors.black,
      ),
    );
  }

  // Método para criar campos de entrada personalizados
  Widget _buildInputField(String placeholder, {bool obscureText = false}) {
    return CupertinoTextField(
      placeholder: placeholder,
      obscureText: obscureText,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CupertinoColors.systemGrey3),
      ),
      suffix:
          obscureText
              ? CupertinoButton(
                padding: EdgeInsets.zero,
                child: const Icon(
                  CupertinoIcons.eye,
                  color: CupertinoColors.systemGrey,
                ),
                onPressed: () {}, // Ação de visibilidade da senha
              )
              : null,
    );
  }
}
