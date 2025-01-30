import 'package:flutter/material.dart';
import '../constants/constants.dart';
import 'custom_button.dart';

class CustomBottomSheet extends StatelessWidget {
  final String? title;
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
  final bool isDismissible;
  final bool enableDrag;
  final double? height;
  final CustomButtonType confirmButtonType;
  final CustomButtonType cancelButtonType;

  const CustomBottomSheet({
    super.key,
    this.title,
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
    this.isDismissible = true,
    this.enableDrag = true,
    this.height,
    this.confirmButtonType = CustomButtonType.primary,
    this.cancelButtonType = CustomButtonType.outline,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);

    return Container(
      height: height,
      constraints: BoxConstraints(
        maxHeight: mediaQuery.size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: backgroundColor ?? theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(borderRadius),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(
                vertical: AppConstants.paddingSmall,
              ),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          if (title != null) ...[
            Padding(
              padding: EdgeInsets.only(
                top: AppConstants.paddingMedium,
                left: padding?.left ?? AppConstants.paddingLarge,
                right: padding?.right ?? AppConstants.paddingLarge,
              ),
              child: Text(
                title!,
                style: titleStyle ??
                    AppConstants.headlineMedium.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
              ),
            ),
            const Divider(),
          ],
          if (content != null)
            Flexible(
              child: SingleChildScrollView(
                padding:
                    padding ?? const EdgeInsets.all(AppConstants.paddingLarge),
                child: content!,
              ),
            ),
          if (actions != null || confirmText != null || cancelText != null)
            Container(
              padding:
                  padding ?? const EdgeInsets.all(AppConstants.paddingLarge),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                border: Border(
                  top: BorderSide(
                    color: theme.dividerColor,
                  ),
                ),
              ),
              child: actions != null
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: actions!,
                    )
                  : Row(
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
            ),
          // Add extra padding for bottom safe area
          SizedBox(height: mediaQuery.padding.bottom),
        ],
      ),
    );
  }

  static Future<T?> show<T>({
    required BuildContext context,
    String? title,
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
    bool isDismissible = true,
    bool enableDrag = true,
    double? height,
    CustomButtonType confirmButtonType = CustomButtonType.primary,
    CustomButtonType cancelButtonType = CustomButtonType.outline,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      isScrollControlled: true,
      builder: (context) => CustomBottomSheet(
        title: title,
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
        isDismissible: isDismissible,
        enableDrag: enableDrag,
        height: height,
        confirmButtonType: confirmButtonType,
        cancelButtonType: cancelButtonType,
      ),
    );
  }
}
