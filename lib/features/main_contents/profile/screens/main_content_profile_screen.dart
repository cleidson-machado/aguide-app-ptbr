// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:portugal_guide/app/helpers/env_key_helper_config.dart';

class MainContentProfileScreen extends StatefulWidget {
  const MainContentProfileScreen({super.key});

  @override
  _MainContentProfileScreenState createState() => _MainContentProfileScreenState();
}

class _MainContentProfileScreenState extends State<MainContentProfileScreen> {
  final TextEditingController _nameController = TextEditingController(text: "Suzane Jobs");
  final TextEditingController _emailController = TextEditingController(text: "abc@gmail.com");
  final TextEditingController _phoneController = TextEditingController(text: "+91 123456890");

  final isDev = EnvKeyHelperConfig.label.toUpperCase() == 'DEV'; // TEST

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text(">> Lista Contatos para Ambos <<")),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          children: [
            // Profile Picture
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                const CircleAvatar(
                  radius: 50,
                  backgroundImage: NetworkImage("https://images.pexels.com/photos/415829/pexels-photo-415829.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=2"), // Replace with user's image
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {}, // Implement image change logic
                  child: Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: CupertinoColors.black,
                    ),
                    padding: const EdgeInsets.all(5),
                    child: const Icon(CupertinoIcons.pencil, color: CupertinoColors.white, size: 16),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),
            const Text("Suzane Jobs", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Text("user@gmail.com", style: TextStyle(color: CupertinoColors.systemGrey)),

            const SizedBox(height: 30),

            // Name Field
            _buildTextField("Name", _nameController),
            const SizedBox(height: 20),

            // Email Field
            _buildTextField("Email", _emailController),
            const SizedBox(height: 20),

            // Phone Field
            _buildTextField("Phone", _phoneController),
            const SizedBox(height: 30),

            // Save Button
            CupertinoButton.filled(
              child: const Text("SAVE"),
              onPressed: () {
                // Implement save logic
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        const SizedBox(height: 5),
        CupertinoTextField(
          controller: controller,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          decoration: BoxDecoration(
            color: CupertinoColors.systemGrey5,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ],
    );
  }
}

