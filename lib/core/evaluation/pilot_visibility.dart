import 'dart:async';
import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';

/// Counts only uninterrupted foreground visibility; scrolling away cancels it.
class PilotVisibility extends StatefulWidget {
  const PilotVisibility({super.key, required this.identity, required this.onViewed, required this.child});
  final String identity;
  final Future<void> Function() onViewed;
  final Widget child;
  @override
  State<PilotVisibility> createState() => _PilotVisibilityState();
}

class _PilotVisibilityState extends State<PilotVisibility> with WidgetsBindingObserver {
  Timer? _timer;
  bool _visible = false;
  bool _foreground = true;
  bool _done = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didUpdateWidget(PilotVisibility oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.identity != widget.identity) {
      _cancel();
      _done = false;
      _visible = false;
    }
  }

  void _cancel() { _timer?.cancel(); _timer = null; }

  void _check() {
    if (!_visible || !_foreground || !(ModalRoute.of(context)?.isCurrent ?? true)) {
      _cancel();
      return;
    }
    if (_done || _timer != null) return;
    _timer = Timer(const Duration(seconds: 1), () async {
      _timer = null;
      if (!mounted || !_foreground || !_visible || !(ModalRoute.of(context)?.isCurrent ?? true)) return;
      _done = true;
      try {
        await widget.onViewed();
      } catch (_) {
        _done = false;
        if (mounted) _check();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _check();
  }

  @override
  void dispose() {
    _cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => VisibilityDetector(
    key: ValueKey(widget.identity),
    onVisibilityChanged: (info) {
      _visible = info.visibleFraction >= .5;
      _check();
    },
    child: widget.child,
  );
}
