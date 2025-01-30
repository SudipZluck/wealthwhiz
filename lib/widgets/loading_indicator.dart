import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../constants/constants.dart';

class LoadingIndicator extends StatelessWidget {
  final double size;
  final Color? color;
  final double strokeWidth;
  final String? message;
  final TextStyle? messageStyle;
  final bool useShimmer;

  const LoadingIndicator({
    super.key,
    this.size = 40.0,
    this.color,
    this.strokeWidth = 4.0,
    this.message,
    this.messageStyle,
    this.useShimmer = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final indicator = SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? theme.colorScheme.primary,
        ),
      ),
    );

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        indicator,
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
      ],
    );

    if (useShimmer) {
      return Shimmer.fromColors(
        baseColor: theme.colorScheme.surface,
        highlightColor: theme.colorScheme.surface.withOpacity(0.3),
        child: content,
      );
    }

    return content;
  }
}

class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final Color? barrierColor;
  final String? message;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.barrierColor,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: barrierColor ?? Colors.black54,
            child: Center(
              child: LoadingIndicator(
                message: message,
              ),
            ),
          ),
      ],
    );
  }
}

class ShimmerLoadingBlock extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;
  final Color? baseColor;
  final Color? highlightColor;
  final EdgeInsets? margin;

  const ShimmerLoadingBlock({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 12.0,
    this.baseColor,
    this.highlightColor,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: margin,
      child: Shimmer.fromColors(
        baseColor: baseColor ?? theme.colorScheme.surface,
        highlightColor:
            highlightColor ?? theme.colorScheme.surface.withOpacity(0.3),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
      ),
    );
  }
}

class ShimmerLoadingList extends StatelessWidget {
  final int itemCount;
  final double itemHeight;
  final EdgeInsets padding;
  final EdgeInsets itemPadding;
  final double itemBorderRadius;
  final Color? baseColor;
  final Color? highlightColor;

  const ShimmerLoadingList({
    super.key,
    this.itemCount = 5,
    this.itemHeight = 80.0,
    this.padding = const EdgeInsets.all(AppConstants.paddingMedium),
    this.itemPadding = const EdgeInsets.symmetric(
      vertical: AppConstants.paddingSmall,
    ),
    this.itemBorderRadius = 12.0,
    this.baseColor,
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        children: List.generate(
          itemCount,
          (index) => ShimmerLoadingBlock(
            width: double.infinity,
            height: itemHeight,
            borderRadius: itemBorderRadius,
            baseColor: baseColor,
            highlightColor: highlightColor,
            margin: itemPadding,
          ),
        ),
      ),
    );
  }
}
