import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class AppLoadingIndicator extends StatelessWidget {
  final Color? color;
  final double? size;

  const AppLoadingIndicator({this.color, this.size, super.key});

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return CupertinoActivityIndicator(
        color: color ?? AppColors.primary,
        radius: size != null ? size! / 2 : 14,
      );
    }
    final indicator = CircularProgressIndicator(
      color: color ?? AppColors.primary,
      strokeWidth: 2.5,
    );
    if (size != null) {
      return SizedBox(width: size, height: size, child: indicator);
    }
    return indicator;
  }
}
