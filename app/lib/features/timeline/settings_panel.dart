// Settings panel popup.
//
// TLDR:
// Overview: A card that shows font size options and a logout button.
// Problem: Need a place for persistent user configuration.
// Solution: Displays a shadow-boxed card with FontSize picker and Logout.
// Breaking Changes: No.
//
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:happening/core/settings/settings_service.dart';

/// Popup panel for app settings (Font size, Logout).
class SettingsPanel extends StatelessWidget {
  const SettingsPanel({
    super.key,
    required this.settingsService,
    required this.onSignOut,
  });

  final SettingsService settingsService;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 180,
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(
          color: Color(0xFF2A2A40),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(8),
            bottomRight: Radius.circular(8),
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black45, blurRadius: 10, offset: Offset(0, 4)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'SETTINGS',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 12),

            // Font Size Picker
            const Text(
              'Font Size',
              style: TextStyle(color: Colors.white, fontSize: 11),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: FontSize.values.map((fs) {
                final isSelected = settingsService.current.fontSize == fs;
                return GestureDetector(
                  onTap: () =>
                      settingsService.update(AppSettings(fontSize: fs)),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blueAccent : Colors.white10,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      fs.name[0].toUpperCase() + fs.name.substring(1),
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontSize: 10,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),
            const Divider(color: Colors.white10, height: 1),
            const SizedBox(height: 12),

            // Logout Button
            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: onSignOut,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                        color: Colors.redAccent.withValues(alpha: 0.3)),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'Logout',
                    style: TextStyle(color: Colors.redAccent, fontSize: 10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
