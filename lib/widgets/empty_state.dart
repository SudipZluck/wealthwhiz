import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../constants/constants.dart';
import 'custom_button.dart';

class EmptyState extends StatelessWidget {
  final String title;
  final String? message;
  final String? buttonText;
  final VoidCallback? onButtonPressed;
  final Widget? illustration;
  final String? lottieAsset;
  final double? lottieWidth;
  final double? lottieHeight;
  final TextStyle? titleStyle;
  final TextStyle? messageStyle;
  final EdgeInsets padding;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final CustomButtonType buttonType;

  const EmptyState({
    super.key,
    required this.title,
    this.message,
    this.buttonText,
    this.onButtonPressed,
    this.illustration,
    this.lottieAsset,
    this.lottieWidth = 200,
    this.lottieHeight = 200,
    this.titleStyle,
    this.messageStyle,
    this.padding = const EdgeInsets.all(AppConstants.paddingLarge),
    this.mainAxisAlignment = MainAxisAlignment.center,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.buttonType = CustomButtonType.primary,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: padding,
      child: Column(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        children: [
          if (illustration != null)
            Padding(
              padding: const EdgeInsets.only(
                bottom: AppConstants.paddingLarge,
              ),
              child: illustration!,
            )
          else if (lottieAsset != null)
            Padding(
              padding: const EdgeInsets.only(
                bottom: AppConstants.paddingLarge,
              ),
              child: Lottie.asset(
                lottieAsset!,
                width: lottieWidth,
                height: lottieHeight,
                fit: BoxFit.contain,
              ),
            ),
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
          if (buttonText != null && onButtonPressed != null) ...[
            const SizedBox(height: AppConstants.paddingLarge),
            CustomButton(
              text: buttonText!,
              onPressed: onButtonPressed,
              type: buttonType,
            ),
          ],
        ],
      ),
    );
  }
}

class ErrorState extends StatelessWidget {
  final String title;
  final String? message;
  final String? buttonText;
  final VoidCallback? onButtonPressed;
  final Widget? illustration;
  final String? lottieAsset;
  final double? lottieWidth;
  final double? lottieHeight;
  final TextStyle? titleStyle;
  final TextStyle? messageStyle;
  final EdgeInsets padding;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final CustomButtonType buttonType;

  const ErrorState({
    super.key,
    required this.title,
    this.message,
    this.buttonText = 'Try Again',
    this.onButtonPressed,
    this.illustration,
    this.lottieAsset,
    this.lottieWidth = 200,
    this.lottieHeight = 200,
    this.titleStyle,
    this.messageStyle,
    this.padding = const EdgeInsets.all(AppConstants.paddingLarge),
    this.mainAxisAlignment = MainAxisAlignment.center,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.buttonType = CustomButtonType.primary,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      title: title,
      message: message ?? AppConstants.genericError,
      buttonText: buttonText,
      onButtonPressed: onButtonPressed,
      illustration: illustration,
      lottieAsset: lottieAsset,
      lottieWidth: lottieWidth,
      lottieHeight: lottieHeight,
      titleStyle: titleStyle,
      messageStyle: messageStyle,
      padding: padding,
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      buttonType: buttonType,
    );
  }
}

class NoConnectionState extends StatelessWidget {
  final VoidCallback? onRetry;
  final String? lottieAsset;
  final EdgeInsets padding;

  const NoConnectionState({
    super.key,
    this.onRetry,
    this.lottieAsset,
    this.padding = const EdgeInsets.all(AppConstants.paddingLarge),
  });

  @override
  Widget build(BuildContext context) {
    return ErrorState(
      title: 'No Internet Connection',
      message: AppConstants.networkError,
      buttonText: 'Retry',
      onButtonPressed: onRetry,
      lottieAsset: lottieAsset,
      padding: padding,
    );
  }
}
