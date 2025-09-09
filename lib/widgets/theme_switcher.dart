import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../services/theme_service.dart';

class ThemeSwitcher extends StatelessWidget {
  const ThemeSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeService.themeModeNotifier,
      builder: (context, currentMode, child) {
        return Container(
          padding: EdgeInsets.all(4.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Appearance',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              SizedBox(height: 3.h),
              _buildThemeOption(
                context,
                'Light Mode',
                'Clean and bright interface',
                Icons.light_mode,
                ThemeMode.light,
                currentMode,
              ),
              SizedBox(height: 2.h),
              _buildThemeOption(
                context,
                'Dark Mode',
                'Easy on the eyes in low light',
                Icons.dark_mode,
                ThemeMode.dark,
                currentMode,
              ),
              SizedBox(height: 2.h),
              _buildThemeOption(
                context,
                'System Default',
                'Follows your device settings',
                Icons.settings_system_daydream,
                ThemeMode.system,
                currentMode,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    ThemeMode mode,
    ThemeMode currentMode,
  ) {
    final isSelected = currentMode == mode;
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: () => ThemeService.setThemeMode(mode),
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: isSelected 
            ? theme.colorScheme.primary.withOpacity(0.1)
            : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
              ? theme.colorScheme.primary
              : theme.colorScheme.outline.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: isSelected 
                  ? theme.colorScheme.primary
                  : theme.colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isSelected 
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurfaceVariant,
                size: 6.w,
              ),
            ),
            SizedBox(width: 4.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: isSelected 
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: theme.colorScheme.primary,
                size: 5.w,
              ),
          ],
        ),
      ),
    );
  }
}
