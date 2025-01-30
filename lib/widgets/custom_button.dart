import 'package:flutter/material.dart';
import '../constants/constants.dart';

enum CustomButtonType { primary, secondary, outline, text }

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final CustomButtonType type;
  final bool isLoading;
  final bool isFullWidth;
  final double? width;
  final double height;
  final IconData? icon;
  final Color? color;
  final EdgeInsets? padding;
  final double borderRadius;
  final TextStyle? textStyle;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.type = CustomButtonType.primary,
    this.isLoading = false,
    this.isFullWidth = true,
    this.width,
    this.height = 48.0,
    this.icon,
    this.color,
    this.padding,
    this.borderRadius = 12.0,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget buttonChild = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading)
          Padding(
            padding: const EdgeInsets.only(right: AppConstants.paddingSmall),
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  _getTextColor(theme),
                ),
              ),
            ),
          )
        else if (icon != null)
          Padding(
            padding: const EdgeInsets.only(right: AppConstants.paddingSmall),
            child: Icon(
              icon,
              color: _getTextColor(theme),
              size: 20,
            ),
          ),
        Text(
          text,
          style: textStyle?.copyWith(
                color: _getTextColor(theme),
              ) ??
              AppConstants.bodyLarge.copyWith(
                color: _getTextColor(theme),
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );

    Widget button;
    switch (type) {
      case CustomButtonType.primary:
        button = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color ?? theme.colorScheme.primary,
            foregroundColor: Colors.white,
            padding: padding,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
          ),
          child: buttonChild,
        );
        break;

      case CustomButtonType.secondary:
        button = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color ?? theme.colorScheme.secondary,
            foregroundColor: Colors.white,
            padding: padding,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
          ),
          child: buttonChild,
        );
        break;

      case CustomButtonType.outline:
        button = OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: color ?? theme.colorScheme.primary,
            padding: padding,
            side: BorderSide(
              color: color ?? theme.colorScheme.primary,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
          ),
          child: buttonChild,
        );
        break;

      case CustomButtonType.text:
        button = TextButton(
          onPressed: isLoading ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: color ?? theme.colorScheme.primary,
            padding: padding,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
          ),
          child: buttonChild,
        );
        break;
    }

    return SizedBox(
      width: isFullWidth ? double.infinity : width,
      height: height,
      child: button,
    );
  }

  Color _getTextColor(ThemeData theme) {
    switch (type) {
      case CustomButtonType.primary:
      case CustomButtonType.secondary:
        return Colors.white;
      case CustomButtonType.outline:
      case CustomButtonType.text:
        return color ?? theme.colorScheme.primary;
    }
  }
}
