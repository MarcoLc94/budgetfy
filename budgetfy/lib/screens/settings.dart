import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final s = settings.strings;

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        backgroundColor: AppColors.darkBg,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          s.settings,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _SettingSection(
            icon: Icons.translate_rounded,
            title: s.language,
            child: Row(
              children: [
                _OptionChip(
                  label: s.spanish,
                  selected: settings.language == 'es',
                  onTap: () => settings.setLanguage('es'),
                ),
                const SizedBox(width: 8),
                _OptionChip(
                  label: s.english,
                  selected: settings.language == 'en',
                  onTap: () => settings.setLanguage('en'),
                ),
              ],
            ),
          ),
          _SettingSection(
            icon: Icons.dark_mode_outlined,
            title: s.theme,
            child: Row(
              children: [
                _OptionChip(
                  label: s.darkMode,
                  icon: Icons.dark_mode_rounded,
                  selected: settings.isDark,
                  onTap: () => settings.setDark(true),
                ),
                const SizedBox(width: 8),
                _OptionChip(
                  label: s.lightMode,
                  icon: Icons.light_mode_rounded,
                  selected: !settings.isDark,
                  onTap: () => settings.setDark(false),
                ),
              ],
            ),
          ),
          _SettingSection(
            icon: Icons.attach_money_rounded,
            title: s.currency,
            child: Row(
              children: [
                _OptionChip(
                  label: 'MXN',
                  selected: settings.currency == 'MXN',
                  onTap: () => settings.setCurrency('MXN'),
                ),
                const SizedBox(width: 8),
                _OptionChip(
                  label: 'USD',
                  selected: settings.currency == 'USD',
                  onTap: () => settings.setCurrency('USD'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _SettingSection({
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.lightPurple, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _OptionChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  const _OptionChip({
    required this.label,
    this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primaryPurple.withValues(alpha: 0.18)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? AppColors.primaryPurple : AppColors.divider,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 16,
                  color: selected
                      ? AppColors.lightPurple
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  color: selected
                      ? AppColors.lightPurple
                      : AppColors.textSecondary,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
