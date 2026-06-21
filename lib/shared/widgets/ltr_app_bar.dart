import 'dart:io';

import 'package:flutter/material.dart';

/// Wraps [AppBar] in a LTR [Directionality] on iOS so the [AppBar.leading]
/// slot appears on the visual LEFT, matching iOS navigation convention.
/// On Android, the app-level RTL [Directionality] from main.dart applies.
class LtrAppBar extends StatelessWidget implements PreferredSizeWidget {
  const LtrAppBar(this._appBar, {super.key});
  final AppBar _appBar;

  @override
  Size get preferredSize => _appBar.preferredSize;

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return Directionality(textDirection: TextDirection.ltr, child: _appBar);
    }
    return _appBar;
  }
}
