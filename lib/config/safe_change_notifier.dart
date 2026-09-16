import 'package:flutter/foundation.dart';

mixin SafeChangeNotifier on ChangeNotifier {
  bool _safeDisposed = false;

  bool get foiDisposed => _safeDisposed;

  void avisar() {
    if (!_safeDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _safeDisposed = true;
    super.dispose();
  }
}
