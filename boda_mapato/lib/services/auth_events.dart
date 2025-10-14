import 'dart:async';

enum AuthEvent {
  unauthorized,
}

class AuthEvents {
  AuthEvents._();
  static final AuthEvents instance = AuthEvents._();

  final StreamController<AuthEvent> _controller =
      StreamController<AuthEvent>.broadcast();

  Stream<AuthEvent> get stream => _controller.stream;

  void emit(AuthEvent event) {
    if (!_controller.isClosed) {
      _controller.add(event);
    }
  }

  void dispose() {
    _controller.close();
  }
}
