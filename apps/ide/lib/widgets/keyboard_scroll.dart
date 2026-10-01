import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Arrow keys, Page Up/Down, Home and End scroll the page on the computer,
/// without clicking into it first.
///
/// Flutter only scrolls with the keyboard when the focus is already inside a
/// list, so on most Ember screens the keys did nothing and the only way down
/// was dragging with the mouse. This scrolls the list under the mouse pointer
/// (or the biggest one on screen), and leaves the keys alone while a text
/// field is being typed in.
class KeyboardScroll extends StatefulWidget {
  const KeyboardScroll({super.key, required this.child});

  final Widget child;

  @override
  State<KeyboardScroll> createState() => _KeyboardScrollState();
}

class _KeyboardScrollState extends State<KeyboardScroll> {
  Offset? _pointer;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    super.dispose();
  }

  bool _typing() {
    final BuildContext? focused = FocusManager.instance.primaryFocus?.context;
    if (focused == null) return false;
    if (focused.widget is EditableText) return true;
    return focused.findAncestorWidgetOfExactType<EditableText>() != null;
  }

  bool _onKey(KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return false;
    final LogicalKeyboardKey key = event.logicalKey;
    final Set<LogicalKeyboardKey> keys = <LogicalKeyboardKey>{
      LogicalKeyboardKey.arrowUp,
      LogicalKeyboardKey.arrowDown,
      LogicalKeyboardKey.pageUp,
      LogicalKeyboardKey.pageDown,
      LogicalKeyboardKey.home,
      LogicalKeyboardKey.end,
    };
    if (!keys.contains(key) || _typing()) return false;
    final ScrollableState? target = _target();
    if (target == null) return false;
    final ScrollPosition p = target.position;
    final double page = p.viewportDimension * 0.85;
    final double to = switch (key) {
      LogicalKeyboardKey.arrowUp => p.pixels - 80,
      LogicalKeyboardKey.arrowDown => p.pixels + 80,
      LogicalKeyboardKey.pageUp => p.pixels - page,
      LogicalKeyboardKey.pageDown => p.pixels + page,
      LogicalKeyboardKey.home => p.minScrollExtent,
      _ => p.maxScrollExtent,
    }
        .clamp(p.minScrollExtent, p.maxScrollExtent);
    if (to == p.pixels) return true;
    if (event is KeyRepeatEvent) {
      p.jumpTo(to);
    } else {
      p.animateTo(to, duration: const Duration(milliseconds: 140), curve: Curves.easeOut);
    }
    return true;
  }

  /// The vertical list under the mouse, on the page in front; otherwise the
  /// biggest one there.
  ScrollableState? _target() {
    ScrollableState? under;
    double underArea = double.infinity;
    ScrollableState? biggest;
    double biggestArea = 0;
    void visit(Element e) {
      if (e is StatefulElement && e.state is ScrollableState) {
        final ScrollableState s = e.state as ScrollableState;
        final RenderObject? box = e.renderObject;
        final ModalRoute<Object?>? route = ModalRoute.of(e);
        if (axisDirectionToAxis(s.axisDirection) == Axis.vertical &&
            (route == null || route.isCurrent) &&
            box is RenderBox &&
            box.attached &&
            box.hasSize &&
            s.position.hasContentDimensions &&
            s.position.maxScrollExtent > s.position.minScrollExtent) {
          final Rect rect = box.localToGlobal(Offset.zero) & box.size;
          final double area = rect.width * rect.height;
          if (_pointer != null && rect.contains(_pointer!) && area < underArea) {
            // The innermost list under the pointer.
            under = s;
            underArea = area;
          }
          if (area > biggestArea) {
            biggest = s;
            biggestArea = area;
          }
        }
      }
      e.visitChildElements(visit);
    }

    context.visitChildElements(visit);
    return under ?? biggest;
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerHover: (PointerHoverEvent e) => _pointer = e.position,
      onPointerDown: (PointerDownEvent e) => _pointer = e.position,
      onPointerSignal: (PointerSignalEvent e) => _pointer = e.position,
      child: widget.child,
    );
  }
}
