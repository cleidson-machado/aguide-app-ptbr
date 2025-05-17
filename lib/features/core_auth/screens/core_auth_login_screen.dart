import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:portugal_guide/app/routing/app_routes.dart';
import 'package:portugal_guide/features/core_auth/screens/core_auth_forgot_pass_screen.dart';
//import 'package:portugal_guide/features/core_auth/screens/core_auth_register_screen.dart'; //#######>>>> USED to CREATE A SIMPLE LINK TO OTHER PAGE.....

class CoreAuthLoginScreen extends StatelessWidget {
  const CoreAuthLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Imagem no topo
            Container(
              height: 250,
              color: CupertinoColors.lightBackgroundGray,
              child: Center(
                child: CupertinoButton(
                  child: const Icon(CupertinoIcons.photo,
                      size: 50, color: CupertinoColors.inactiveGray),
                  onPressed: () {}, // Placeholder para imagem
                ),
              ),
            ),

            // Seção de Login
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título
                  Text(
                    "Welcome - Plus!",
                    style: GoogleFonts.lato(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: CupertinoColors.black,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Campo de Email
                  CupertinoTextField(
                    placeholder: "Email Address",
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: CupertinoColors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: CupertinoColors.systemGrey3),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Campo de Senha
                  CupertinoTextField(
                    placeholder: "Password",
                    obscureText: true,
                    padding: const EdgeInsets.all(16),
                    suffix: CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Icon(CupertinoIcons.eye,
                          color: CupertinoColors.systemGrey),
                      onPressed: () {}, // Ação para exibir senha
                    ),
                    decoration: BoxDecoration(
                      color: CupertinoColors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: CupertinoColors.systemGrey3),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Esqueceu a senha
                  Align(
                    alignment: Alignment.centerRight,
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: Text(
                        "Forgot password?",
                        style: GoogleFonts.lato(
                          color: CupertinoColors.activeBlue,
                          fontSize: 14,
                        ),
                      ),
                      //#######>>>> SIMPLE LINK TO OTHER PAGE.....
                      onPressed: () {
                        Navigator.push(
                          context,
                          CupertinoPageRoute(
                              builder: (context) => const CoreAuthForgotPassScreen()),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Botão Login
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoButton.filled(
                      borderRadius: BorderRadius.circular(8),
                      child: const Text("Login"),
                      onPressed: () {
                        // Ação de login
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Cadastro
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Not a member?  | ",
                        style: GoogleFonts.lato(
                            fontSize: 14, color: CupertinoColors.systemGrey),
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        child: Text(
                          "Register now",
                          style: GoogleFonts.lato(
                            fontSize: 14,
                            color: CupertinoColors.activeBlue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        //#######>>>> SIMPLE LINK TO OTHER PAGE.....
                        onPressed: () {
                          Modular.to.pushNamed(AppRoutes.register); // Go to REGISTER Page (free route!??)

                          //#######>>>> THIS IS THE OLD WAY TO NAVIGATE! START
                          // Navigator.push(
                          //   context,
                          //   CupertinoPageRoute(
                          //       builder: (context) => const CoreAuthRegisterScreen()),
                          // );
                          //#######>>>> THIS IS THE OLD WAY TO NAVIGATE! END!

                        },
                      ),
                    ],
                  ),

                  // Linha divisória
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      children: [
                        const Expanded(
                            child: Divider(color: CupertinoColors.systemGrey3)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text("Or continue with",
                              style: GoogleFonts.lato(
                                  fontSize: 14,
                                  color: CupertinoColors.systemGrey)),
                        ),
                        const Expanded(
                            child: Divider(color: CupertinoColors.systemGrey3)),
                      ],
                    ),
                  ),

                  // Botões sociais
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _socialButton("G", CupertinoColors.destructiveRed),
                      const SizedBox(width: 16),
                      _socialButton("", CupertinoColors.black),
                      const SizedBox(width: 16),
                      _socialButton("f", CupertinoColors.systemBlue),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Método para criar botões sociais
  Widget _socialButton(String label, Color color) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.lato(
              fontSize: 24,
              color: CupertinoColors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      onPressed: () {
        // Ação social login
      },
    );
  }
}