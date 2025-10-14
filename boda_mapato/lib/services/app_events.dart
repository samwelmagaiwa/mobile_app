import 'dart:async';

enum AppEventType {
  receiptsUpdated,
  paymentsUpdated,
  debtsUpdated,
  dashboardShouldRefresh,
}

class AppEvent {
  AppEvent(this.type, {this.payload});
  final AppEventType type;
  final Map<String, dynamic>? payload;
}

class AppEvents {
  AppEvents._();
  static final AppEvents instance = AppEvents._();

  final StreamController<AppEvent> _controller =
      StreamController<AppEvent>.broadcast();

  Stream<AppEvent> get stream => _controller.stream;

  void emit(AppEventType type, {Map<String, dynamic>? payload}) {
    if (!_controller.isClosed) {
      _controller.add(AppEvent(type, payload: payload));
    }
  }

  void dispose() {
    _controller.close();
  }
}
