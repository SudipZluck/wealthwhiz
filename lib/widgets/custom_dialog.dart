import 'package:flutter/material.dart';
import '../constants/constants.dart';
import 'custom_button.dart';

class CustomDialog extends StatelessWidget {
  final String title;
  final String? message;
  final Widget? content;
  final List<Widget>? actions;
  final String? confirmText;
  final String? cancelText;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final bool isLoading;
  final Color? backgroundColor;
  final double borderRadius;
  final EdgeInsets? padding;
  final TextStyle? titleStyle;
  final TextStyle? messageStyle;
  final Widget? icon;
  final Color? iconColor;
  final bool barrierDismissible;
  final CustomButtonType confirmButtonType;
  final CustomButtonType cancelButtonType;

  const CustomDialog({
    super.key,
    required this.title,
    this.message,
    this.content,
    this.actions,
    this.confirmText,
    this.cancelText,
    this.onConfirm,
    this.onCancel,
    this.isLoading = false,
    this.backgroundColor,
    this.borderRadius = 12.0,
    this.padding,
    this.titleStyle,
    this.messageStyle,
    this.icon,
    this.iconColor,
    this.barrierDismissible = true,
    this.confirmButtonType = CustomButtonType.primary,
    this.cancelButtonType = CustomButtonType.outline,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: backgroundColor ?? theme.dialogTheme.backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (icon != null) ...[
              Center(
                child: IconTheme(
                  data: IconThemeData(
                    color: iconColor ?? theme.colorScheme.primary,
                    size: 48,
                  ),
                  child: icon!,
                ),
              ),
              const SizedBox(height: AppConstants.paddingMedium),
            ],
            Text(
              title,
              style: titleStyle ??
                  AppConstants.headlineMedium.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: AppConstants.paddingMedium),
              Text(
                message!,
                style: messageStyle ??
                    AppConstants.bodyLarge.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                textAlign: TextAlign.center,
              ),
            ],
            if (content != null) ...[
              const SizedBox(height: AppConstants.paddingMedium),
              content!,
            ],
            const SizedBox(height: AppConstants.paddingLarge),
            if (actions != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: actions!,
              )
            else if (confirmText != null || cancelText != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (cancelText != null)
                    Expanded(
                      child: CustomButton(
                        text: cancelText!,
                        onPressed: isLoading
                            ? null
                            : onCancel ?? () => Navigator.pop(context),
                        type: cancelButtonType,
                      ),
                    ),
                  if (confirmText != null && cancelText != null)
                    const SizedBox(width: AppConstants.paddingMedium),
                  if (confirmText != null)
                    Expanded(
                      child: CustomButton(
                        text: confirmText!,
                        onPressed: isLoading ? null : onConfirm,
                        isLoading: isLoading,
                        type: confirmButtonType,
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    String? message,
    Widget? content,
    List<Widget>? actions,
    String? confirmText,
    String? cancelText,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    bool isLoading = false,
    Color? backgroundColor,
    double borderRadius = 12.0,
    EdgeInsets? padding,
    TextStyle? titleStyle,
    TextStyle? messageStyle,
    Widget? icon,
    Color? iconColor,
    bool barrierDismissible = true,
    CustomButtonType confirmButtonType = CustomButtonType.primary,
    CustomButtonType cancelButtonType = CustomButtonType.outline,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => CustomDialog(
        title: title,
        message: message,
        content: content,
        actions: actions,
        confirmText: confirmText,
        cancelText: cancelText,
        onConfirm: onConfirm,
        onCancel: onCancel,
        isLoading: isLoading,
        backgroundColor: backgroundColor,
        borderRadius: borderRadius,
        padding: padding,
        titleStyle: titleStyle,
        messageStyle: messageStyle,
        icon: icon,
        iconColor: iconColor,
        barrierDismissible: barrierDismissible,
        confirmButtonType: confirmButtonType,
        cancelButtonType: cancelButtonType,
      ),
    );
  }
}
