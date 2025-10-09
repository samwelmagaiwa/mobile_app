import 'package:flutter/foundation.dart';

class DebtsProvider extends ChangeNotifier {
  bool _shouldRefresh = false;

  bool get shouldRefresh => _shouldRefresh;

  void markChanged() {
    _shouldRefresh = true;
    notifyListeners();
  }

  void consume() {
    _shouldRefresh = false;
  }
}
