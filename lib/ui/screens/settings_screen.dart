import 'package:flutter/material.dart';
import 'package:codepath/theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _voiceChatEnabled = true;
  bool _textChatEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text('Battle Preferences', style: TextStyle(color: AppColors.accentBlue, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Enable Voice Chat', style: TextStyle(color: Colors.white)),
            subtitle: const Text('Allow voice communication during 1v1 battles', style: TextStyle(color: AppColors.textSecondary)),
            value: _voiceChatEnabled,
            activeThumbColor: AppColors.accentBlue,
            onChanged: (val) => setState(() => _voiceChatEnabled = val),
          ),
          SwitchListTile(
            title: const Text('Enable Text Chat', style: TextStyle(color: Colors.white)),
            subtitle: const Text('Allow text messaging during 1v1 battles', style: TextStyle(color: AppColors.textSecondary)),
            value: _textChatEnabled,
            activeThumbColor: AppColors.accentBlue,
            onChanged: (val) => setState(() => _textChatEnabled = val),
          ),
        ],
      ),
    );
  }
}
