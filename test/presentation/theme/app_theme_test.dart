import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fosdem_flutter/presentation/theme/app_theme.dart';
import 'package:fosdem_flutter/presentation/theme/app_colors.dart';

void main() {
  group('AppTheme Tests', () {
    test('lightTheme should have Material 3 enabled', () {
      expect(AppTheme.lightTheme.useMaterial3, isTrue);
    });

    test('darkTheme should have Material 3 enabled', () {
      expect(AppTheme.darkTheme.useMaterial3, isTrue);
    });

    test('lightTheme should have light brightness', () {
      expect(AppTheme.lightTheme.brightness, Brightness.light);
    });

    test('darkTheme should have dark brightness', () {
      expect(AppTheme.darkTheme.brightness, Brightness.dark);
    });
  });

  group('AppColors Tests', () {
    test('primary color should be FOSDEM orange', () {
      expect(AppColors.primary, const Color(0xFFE95420));
    });

    test('secondary color should be FOSDEM purple', () {
      expect(AppColors.secondary, const Color(0xFF77216F));
    });

    test('should have success color defined', () {
      expect(AppColors.success, const Color(0xFF4CAF50));
    });

    test('should have error color defined', () {
      expect(AppColors.error, const Color(0xFFF44336));
    });
  });
}
