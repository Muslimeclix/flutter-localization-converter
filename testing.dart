import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shimmer/shimmer.dart';
import 'package:time_tracking_app/controllers/premium_controller.dart';
import 'package:time_tracking_app/utils/constants/ads_helper.dart';


import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:time_tracking_app/controllers/ads_controller.dart';
import 'package:time_tracking_app/utils/widgets/custom_ads_widgets/banner_ads.dart';

class GradientText extends StatelessWidget {
  const GradientText(
    this.text, {
    Key? key,
    required this.gradient,
    this.style,
  }) : super(key: key);

  final String text;
  final TextStyle? style;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) {
        return gradient.createShader(
          Rect.fromLTWH(0, 0, bounds.width, bounds.height),
        );
      },
      child: Text(text, style: style),
    );
  }
}





class BannerAdWidget extends StatefulWidget {
  final AdSize adSize;
  final EdgeInsets? margin;
  final EdgeInsets? padding;
  final Color? backgroundColor;
  final double? borderRadius;
  final bool showBorder;
  final Color? borderColor;
  final bool showShadow;
  final bool showOnlyWhenLoaded;
  final VoidCallback? onAdLoaded;
  final Function(LoadAdError)? onAdFailedToLoad;
  final VoidCallback? onAdClicked;

  const BannerAdWidget({
    super.key,
    this.adSize = AdSize.banner,
    this.margin,
    this.padding,
    this.backgroundColor,
    this.borderRadius,
    this.showBorder = false,
    this.borderColor,
    this.showShadow = true,
    this.showOnlyWhenLoaded = true,
    this.onAdLoaded,
    this.onAdFailedToLoad,
    this.onAdClicked,
  });

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  bool _isAdLoading = false;
  String? _loadError;

  final premiumCtrl = Get.find<PremiumController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_){

    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isAdLoading && !_isAdLoaded && _bannerAd == null) {
      _loadAd();
    }
  }


  Future<void> _loadAd() async {
    // Don't load ad if user is premium
    if (premiumCtrl.isPro.value == true) {
      return;
    }

    if (_isAdLoading) return;

    setState(() {
      _isAdLoading = true;
      _loadError = null;
    });

    debugPrint('Loading Banner Ad with size: ${widget.adSize}');

    _bannerAd = BannerAd(
      size: widget.adSize,
      adUnitId: AdsHelper.bannerAdUnitId,
      listener: _buildBannerAdListener(),
      request: const AdRequest(),
    );

    _bannerAd!.load();



  }

  BannerAdListener _buildBannerAdListener() {
    return BannerAdListener(
      onAdLoaded: (ad) {
        debugPrint('Banner Ad loaded successfully');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _isAdLoaded = true;
              _isAdLoading = false;
              _loadError = null;
            });
            widget.onAdLoaded?.call();
          }
        });

      },
      onAdFailedToLoad: (ad, error) {
        debugPrint('Banner ad failed to load: $error');
        ad.dispose();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _isAdLoaded = false;
              _isAdLoading = false;
              _loadError = error.message;
            });
            widget.onAdFailedToLoad?.call(error);
          }
        });

      },
      onAdClicked: (ad) {
        debugPrint('Banner ad clicked');
        widget.onAdClicked?.call();
      },
      onAdImpression: (ad) {
        debugPrint('Banner ad impression recorded');
      },
      onAdClosed: (ad) {
        debugPrint('Banner ad closed');
      },
      onAdWillDismissScreen: (ad) {
        debugPrint('Banner ad will dismiss screen');
      },
      onAdOpened: (ad) {
        debugPrint('Banner ad opened');
      },
    );
  }

  EdgeInsets _getDefaultMargin() {
    // Adjust margin based on ad size
    if (widget.adSize == AdSize.largeBanner ||
        widget.adSize == AdSize.mediumRectangle) {
      return const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0);
    } else if (widget.adSize == AdSize.leaderboard) {
      return const EdgeInsets.symmetric(vertical: 20.0, horizontal: 8.0);
    } else {
      return const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0);
    }
  }

  EdgeInsets _getDefaultPadding() {
    return  EdgeInsets.zero;
  }

  Widget _buildLoadingWidget() {
    final brightness = mounted ? Theme.of(context).brightness : Brightness.light;
    final isDark = brightness == Brightness.dark;

    return Container(
      width: widget.adSize.width.toDouble(),
      height: widget.adSize.height.toDouble(),
      margin: widget.margin ?? _getDefaultMargin(),
      padding: widget.padding ?? _getDefaultPadding(),
      decoration: BoxDecoration(
        color: widget.backgroundColor ??
            (isDark ? Colors.grey[800] : Colors.grey[200]),
        borderRadius: BorderRadius.circular(widget.borderRadius ?? 8.0),
        border: widget.showBorder
            ? Border.all(
          color: widget.borderColor ?? Colors.grey.withValues(alpha: 0.3),
          width: 1.0,
        )
            : null,
        boxShadow: widget.showShadow
            ? [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ]
            : null,
      ),
      child: const Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 8),
            Text(
              'Loading ad...',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      width: widget.adSize.width.toDouble(),
      height: widget.adSize.height.toDouble(),
      margin: widget.margin ?? _getDefaultMargin(),
      padding: widget.padding ?? _getDefaultPadding(),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(widget.borderRadius ?? 8.0),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red[400],
              size: 18,
            ),
            const SizedBox(height: 4),
            Text(
              'Ad failed to load',
              style: TextStyle(
                fontSize: 10,
                color: Colors.red[400],
              ),
            ),
            if (_loadError != null && widget.adSize.height > 60) ...[
              const SizedBox(height: 2),
              Text(
                _loadError!,
                style: TextStyle(
                  fontSize: 8,
                  color: Colors.red[300],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAdWidget() {

    return Container(
      margin: widget.margin ?? _getDefaultMargin(),
      padding: widget.padding,
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: BorderRadius.circular(widget.borderRadius ?? 8.0),
        border: widget.showBorder
            ? Border.all(
          color: widget.borderColor ?? Colors.grey.withValues(alpha: 0.3),
          width: 1.0,
        )
            : null,
        boxShadow: widget.showShadow
            ? [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ]
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: _bannerAd?.size.width.toDouble(),
        height: _bannerAd?.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Don't show anything if user is premium
    if (premiumCtrl.isPro.value == true) {
      return const SizedBox.shrink();
    }

    // Show loading state
    if (_isAdLoading && !_isAdLoaded) {
      return widget.showOnlyWhenLoaded ?  _buildShimmerLoadingWidget() : _buildLoadingWidget();
    }

    // Show error state
    if (_loadError != null && !_isAdLoaded) {
      return widget.showOnlyWhenLoaded ? _buildShimmerLoadingWidget() : _buildErrorWidget();
    }

    // Show ad if loaded
    if (_isAdLoaded && _bannerAd != null) {
      return _buildAdWidget();
    }

    // Default empty state
    return const SizedBox.shrink();
  }

  Widget _buildShimmerLoadingWidget() {
    return Shimmer.fromColors(
      baseColor: const Color(0xff374151).withValues(alpha: 0.1),
      highlightColor: Colors.white,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        width: widget.adSize.width.toDouble(),
        height: widget.adSize.height.toDouble(),
      ),
    );
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }
}

// Extension for easier usage with predefined ad sizes
extension BannerAdWidgetExtension on BannerAdWidget {
  static Widget standard({
    Key? key,
    EdgeInsets? margin,
    EdgeInsets? padding,
    Color? backgroundColor,
    double? borderRadius,
    bool showBorder = false,
    Color? borderColor,
    bool showShadow = true,
    VoidCallback? onAdLoaded,
    Function(LoadAdError)? onAdFailedToLoad,
    VoidCallback? onAdClicked,
  }) {
    return BannerAdWidget(
      key: key,
      adSize: AdSize.banner,
      margin: margin,
      padding: padding,
      backgroundColor: backgroundColor,
      borderRadius: borderRadius,
      showBorder: showBorder,
      borderColor: borderColor,
      showShadow: showShadow,
      onAdLoaded: onAdLoaded,
      onAdFailedToLoad: onAdFailedToLoad,
      onAdClicked: onAdClicked,
    );
  }

  static Widget large({
    Key? key,
    EdgeInsets? margin,
    EdgeInsets? padding,
    Color? backgroundColor,
    double? borderRadius,
    bool showBorder = false,
    Color? borderColor,
    bool showShadow = true,
    VoidCallback? onAdLoaded,
    Function(LoadAdError)? onAdFailedToLoad,
    VoidCallback? onAdClicked,
  }) {
    return BannerAdWidget(
      key: key,
      adSize: AdSize.largeBanner,
      margin: margin,
      padding: padding,
      backgroundColor: backgroundColor,
      borderRadius: borderRadius,
      showBorder: showBorder,
      borderColor: borderColor,
      showShadow: showShadow,
      onAdLoaded: onAdLoaded,
      onAdFailedToLoad: onAdFailedToLoad,
      onAdClicked: onAdClicked,
    );
  }

  static Widget mediumRectangle({
    Key? key,
    EdgeInsets? margin,
    EdgeInsets? padding,
    Color? backgroundColor,
    double? borderRadius,
    bool showBorder = false,
    Color? borderColor,
    bool showShadow = true,
    VoidCallback? onAdLoaded,
    Function(LoadAdError)? onAdFailedToLoad,
    VoidCallback? onAdClicked,
  }) {
    return BannerAdWidget(
      key: key,
      adSize: AdSize.mediumRectangle,
      margin: margin,
      padding: padding,
      backgroundColor: backgroundColor,
      borderRadius: borderRadius,
      showBorder: showBorder,
      borderColor: borderColor,
      showShadow: showShadow,
      onAdLoaded: onAdLoaded,
      onAdFailedToLoad: onAdFailedToLoad,
      onAdClicked: onAdClicked,
    );
  }

  static Widget leaderboard({
    Key? key,
    EdgeInsets? margin,
    EdgeInsets? padding,
    Color? backgroundColor,
    double? borderRadius,
    bool showBorder = false,
    Color? borderColor,
    bool showShadow = true,
    VoidCallback? onAdLoaded,
    Function(LoadAdError)? onAdFailedToLoad,
    VoidCallback? onAdClicked,
  }) {
    return BannerAdWidget(
      key: key,
      adSize: AdSize.leaderboard,
      margin: margin,
      padding: padding,
      backgroundColor: backgroundColor,
      borderRadius: borderRadius,
      showBorder: showBorder,
      borderColor: borderColor,
      showShadow: showShadow,
      onAdLoaded: onAdLoaded,
      onAdFailedToLoad: onAdFailedToLoad,
      onAdClicked: onAdClicked,
    );
  }

}




class AdaptiveAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget appBar;
  final double bannerHeight;
  final double spacing;
  final bool useSafeArea;
  final double bottomSize;

  AdaptiveAppBar({
    super.key,
    required this.appBar,
    this.bannerHeight = 80.0,
    this.spacing = 8.0,
    this.useSafeArea = true,
    this.bottomSize = 0.0,
  });

  final adsCtrl = Get.find<AdsController>();
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final content = Column(
        mainAxisSize: MainAxisSize.min,
        spacing: spacing,
        children: [
          if (adsCtrl.shouldShowBanner.value) const BannerAdWidget(),
          appBar,
        ],
      );

      return PreferredSize(
        preferredSize: preferredSize,
        child: useSafeArea ? SafeArea(child: content) : content,
      );
    });
  }

  @override
  Size get preferredSize {
    // Calculate height based on banner visibility
    final baseHeight = kToolbarHeight + bottomSize;
    final additionalHeight = adsCtrl.shouldShowBanner.value
        ? bannerHeight + spacing
        : 0.0;

    return Size.fromHeight(baseHeight + additionalHeight);
  }
}



import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shimmer/shimmer.dart';
import 'package:time_tracking_app/controllers/premium_controller.dart';
import 'package:time_tracking_app/utils/constants/ads_helper.dart';

class NativeAdWidget extends StatefulWidget {
  final TemplateType templateType;
  final EdgeInsets? margin;
  final Color? backgroundColor;
  final Color? primaryTextColor;
  final Color? secondaryTextColor;
  final Color? ctaBackgroundColor;
  final Color? ctaTextColor;
  final bool showOnlyWhenLoaded;

  const NativeAdWidget({
    super.key,
    this.templateType = TemplateType.medium,
    this.margin,
    this.backgroundColor,
    this.primaryTextColor,
    this.secondaryTextColor,
    this.ctaBackgroundColor,
    this.ctaTextColor,
    this.showOnlyWhenLoaded = true,
  });

  @override
  State<NativeAdWidget> createState() => _NativeAdWidgetState();
}

class _NativeAdWidgetState extends State<NativeAdWidget> {
  NativeAd? _nativeAd;
  bool _isAdLoaded = false;
  bool _isAdLoading = false;
  String? _loadError;
  final premiumCtrl = Get.find<PremiumController>();

  @override
  void initState() {
    super.initState();
    // _initializeController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isAdLoading && !_isAdLoaded && _nativeAd == null) {
      _loadAd();
    }
  }

  void _loadAd() {
    // Don't load ad if user is premium
    if (premiumCtrl.isPro.value == true) {
      return;
    }

    if (_isAdLoading) return;

    setState(() {
      _isAdLoading = true;
      _loadError = null;
    });

    debugPrint('Loading Native Ad with template: ${widget.templateType}');

    _nativeAd = NativeAd(
      adUnitId: AdsHelper.nativeAdUnitId,
      nativeTemplateStyle: _buildNativeTemplateStyle(),
      nativeAdOptions: _buildNativeAdOptions(),
      listener: _buildNativeAdListener(),
      request: const AdRequest(),
    );

    _nativeAd!.load();
  }

  NativeTemplateStyle _buildNativeTemplateStyle() {
    // Get theme brightness, fallback to light if context not available
    final brightness = mounted
        ? Theme.of(context).brightness
        : Brightness.light;
    final isDark = brightness == Brightness.dark;

    return NativeTemplateStyle(
      templateType: widget.templateType,
      mainBackgroundColor:
          widget.backgroundColor ??
          (isDark ? const Color(0xFF1E1E1E) : Colors.white),
      cornerRadius: 12.0,
      callToActionTextStyle: NativeTemplateTextStyle(
        textColor: widget.ctaTextColor ?? Colors.white,
        backgroundColor: widget.ctaBackgroundColor ?? Colors.blue,
        style: NativeTemplateFontStyle.bold,
        size: 14.0,
      ),
      primaryTextStyle: NativeTemplateTextStyle(
        textColor:
            widget.primaryTextColor ?? (isDark ? Colors.white : Colors.black),
        backgroundColor: Colors.transparent,
        style: NativeTemplateFontStyle.bold,
        size: 16.0,
      ),
      secondaryTextStyle: NativeTemplateTextStyle(
        textColor:
            widget.secondaryTextColor ??
            (isDark ? Colors.grey[300] : Colors.grey[600]),
        backgroundColor: Colors.transparent,
        style: NativeTemplateFontStyle.normal,
        size: 14.0,
      ),
      tertiaryTextStyle: NativeTemplateTextStyle(
        textColor:
            widget.secondaryTextColor ??
            (isDark ? Colors.grey[400] : Colors.grey[500]),
        backgroundColor: Colors.transparent,
        style: NativeTemplateFontStyle.normal,
        size: 12.0,
      ),
    );
  }

  // NativeAdOptions _buildNativeAdOptions() {
  //   return NativeAdOptions(
  //     requestCustomMuteThisAd: true,
  //     shouldRequestMultipleImages: widget.templateType != TemplateType.small,
  //     adChoicesPlacement: AdChoicesPlacement.topRightCorner,
  //     mediaAspectRatio: MediaAspectRatio.landscape,
  //     videoOptions: VideoOptions(
  //       startMuted: true,
  //       customControlsRequested: true,
  //       clickToExpandRequested: widget.templateType == TemplateType.medium,
  //     ),
  //   );
  // }
  NativeAdOptions _buildNativeAdOptions() {
    final isSmallTemplate = widget.templateType == TemplateType.small;

    return NativeAdOptions(
      requestCustomMuteThisAd: true,
      shouldRequestMultipleImages: !isSmallTemplate,
      adChoicesPlacement: AdChoicesPlacement.topRightCorner,
      mediaAspectRatio: isSmallTemplate
          ? MediaAspectRatio.square
          : MediaAspectRatio.landscape,
      videoOptions: VideoOptions(
        startMuted: true,
        customControlsRequested: !isSmallTemplate,
        clickToExpandRequested: !isSmallTemplate,
      ),
    );
  }

  NativeAdListener _buildNativeAdListener() {
    return NativeAdListener(
      onAdLoaded: (ad) {
        debugPrint('Native Ad Loaded successfully');
        if (mounted) {
          setState(() {
            _isAdLoaded = true;
            _isAdLoading = false;
            _loadError = null;
          });
        }
      },
      onAdFailedToLoad: (ad, error) {
        debugPrint('Native ad failed to load: ${error.message}');
        ad.dispose();
        if (mounted) {
          setState(() {
            _isAdLoaded = false;
            _isAdLoading = false;
            _loadError = error.message;
          });
        }
      },
      onAdClicked: (ad) {
        debugPrint('Native ad clicked');
      },
      onAdImpression: (ad) {
        debugPrint('Native ad impression recorded');
      },
      onAdClosed: (ad) {
        debugPrint('Native ad closed');
      },
      onAdWillDismissScreen: (ad) {
        debugPrint('Native ad will dismiss screen');
      },
      onAdOpened: (ad) {
        debugPrint('Native ad opened');
      },
    );
  }

  Widget _buildShimmerLoadingWidget() {
    return Shimmer.fromColors(
      baseColor: const Color(0xff374151).withValues(alpha: 0.1),
      highlightColor: Colors.white,
      child: Container(
        margin: widget.margin ?? _getDefaultMargin(), // ADD THIS
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        height: _getAdHeight(),
      ),
    );
  }

  double _getAdHeight() {
    switch (widget.templateType) {
      case TemplateType.small:
        return 120.0;
      case TemplateType.medium:
        return 350.0;
    }
  }

  EdgeInsets _getDefaultMargin() {
    switch (widget.templateType) {
      case TemplateType.small:
        return const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0);
      case TemplateType.medium:
        return const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0);
    }
  }

  Widget _buildLoadingWidget() {
    // Get theme brightness safely
    final brightness = mounted
        ? Theme.of(context).brightness
        : Brightness.light;
    final isDark = brightness == Brightness.dark;

    return Container(
      height: _getAdHeight(),
      margin: widget.margin ?? _getDefaultMargin(),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[200],
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: const Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 8),
            Text(
              'Loading ad...',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      height: _getAdHeight(),
      margin: widget.margin ?? _getDefaultMargin(),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red[400], size: 20),
            const SizedBox(height: 4),
            Text(
              'Ad failed to load',
              style: TextStyle(fontSize: 10, color: Colors.red[400]),
            ),
            if (_loadError != null) ...[
              const SizedBox(height: 2),
              Text(
                _loadError!,
                style: TextStyle(fontSize: 8, color: Colors.red[300]),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAdWidget() {
    return Container(
      height: _getAdHeight(),
      margin: widget.margin ?? _getDefaultMargin(),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: AdWidget(ad: _nativeAd!),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Don't show anything if user is premium
    if (premiumCtrl.isPro.value == true) {
      return const SizedBox.shrink();
    }

    // Show loading state
    if (_isAdLoading && !_isAdLoaded) {
      return widget.showOnlyWhenLoaded
          ? _buildShimmerLoadingWidget()
          : _buildLoadingWidget();
    }

    // Show error state
    if (_loadError != null && !_isAdLoaded) {
      return widget.showOnlyWhenLoaded
          ? _buildShimmerLoadingWidget()
          : _buildErrorWidget();
    }

    // Show ad if loaded
    if (_isAdLoaded && _nativeAd != null) {
      return _buildAdWidget();
    }

    // Default empty state
    return const SizedBox.shrink();
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }
}

// Extension for easier usage
extension NativeAdWidgetExtension on NativeAdWidget {
  static Widget small({
    Key? key,
    EdgeInsets? margin,
    Color? backgroundColor,
    Color? primaryTextColor,
    Color? secondaryTextColor,
    Color? ctaBackgroundColor,
    Color? ctaTextColor,
  }) {
    return NativeAdWidget(
      key: key,
      templateType: TemplateType.small,
      margin: margin,
      backgroundColor: backgroundColor,
      primaryTextColor: primaryTextColor,
      secondaryTextColor: secondaryTextColor,
      ctaBackgroundColor: ctaBackgroundColor,
      ctaTextColor: ctaTextColor,
    );
  }

  static Widget medium({
    Key? key,
    EdgeInsets? margin,
    Color? backgroundColor,
    Color? primaryTextColor,
    Color? secondaryTextColor,
    Color? ctaBackgroundColor,
    Color? ctaTextColor,
  }) {
    return NativeAdWidget(
      key: key,
      templateType: TemplateType.medium,
      margin: margin,
      backgroundColor: backgroundColor,
      primaryTextColor: primaryTextColor,
      secondaryTextColor: secondaryTextColor,
      ctaBackgroundColor: ctaBackgroundColor,
      ctaTextColor: ctaTextColor,
    );
  }
}
