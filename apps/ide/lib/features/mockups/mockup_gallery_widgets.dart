import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

import '../../l10n/app_localizations.dart';
import '../../ui/ui.dart';
import 'mockup_controller.dart';

/// Controls drawn over a mockup.
///
/// In the browser the mockup is an iframe, and an iframe takes every click
/// made over it: the arrows, the choose button and the sheets above the page
/// were all on screen and none of them answered. Elsewhere this does nothing.
class OverPage extends StatelessWidget {
  const OverPage({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => PointerInterceptor(child: child);
}

class MockupPage extends StatelessWidget {
  const MockupPage({super.key, required this.mockup, required this.onRetry});

  final Mockup mockup;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final ember = context.ember;
    // These two stay hand-built: the page is dark in the light theme too, so
    // the shared loading and error states would draw dark text on it.
    switch (mockup.status) {
      case MockupStatus.loading:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              Gap.vLg,
              Text(l.designingStyle(mockupStyleLabel(l, mockup.style.id)), style: TextStyle(color: ember.onCodeSurface)),
            ],
          ),
        );
      case MockupStatus.failed:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(Gap.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, color: ember.warning, size: 40),
                Gap.vSm,
                Text(mockup.error ?? '', textAlign: TextAlign.center, style: TextStyle(color: ember.onCodeSurface)),
                Gap.vMd,
                FilledButton(onPressed: onRetry, child: Text(l.retry)),
              ],
            ),
          ),
        );
      case MockupStatus.ready:
        return MockupWebView(html: mockup.html!);
    }
  }
}


/// The page itself, shown once and reloaded in place.
///
/// It used to be keyed by the page's own hash, so every redraw replaced the
/// widget — and with it the native WebView underneath. The panel rounds redraw
/// all eight, which meant eight native views torn down and rebuilt in a few
/// seconds; on Windows the plugin fell over and took Ember with it
/// (flutter_inappwebview_windows_plugin.dll, 0xc0000005). The view is now
/// created once and simply given the new page.
class MockupWebView extends StatefulWidget {
  const MockupWebView({super.key, required this.html});

  final String html;

  @override
  State<MockupWebView> createState() => _MockupWebViewState();
}

class _MockupWebViewState extends State<MockupWebView> {
  InAppWebViewController? _controller;

  @override
  void didUpdateWidget(covariant MockupWebView old) {
    super.didUpdateWidget(old);
    if (old.html != widget.html) {
      _controller?.loadData(data: widget.html, mimeType: 'text/html', encoding: 'utf8');
    }
  }

  @override
  Widget build(BuildContext context) => InAppWebView(
        initialData: InAppWebViewInitialData(data: widget.html, mimeType: 'text/html', encoding: 'utf8'),
        initialSettings: InAppWebViewSettings(
          javaScriptEnabled: false,
          supportZoom: false,
          transparentBackground: false,
          verticalScrollBarEnabled: false,
        ),
        onWebViewCreated: (c) => _controller = c,
        // Horizontal swipes go to the PageView; vertical scroll stays in the mockup.
        gestureRecognizers: const {},
      );
}
