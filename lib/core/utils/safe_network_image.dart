import 'package:flutter/material.dart';

import 'package:maura_bastion_system/core/utils/url_validator.dart';

class SafeNetworkImage extends StatelessWidget {
  final String? url;
  final Widget placeholder;
  final double? height;
  final double? width;
  final BoxFit fit;

  const SafeNetworkImage({
    super.key,
    required this.url,
    required this.placeholder,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    if (!UrlValidator.isValidFormat(url)) return placeholder;
    return Image.network(
      url!,
      height: height,
      width: width,
      fit: fit,
      errorBuilder: (_, _, _) => placeholder,
    );
  }
}
