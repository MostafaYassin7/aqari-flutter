import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_constants.dart';

String? safeReturnTo(String? value) {
  if (value == null ||
      !value.startsWith('/') ||
      value.startsWith('//') ||
      value.contains('\\') ||
      RegExp(r'[\x00-\x20]').hasMatch(value)) {
    return null;
  }
  final uri = Uri.tryParse(value);
  if (uri == null || uri.hasScheme || uri.hasAuthority) return null;
  String decoded;
  try {
    decoded = Uri.decodeComponent(uri.path);
  } catch (_) {
    return null;
  }
  if (decoded.startsWith('//') ||
      decoded.contains('\\') ||
      RegExp(r'[\x00-\x20]').hasMatch(decoded)) {
    return null;
  }
  return value;
}

String authRoute(String path, String? returnTo) => Uri(
  path: path,
  queryParameters: safeReturnTo(returnTo) == null
      ? null
      : {'returnTo': safeReturnTo(returnTo)!},
).toString();
String? currentReturnTo(BuildContext context) =>
    safeReturnTo(GoRouterState.of(context).uri.queryParameters['returnTo']);
String authDestination(BuildContext context) =>
    currentReturnTo(context) ?? AppRoutes.home;
String nextAuthRoute(BuildContext context, String path) =>
    authRoute(path, currentReturnTo(context));
