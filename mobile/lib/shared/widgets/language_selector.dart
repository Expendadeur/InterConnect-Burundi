import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class LanguageSelector extends StatelessWidget {
  final String selectedLanguage;
  final ValueChanged<String> onLanguageChanged;

  static const Map<String, String> languages = {
    'rn': 'Kirundi (Burundi) 🇧🇮',
    'fr': 'Français 🇫🇷',
    'en': 'English 🇬🇧',
    'sw': 'Kiswahili 🇹🇿',
    'ar': 'العربية 🇸🇦',
  };

  const LanguageSelector({
    super.key,
    required this.selectedLanguage,
    required this.onLanguageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedLanguage,
          isExpanded: true,
          icon: const Icon(Icons.language, color: AppColors.primary),
          items: languages.entries.map((entry) {
            return DropdownMenuItem<String>(
              value: entry.key,
              child: Text(
                entry.value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) onLanguageChanged(val);
          },
        ),
      ),
    );
  }
}

