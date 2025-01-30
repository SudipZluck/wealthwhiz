import 'package:flutter/material.dart';
import '../constants/constants.dart';
import '../services/theme_service.dart';
import 'widgets.dart';

class ThemePickerDialog extends StatelessWidget {
  final ThemeMode currentTheme;
  final ValueChanged<ThemeMode> onThemeChanged;

  const ThemePickerDialog({
    super.key,
    required this.currentTheme,
    required this.onThemeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CustomDialog(
      title: 'Choose Theme',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildThemeOption(
            context,
            'System',
            Icons.brightness_auto,
            ThemeMode.system,
          ),
          const Divider(),
          _buildThemeOption(
            context,
            'Light',
            Icons.light_mode,
            ThemeMode.light,
          ),
          const Divider(),
          _buildThemeOption(
            context,
            'Dark',
            Icons.dark_mode,
            ThemeMode.dark,
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    String title,
    IconData icon,
    ThemeMode mode,
  ) {
    final isSelected = currentTheme == mode;
    final theme = Theme.of(context);

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? theme.colorScheme.primary : null,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? theme.colorScheme.primary : null,
          fontWeight: isSelected ? FontWeight.bold : null,
        ),
      ),
      trailing: isSelected
          ? Icon(
              Icons.check,
              color: theme.colorScheme.primary,
            )
          : null,
      onTap: () {
        onThemeChanged(mode);
        Navigator.pop(context);
      },
    );
  }
}
