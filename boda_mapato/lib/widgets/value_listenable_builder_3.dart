import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// ValueListenableBuilder for 3 notifiers.
class ValueListenableBuilder3<A, B, C> extends StatelessWidget {
  const ValueListenableBuilder3({
    required this.a,
    required this.b,
    required this.c,
    required this.builder,
    super.key,
  });
  final ValueListenable<A> a;
  final ValueListenable<B> b;
  final ValueListenable<C> c;
  final Widget Function(BuildContext, A, B, C) builder;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<A>(
      valueListenable: a,
      builder: (context, av, _) => ValueListenableBuilder<B>(
        valueListenable: b,
        builder: (context, bv, __) => ValueListenableBuilder<C>(
          valueListenable: c,
          builder: (context, cv, ___) => builder(context, av, bv, cv),
        ),
      ),
    );
  }
}
