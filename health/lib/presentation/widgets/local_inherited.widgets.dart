import 'package:flutter/material.dart';

class LocaleInheritedWidget extends InheritedWidget {
  final Locale locale;
  final Function(Locale) updateLocale;

  const LocaleInheritedWidget({
    Key? key,
    required this.locale,
    required this.updateLocale,
    required Widget child,
  }) : super(key: key, child: child);

  static LocaleInheritedWidget of(BuildContext context) {
    final result = context.dependOnInheritedWidgetOfExactType<LocaleInheritedWidget>();
    assert(result != null, 'No LocaleInheritedWidget found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(LocaleInheritedWidget oldWidget) {
    return locale != oldWidget.locale;
  }
}
